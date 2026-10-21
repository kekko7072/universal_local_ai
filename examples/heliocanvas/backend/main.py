import json, math, os, sqlite3, threading, time
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
import httpx
import paho.mqtt.client as mqtt
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

DB_PATH=Path(os.getenv('DB_PATH','/data/solar.db'))
MQTT_HOST=os.getenv('MQTT_HOST','mosquitto'); MQTT_TOPIC=os.getenv('MQTT_TOPIC','energy/growatt/#')
OLLAMA_URL=os.getenv('OLLAMA_URL','http://ollama:11434'); OLLAMA_MODEL=os.getenv('OLLAMA_MODEL','gemma3:1b')
MOCK_DATA=os.getenv('MOCK_DATA','false').lower() in ('1','true','yes','on')
PLANT_NAME=os.getenv('PLANT_NAME','My solar plant')
RATED_POWER_KW=float(os.getenv('RATED_POWER_KW','0') or 0)
LOGGER_MODEL=os.getenv('LOGGER_MODEL','ShineWiFi-X')
app=FastAPI(title='Local Solar API',version='0.1.0')
app.add_middleware(CORSMiddleware,allow_origins=['*'],allow_methods=['*'],allow_headers=['*'])
lock=threading.Lock()
mqtt_state={'connected':False,'messages':0,'last_message_at':None,'last_error':None}

def db():
    DB_PATH.parent.mkdir(parents=True,exist_ok=True)
    c=sqlite3.connect(DB_PATH); c.row_factory=sqlite3.Row
    c.execute('CREATE TABLE IF NOT EXISTS samples (ts TEXT NOT NULL, device TEXT, watts REAL, today REAL, total REAL, temp REAL, voltage REAL, raw TEXT)')
    existing={row['name'] for row in c.execute('PRAGMA table_info(samples)').fetchall()}
    for column in ('battery_soc','battery_charge_w','battery_discharge_w','battery_voltage','home_load_w','grid_import_w','grid_export_w'):
        if column not in existing: c.execute(f'ALTER TABLE samples ADD COLUMN {column} REAL')
    c.execute('CREATE INDEX IF NOT EXISTS samples_ts ON samples(ts)'); c.commit(); return c

def pick(values:dict,*names:str)->float:
    lowered={str(k).lower():v for k,v in values.items()}
    for name in names:
        try:
            if name.lower() in lowered:return float(lowered[name.lower()])
        except (TypeError,ValueError):pass
    return 0.0

def pick_optional(values:dict,*names:str)->float|None:
    lowered={str(k).lower():v for k,v in values.items()}
    for name in names:
        try:
            if name.lower() in lowered:return float(lowered[name.lower()])
        except (TypeError,ValueError):pass
    return None

def normalize(payload:dict)->dict:
    values=payload.get('values',payload); device=str(payload.get('device') or payload.get('inverter') or values.get('pvserial') or 'Growatt inverter')
    return {'ts':datetime.now(timezone.utc).isoformat(),'device':device,
      'watts':pick(values,'pvpowerout','outputpower','pac','power'),
      'today':pick(values,'pvenergytoday','energytoday','etoday'),
      'total':pick(values,'pvenergytotal','energytotal','etotal'),
      'temp':pick(values,'pvtemperature','temperature','temp'),
      'voltage':pick(values,'pvgridvoltage','gridvoltage','grid_volt','vac1','vac'),
      'battery_soc':pick_optional(values,'batterySoc','SOC','battery_soc'),
      'battery_charge_w':pick_optional(values,'p1charge1','chargePower','acchr_watt','ACCharWatt'),
      'battery_discharge_w':pick_optional(values,'pdischarge1','BatDischarWatt','batteryDischargePower'),
      'battery_voltage':pick_optional(values,'vbat','bat_Volt','batteryVoltage'),
      'home_load_w':pick_optional(values,'plocaloadtot','plocaloadr','loadPower','outputpower','op_watt'),
      'grid_import_w':pick_optional(values,'pactousertot','pactouserr','gridImportPower','AC_InWatt'),
      'grid_export_w':pick_optional(values,'pactogridtot','pactogridr','gridExportPower')}

def on_connect(client,userdata,flags,reason_code,properties):
    mqtt_state['connected']=reason_code==0
    mqtt_state['last_error']=None if reason_code==0 else f'MQTT connection refused: {reason_code}'
    if reason_code==0: client.subscribe(MQTT_TOPIC)

def on_disconnect(client,userdata,disconnect_flags,reason_code,properties):
    mqtt_state['connected']=False
    if reason_code!=0: mqtt_state['last_error']=f'MQTT disconnected: {reason_code}'

def on_message(client,userdata,msg):
    try:
        payload=json.loads(msg.payload.decode()); s=normalize(payload)
        with lock:
            c=db(); c.execute('''INSERT INTO samples
              (ts,device,watts,today,total,temp,voltage,raw,battery_soc,battery_charge_w,battery_discharge_w,battery_voltage,home_load_w,grid_import_w,grid_export_w)
              VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''',(s['ts'],s['device'],s['watts'],s['today'],s['total'],s['temp'],s['voltage'],json.dumps(payload),s['battery_soc'],s['battery_charge_w'],s['battery_discharge_w'],s['battery_voltage'],s['home_load_w'],s['grid_import_w'],s['grid_export_w'])); c.commit(); c.close()
        mqtt_state['messages']+=1; mqtt_state['last_message_at']=s['ts']; mqtt_state['last_error']=None
    except Exception as exc: print(f'MQTT payload ignored: {exc}',flush=True)

@app.on_event('startup')
def startup():
    db().close(); client=mqtt.Client(mqtt.CallbackAPIVersion.VERSION2); client.on_connect=on_connect; client.on_disconnect=on_disconnect; client.on_message=on_message
    client.reconnect_delay_set(min_delay=2,max_delay=30)
    def run():
        while True:
            try:
                client.connect(MQTT_HOST,int(os.getenv('MQTT_PORT','1883')),60); client.loop_forever()
            except Exception as exc:
                mqtt_state['connected']=False; mqtt_state['last_error']=str(exc)
                print(f'MQTT connection error, retrying: {exc}',flush=True); time.sleep(5)
    threading.Thread(target=run,daemon=True).start()

@app.get('/api/health')
async def health():
    with lock:
        c=db(); sample_count=c.execute('SELECT COUNT(*) FROM samples').fetchone()[0]; c.close()
    ai_reachable=False; ai_model_ready=False
    try:
        async with httpx.AsyncClient(timeout=2) as client:
            response=await client.get(f'{OLLAMA_URL}/api/tags'); response.raise_for_status()
            names=[str(model.get('name','')) for model in response.json().get('models',[])]
            ai_reachable=True; ai_model_ready=any(name==OLLAMA_MODEL or name.startswith(f'{OLLAMA_MODEL}:') for name in names)
    except Exception: pass
    return {'ok':True,'mqtt':{**mqtt_state,'topic':MQTT_TOPIC},'telemetry':{'samples':sample_count,'live':sample_count>0},'local_ai':{'reachable':ai_reachable,'model':OLLAMA_MODEL,'model_ready':ai_model_ready}}

@app.get('/api/status')
def status(history_hours:int=24):
    with lock:
        c=db(); latest=c.execute('SELECT * FROM samples ORDER BY ts DESC LIMIT 1').fetchone(); since=(datetime.now(timezone.utc)-timedelta(hours=max(1,min(history_hours,168)))).isoformat(); rows=c.execute('SELECT ts,watts FROM samples WHERE ts>=? ORDER BY ts',(since,)).fetchall(); c.close()
    if not latest:
        now=datetime.now(timezone.utc)
        if MOCK_DATA:
            history=[]
            for offset in range(history_hours,-1,-1):
                point=now-timedelta(hours=offset); daylight=max(0,math.sin((point.hour-6)/13*math.pi))
                history.append({'time':point.isoformat(),'watts':round(daylight*9200,1)})
            current=max(0,math.sin((now.hour-6)/13*math.pi))*9200
            return {'device':'Demo Growatt inverter','plant_name':PLANT_NAME,'rated_power_kw':RATED_POWER_KW,'datalogger':LOGGER_MODEL,'online':True,'demo':True,'updated_at':now.isoformat(),'current_w':round(current,1),'today_kwh':18.8,'total_kwh':2327.1,'temperature_c':41.2,'grid_voltage_v':231.4,'battery_soc':68.0,'battery_charge_w':1200.0,'battery_discharge_w':0.0,'battery_voltage_v':51.8,'home_load_w':1850.0,'grid_import_w':0.0,'grid_export_w':max(0,round(current-3050,1)),'history':history}
        return {'device':'Awaiting solar logger','plant_name':PLANT_NAME,'rated_power_kw':RATED_POWER_KW,'datalogger':LOGGER_MODEL,'online':False,'demo':False,'updated_at':now.isoformat(),'current_w':0,'today_kwh':0,'total_kwh':0,'temperature_c':0,'grid_voltage_v':0,'battery_soc':None,'battery_charge_w':None,'battery_discharge_w':None,'battery_voltage_v':None,'home_load_w':None,'grid_import_w':None,'grid_export_w':None,'history':[]}
    updated=datetime.fromisoformat(latest['ts']); online=datetime.now(timezone.utc)-updated<timedelta(minutes=10)
    return {'device':latest['device'] or 'Solar inverter','plant_name':PLANT_NAME,'rated_power_kw':RATED_POWER_KW,'datalogger':LOGGER_MODEL,'online':online,'demo':False,'updated_at':latest['ts'],'current_w':latest['watts'],'today_kwh':latest['today'],'total_kwh':latest['total'],'temperature_c':latest['temp'],'grid_voltage_v':latest['voltage'],'battery_soc':latest['battery_soc'],'battery_charge_w':latest['battery_charge_w'],'battery_discharge_w':latest['battery_discharge_w'],'battery_voltage_v':latest['battery_voltage'],'home_load_w':latest['home_load_w'],'grid_import_w':latest['grid_import_w'],'grid_export_w':latest['grid_export_w'],'history':[{'time':r['ts'],'watts':r['watts']} for r in rows]}

class AiRequest(BaseModel): goal:str; telemetry:dict[str,Any]

def fallback_layout(goal:str)->dict:
    text=goal.lower(); sections=['hero','flow','metrics','chart']; metrics=['battery','load','grid','updated']
    if 'chart first' in text or 'graph first' in text: sections=['chart','hero','metrics']
    if 'hide chart' in text or 'without chart' in text: sections.remove('chart')
    if 'hide metrics' in text or 'only power' in text:
        sections.remove('metrics')
    else:
        requested=[key for key,words in {'total':['total','lifetime'],'battery':['battery','soc','charge'],'load':['load','home','usage'],'grid':['grid','import','export'],'temperature':['temperature','heat'],'voltage':['voltage'],'updated':['updated','sample','status']}.items() if any(word in text for word in words)]
        if requested and ('only' in text or 'focus' in text): metrics=requested
    if 'metrics first' in text: sections=['metrics']+[s for s in sections if s!='metrics']
    return {'title':'My solar focus','sections':sections,'metrics':metrics,'chart_hours':168 if 'week' in text or '7 day' in text else 6 if '6 hour' in text else 24,'density':'compact' if 'compact' in text else 'comfortable'}

@app.post('/api/ai/layout')
async def ai_layout(req:AiRequest):
    fallback=fallback_layout(req.goal)
    prompt=f'''You compose a solar telemetry dashboard from a user request. Return only JSON with title string, sections array containing hero/flow/metrics/chart, metrics array containing total/battery/load/grid/temperature/voltage/updated, chart_hours integer 6-168, density compact or comfortable. Preserve only requested sections but never invent component names. User request: {req.goal}. Available live keys: {json.dumps(list(req.telemetry.keys()))}.'''
    try:
        async with httpx.AsyncClient(timeout=40) as client:
            r=await client.post(f'{OLLAMA_URL}/api/generate',json={'model':OLLAMA_MODEL,'prompt':prompt,'stream':False,'format':'json'}); r.raise_for_status(); value=json.loads(r.json()['response'])
            return value if isinstance(value,dict) else fallback
    except Exception:return fallback

@app.post('/api/ai/module')
async def ai_module(req:AiRequest):
    fallback={'title':'Solar snapshot','icon':'sun','tone':'fern','blurb':'A private, local reading of your system.','blocks':[{'type':'stat','label':'Power now','value':f"{float(req.telemetry.get('current_w',0))/1000:.2f} kW"},{'type':'stat','label':'Generated today','value':f"{float(req.telemetry.get('today_kwh',0)):.1f} kWh"},{'type':'note','text':'Compare production at the same hour across clear days to spot gradual performance changes.'}]}
    prompt=f'''Return only a compact JSON object with title, icon, tone, blurb, blocks. Allowed blocks: stat with label/value, note with text, checklist with label/items containing label/done. Analyze only these telemetry values: {json.dumps(req.telemetry)}. User goal: {req.goal}. Never invent measurements. Maximum 3 blocks.'''
    try:
        async with httpx.AsyncClient(timeout=40) as client:
            r=await client.post(f'{OLLAMA_URL}/api/generate',json={'model':OLLAMA_MODEL,'prompt':prompt,'stream':False,'format':'json'}); r.raise_for_status(); value=json.loads(r.json()['response'])
            return value if isinstance(value,dict) and isinstance(value.get('blocks'),list) else fallback
    except Exception:return fallback
