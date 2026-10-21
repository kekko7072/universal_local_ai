import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/ai_service.dart';

void main() => runApp(const SolarApp());

class SolarApp extends StatelessWidget {
  const SolarApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'HelioCanvas',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffffbd2e)),
      scaffoldBackgroundColor: const Color(0xfff4f5ef),
    ),
    home: const Dashboard(),
  );
}

class Sample {
  const Sample(this.time, this.watts);
  final DateTime time;
  final double watts;
  factory Sample.fromJson(Map<String, dynamic> j) => Sample(
    DateTime.tryParse('${j['time']}')?.toLocal() ?? DateTime.now(),
    (j['watts'] as num?)?.toDouble() ?? 0,
  );
}

class Telemetry {
  const Telemetry({
    required this.device,
    required this.plant,
    required this.ratedKw,
    required this.online,
    required this.updated,
    required this.watts,
    required this.today,
    required this.total,
    required this.temp,
    required this.voltage,
    required this.history,
    this.demo = false,
  });
  final String device;
  final String plant;
  final double ratedKw;
  final bool online, demo;
  final DateTime updated;
  final double watts, today, total, temp, voltage;
  final List<Sample> history;
  factory Telemetry.fromJson(Map<String, dynamic> j) {
    double n(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return Telemetry(
      device: '${j['device'] ?? 'Growatt inverter'}',
      plant: '${j['plant_name'] ?? 'My solar plant'}',
      ratedKw: (j['rated_power_kw'] as num?)?.toDouble() ?? 0,
      online: j['online'] == true,
      updated:
          DateTime.tryParse('${j['updated_at']}')?.toLocal() ?? DateTime.now(),
      watts: n('current_w'),
      today: n('today_kwh'),
      total: n('total_kwh'),
      temp: n('temperature_c'),
      voltage: n('grid_voltage_v'),
      history: (j['history'] as List? ?? [])
          .map((e) => Sample.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      demo: j['demo'] == true,
    );
  }
  factory Telemetry.demo() {
    final now = DateTime.now();
    return Telemetry(
      device: 'Awaiting ShineWiFi-X',
      plant: 'Demo solar plant',
      ratedKw: 15,
      online: false,
      updated: now,
      watts: 3240,
      today: 18.8,
      total: 2327.1,
      temp: 41.2,
      voltage: 231.4,
      demo: true,
      history: List.generate(
        25,
        (i) => Sample(
          now.subtract(Duration(hours: 24 - i)),
          math.max(0, math.sin((i - 6) / 13 * math.pi)) * 9200,
        ),
      ),
    );
  }
}

class DashboardLayout {
  const DashboardLayout({
    required this.title,
    required this.sections,
    required this.metrics,
    required this.chartHours,
    required this.density,
  });
  final String title, density;
  final List<String> sections, metrics;
  final int chartHours;
  static const allowedSections = {'hero', 'metrics', 'chart'};
  static const allowedMetrics = {'total', 'temperature', 'voltage', 'updated'};
  factory DashboardLayout.defaults() => const DashboardLayout(
    title: 'Energy at a glance',
    sections: ['hero', 'metrics', 'chart'],
    metrics: ['total', 'temperature', 'voltage', 'updated'],
    chartHours: 24,
    density: 'comfortable',
  );
  factory DashboardLayout.fromJson(Map<String, dynamic> j) {
    final sections = (j['sections'] as List? ?? [])
        .map((e) => '$e')
        .where(allowedSections.contains)
        .toSet()
        .toList();
    final metrics = (j['metrics'] as List? ?? [])
        .map((e) => '$e')
        .where(allowedMetrics.contains)
        .toSet()
        .toList();
    return DashboardLayout(
      title: '${j['title'] ?? 'My solar dashboard'}'.trim().isEmpty
          ? 'My solar dashboard'
          : '${j['title']}',
      sections: sections.isEmpty
          ? DashboardLayout.defaults().sections
          : sections,
      metrics: metrics.isEmpty ? DashboardLayout.defaults().metrics : metrics,
      chartHours: (j['chart_hours'] as num?)?.toInt().clamp(6, 168) ?? 24,
      density: j['density'] == 'compact' ? 'compact' : 'comfortable',
    );
  }
  Map<String, dynamic> toJson() => {
    'title': title,
    'sections': sections,
    'metrics': metrics,
    'chart_hours': chartHours,
    'density': density,
  };
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Telemetry data = Telemetry.demo();
  DashboardLayout layout = DashboardLayout.defaults();
  Timer? timer;
  bool aiOpen = false, aiBusy = false;
  String goal =
      'Make a compact dashboard focused on current power and temperature.';
  @override
  void initState() {
    super.initState();
    loadLayout();
    refresh();
    timer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final r = await http
          .get(Uri.parse('/api/status?history_hours=${layout.chartHours}'))
          .timeout(const Duration(seconds: 4));
      if (r.statusCode == 200 && mounted) {
        setState(() => data = Telemetry.fromJson(jsonDecode(r.body)));
      }
    } catch (_) {}
  }

  Future<void> loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('heliocanvas.layout.v1');
    if (saved != null && mounted) {
      try {
        setState(() => layout = DashboardLayout.fromJson(jsonDecode(saved)));
        await refresh();
      } catch (_) {}
    }
  }

  Future<void> generate() async {
    setState(() => aiBusy = true);
    final r = await AiService.generateLayout(goal, {
      'current_w': data.watts,
      'today_kwh': data.today,
      'total_kwh': data.total,
      'temperature_c': data.temp,
      'grid_voltage_v': data.voltage,
    });
    if (mounted) {
      if (r != null) {
        final next = DashboardLayout.fromJson(r);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'heliocanvas.layout.v1',
          jsonEncode(next.toJson()),
        );
        setState(() {
          layout = next;
          aiBusy = false;
          aiOpen = false;
        });
        await refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dashboard layout saved locally.')),
          );
        }
      } else {
        setState(() => aiBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not compose a layout. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> resetLayout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('heliocanvas.layout.v1');
    if (mounted) {
      setState(() => layout = DashboardLayout.defaults());
      await refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default layout restored.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 920) const SideRail(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 42),
                    sliver: SliverList.list(
                      children: [
                        Header(
                          data: data,
                          title: layout.title,
                          onAi: () => setState(() => aiOpen = !aiOpen),
                        ),
                        const SizedBox(height: 25),
                        if (aiOpen) ...[
                          AiPanel(
                            goal: goal,
                            busy: aiBusy,
                            onGoal: (v) => goal = v,
                            onGenerate: generate,
                            onReset: resetLayout,
                          ),
                          const SizedBox(height: 16),
                        ],
                        ...layout.sections.expand((section) {
                          final widget = switch (section) {
                            'hero' => HeroCard(data: data),
                            'metrics' => MetricGrid(
                              data: data,
                              order: layout.metrics,
                            ),
                            'chart' => PowerChart(
                              data: data,
                              hours: layout.chartHours,
                            ),
                            _ => const SizedBox.shrink(),
                          };
                          return [
                            widget,
                            SizedBox(
                              height: layout.density == 'compact' ? 10 : 16,
                            ),
                          ];
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SideRail extends StatelessWidget {
  const SideRail({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 88,
    color: const Color(0xff17201b),
    child: const Column(
      children: [
        SizedBox(height: 24),
        Logo(),
        SizedBox(height: 40),
        RailIcon(Icons.grid_view_rounded, true),
        RailIcon(Icons.show_chart_rounded, false),
        RailIcon(Icons.bolt_rounded, false),
        Spacer(),
        RailIcon(Icons.settings_outlined, false),
        SizedBox(height: 20),
      ],
    ),
  );
}

class Logo extends StatelessWidget {
  const Logo({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: const Color(0xffffc53d),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.wb_sunny_rounded),
  );
}

class RailIcon extends StatelessWidget {
  const RailIcon(this.icon, this.active, {super.key});
  final IconData icon;
  final bool active;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: active ? Colors.white12 : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: active ? const Color(0xffffc53d) : Colors.white54,
      ),
    ),
  );
}

class Header extends StatelessWidget {
  const Header({
    required this.data,
    required this.title,
    required this.onAi,
    super.key,
  });
  final Telemetry data;
  final String title;
  final VoidCallback onAi;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 20,
    runSpacing: 12,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HELIOCANVAS',
            style: TextStyle(
              color: Color(0xff368857),
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 30,
              color: Color(0xff17201b),
            ),
          ),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusPill(data: data),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onAi,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Design UI'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff17201b),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
        ],
      ),
    ],
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.data, super.key});
  final Telemetry data;
  @override
  Widget build(BuildContext context) {
    final label = data.demo
        ? 'DEMO DATA'
        : data.online
        ? 'LIVE'
        : 'OFFLINE';
    final color = data.online && !data.demo
        ? const Color(0xff3c9c62)
        : const Color(0xffc98625);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({required this.data, super.key});
  final Telemetry data;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xff17201b),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1817201b),
          blurRadius: 30,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 760;
        final power = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'POWER NOW',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              formatPower(data.watts),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.ratedKw > 0
                  ? '${data.plant} · ${data.device} · ${data.ratedKw.toStringAsFixed(0)} kW rated'
                  : '${data.plant} · ${data.device}',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        );
        final sun = Container(
          width: compact ? double.infinity : 250,
          height: 132,
          decoration: BoxDecoration(
            color: const Color(0xffffc53d),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: 22,
                top: 20,
                child: Icon(Icons.wb_sunny_rounded, size: 68),
              ),
              Positioned(
                left: 20,
                bottom: 18,
                child: Text(
                  '${data.today.toStringAsFixed(1)} kWh\ntoday',
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [power, const SizedBox(height: 25), sun],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [power, sun],
              );
      },
    ),
  );
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({required this.data, required this.order, super.key});
  final Telemetry data;
  final List<String> order;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cols = c.maxWidth > 980
          ? 4
          : c.maxWidth > 540
          ? 2
          : 1;
      final width = (c.maxWidth - (cols - 1) * 14) / cols;
      final available = <String, Metric>{
        'total': Metric(
          'Total generated',
          '${data.total.toStringAsFixed(1)} kWh',
          Icons.solar_power_rounded,
          const Color(0xffffc53d),
        ),
        'temperature': Metric(
          'Inverter temperature',
          '${data.temp.toStringAsFixed(1)} °C',
          Icons.device_thermostat_rounded,
          const Color(0xffff9364),
        ),
        'voltage': Metric(
          'Grid voltage',
          '${data.voltage.toStringAsFixed(1)} V',
          Icons.electrical_services_rounded,
          const Color(0xff9ed8c3),
        ),
        'updated': Metric(
          'Last sample',
          DateFormat('HH:mm:ss').format(data.updated),
          Icons.schedule_rounded,
          const Color(0xffb8c5ef),
        ),
      };
      final cards = order
          .map((key) => available[key])
          .whereType<Metric>()
          .toList();
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: cards.map((e) => SizedBox(width: width, child: e)).toList(),
      );
    },
  );
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, this.icon, this.color, {super.key});
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffe6e8e0)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .32),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xff727970), fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PowerChart extends StatelessWidget {
  const PowerChart({required this.data, required this.hours, super.key});
  final Telemetry data;
  final int hours;
  @override
  Widget build(BuildContext context) {
    final points = data.history.isEmpty
        ? Telemetry.demo().history
        : data.history;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].watts / 1000),
    ];
    final maxY = math.max(
      1.0,
      spots.fold<double>(0, (p, e) => math.max(p, e.y)) * 1.2,
    );
    return Container(
      height: 330,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe6e8e0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hours == 168
                ? 'Production · last 7 days'
                : 'Production · last $hours hours',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: math.max(1, maxY / 4),
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xffeceee8), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toStringAsFixed(0)}k',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff8a9087),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: math.max(
                        1,
                        (points.length / 4).floorToDouble(),
                      ),
                      getTitlesWidget: (v, _) {
                        final i = v.round().clamp(0, points.length - 1);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('HH:mm').format(points[i].time),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xff8a9087),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xffe6a500),
                    barWidth: 4,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55ffc53d), Color(0x00ffc53d)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiPanel extends StatelessWidget {
  const AiPanel({
    required this.goal,
    required this.busy,
    required this.onGoal,
    required this.onGenerate,
    required this.onReset,
    super.key,
  });
  final String goal;
  final bool busy;
  final ValueChanged<String> onGoal;
  final VoidCallback onGenerate, onReset;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xffe9efe9),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffd9e1d8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome_rounded),
            SizedBox(width: 10),
            Text(
              'Design this dashboard',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Describe what matters to you. HelioCanvas generates a safe layout, binds it to live telemetry, and saves it in this browser.',
          style: TextStyle(color: Color(0xff657066)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: goal,
          onChanged: onGoal,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Example: Put the chart first, show only power and temperature, and use a compact layout.',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : onGenerate,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high_rounded),
              label: Text(busy ? 'Composing locally…' : 'Compose & save'),
            ),
            TextButton.icon(
              onPressed: busy ? null : onReset,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset layout'),
            ),
          ],
        ),
      ],
    ),
  );
}

String formatPower(double w) => w >= 1000
    ? '${(w / 1000).toStringAsFixed(2)} kW'
    : '${w.toStringAsFixed(0)} W';
