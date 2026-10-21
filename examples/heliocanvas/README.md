# HelioCanvas

**Your solar data, composed locally.**

HelioCanvas is an open-source, local-first Growatt telemetry dashboard and GenUI showcase for a ShineWiFi-X logger. It keeps a local SQLite history, offers a responsive Flutter web UI, and can continue forwarding packets to Growatt as a backup.

## Architecture

`ShineWiFi-X → Grott proxy → MQTT → FastAPI/SQLite → Flutter web`

The user can describe the dashboard they want in plain language. A constrained local model composes a layout from an allow-listed component catalog, live telemetry binds into that layout, and the preference is saved in Chrome's local storage. The browser uses a local Ollama model; native iOS/Android builds use `flutter_local_ai` and the device's on-device model. No telemetry is sent to an AI cloud service.

## Quick start on Linux

HelioCanvas lives at `examples/heliocanvas` in the Universal Local AI repository because it combines Flutter, Python, MQTT, Grott, SQLite, Nginx, and optional Ollama rather than demonstrating only one Flutter package.

```bash
git clone --filter=blob:none --sparse https://github.com/kekko7072/universal_local_ai.git
cd universal_local_ai
git sparse-checkout set examples/heliocanvas
cd examples/heliocanvas
```

Run the one-command setup:

```bash
./setup.sh
```

It creates the ignored machine-local `.env`, detects the server's LAN address when possible, starts the complete stack, and downloads the configured local Ollama model once. No Growatt login, plant name, serial number, Wi-Fi password, or cloud API key is required.

To run the complete telemetry dashboard without downloading or starting Local AI:

```bash
./setup.sh --no-local-ai
```

This removes a previously started Ollama container from the running stack while preserving its model volume for later reuse. Run `./setup.sh --with-local-ai` to enable it again. Without Ollama, **Design UI** uses the deterministic offline fallback.

Real identifiers received from the logger exist only in the local SQLite volume and UI. They are never added to the repository or sent to an AI cloud. Edit `.env` to change the generic plant label, rated power, ports, mock behavior, or model, then rerun `./setup.sh`.

For a full ecosystem checkout, use `git clone --recurse-submodules` instead.

## Ubuntu installation

Requirements: Docker Engine with Compose v2, a fixed LAN IP, enough disk space for the selected Ollama model, and TCP ports 5279 and 8080 available.

The `.env` file is intentionally ignored by Git. Keep machine-specific values there; publish only `.env.example`.

Open `http://YOUR_SERVER_IP:8080`. The page shows demo data until the first valid Growatt packet arrives.

### First-run demo

The default Compose configuration sets `MOCK_DATA: "true"`. On an empty database the API produces a realistic daylight curve and labels it **DEMO DATA**, so the dashboard and prompt-driven layout composer work immediately in Chrome.

Try this before touching the logger:

1. Open `http://YOUR_SERVER_IP:8080` in Chrome.
2. Select **Design UI**.
3. Prompt: `Put the chart first and use a compact layout, focus only on temperature.`
4. Select **Compose & save**, then reload the page to verify that Chrome retained the layout.

Mock mode is only a fallback. The first real MQTT packet takes precedence automatically. To show zeros instead while waiting for a logger, change `MOCK_DATA` to `"false"` and rerun `./setup.sh`.

## Connect a real Growatt system

### 1. Prepare Ubuntu

Confirm that the Ubuntu server has a fixed LAN address and that the logger can reach TCP port `5279`. Do not expose that port through the internet router.

```bash
./setup.sh
docker compose -f docker-compose.yml -f docker-compose.local-ai.yml ps
curl http://localhost:8080/api/health
```

The health response reports MQTT connectivity, received samples, Ollama reachability, and model readiness. Open the dashboard and confirm that **DEMO DATA** is visible.

### 2. Record the logger's original settings

Before making a change, record or photograph the ShineWiFi-X server hostname and port. This is the rollback information. The common Growatt destination is `server.growatt.com:5279`, but retain whatever your logger currently shows.

### 3. Set the telemetry destination

Use the ShineWiFi-X local configuration flow supplied for your hardware revision—normally its temporary Wi-Fi access point, local configuration page, or the advanced datalogger settings in ShinePhone. ShineServer's **Monitor Settings** page associates a logger with an inverter; it is not necessarily the screen that changes the logger's telemetry server.

Change only these fields:

```text
Server/address: YOUR_UBUNTU_SERVER_FIXED_IP
Server port:    5279
```

Keep the logger connected to the same home network. Save the configuration and restart only the logger if requested. Do not factory-reset the inverter.

### 4. Verify every stage

Watch Grott and the API:

```bash
docker compose logs -f grott api
```

In a second terminal, confirm MQTT messages:

```bash
docker compose exec mosquitto \
  mosquitto_sub -t 'energy/growatt/#' -C 1 -v
```

Then inspect the normalized API output:

```bash
./verify-live.sh
```

When the first packet arrives, `demo` changes to `false`, the real device identifier appears, and SQLite begins retaining samples. No dashboard restart is required; Chrome refreshes telemetry every ten seconds.

### 5. Confirm cloud forwarding or choose local-only

Grott is configured as a proxy and forwards packets to `server.growatt.com:5279`. `blockcmd = True` blocks remote control commands while retaining telemetry forwarding. Do not expose port 5279 or 1883 to the public internet; LAN/VPN access is sufficient.

Logger firmware screens differ. If the server field is not exposed, use the ShineWiFi-X AP configuration flow documented for your hardware revision rather than resetting the inverter.

If packets reach Grott but fields remain zero, save one decoded message from the MQTT command above and add its field names to the aliases in `backend/main.py` (`normalize`/`pick`). Growatt firmware families sometimes use different keys.

To roll back, restore the original logger server and port recorded in step 2. Historical data already stored in HelioCanvas remains local.

## Local AI

The recommended setup runs Ollama inside the same private Docker network and installs a small model automatically:

```bash
./setup.sh
```

Telemetry travels only from the API container to the local Ollama container. The model can reorder allow-listed dashboard components but cannot run code or access arbitrary fields. If Ollama is unavailable, the API uses a deterministic local composer so the dashboard remains usable. Change `OLLAMA_MODEL` in `.env` and rerun setup to use another model.

Example prompts:

- `Put the chart first and use a compact layout.`
- `Focus on temperature and grid voltage.`
- `Show only current power without the chart.`

Generated layouts cannot execute code or request arbitrary data. They can only reorder the `hero`, `metrics`, and `chart` components and select from known telemetry fields. The saved layout remains in that Chrome profile until reset.

## Development

```bash
flutter pub get
flutter run -d chrome
```

The telemetry API is documented at `http://YOUR_SERVER_IP:8080/api/health`. Raw packets are retained in SQLite to make new inverter-field mappings debuggable. Add aliases in `backend/main.py` if your inverter uses different Growatt keys.

## Uninstall

Remove only HelioCanvas containers, images, volumes, telemetry, local AI models, generated files, and the private `.env`:

```bash
./uninstall.sh
```

To also remove every Docker workload on the server, uninstall Docker Engine, and delete all Docker runtime data, use the explicitly destructive system-wide mode:

```bash
./uninstall.sh --purge-docker
```

The script requires a typed confirmation and preserves this Git checkout, allowing future `git pull` operations. The `--purge-docker` option affects unrelated Docker applications on the same server.

## Security and privacy

- MQTT is intentionally available only inside the Docker network.
- Ollama is intentionally available only inside the Docker network.
- The dashboard is HTTP on the trusted LAN/VPN. Put it behind your VPN or a local reverse proxy for HTTPS.
- Inverter commands are disabled in Grott.
- Back up the `telemetry-data` Docker volume if you want to retain history.
- `.env`, SQLite data, Ollama models, and real device identifiers are excluded from Git.

## License

MIT
