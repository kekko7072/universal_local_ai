import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_solar_dashboard/main.dart';

void main() {
  testWidgets('renders the HelioCanvas dashboard', (tester) async {
    await tester.pumpWidget(const SolarApp());
    expect(find.text('Energy at a glance'), findsOneWidget);
    expect(find.text('POWER NOW'), findsOneWidget);
    expect(find.text('Design UI'), findsOneWidget);
  });

  test('generated layouts are constrained to known components', () {
    final layout = DashboardLayout.fromJson({
      'title': 'Mine',
      'sections': ['chart', 'unsafe'],
      'metrics': ['temperature', 'secret'],
      'chart_hours': 999,
      'density': 'compact',
    });
    expect(layout.sections, ['chart']);
    expect(layout.metrics, ['temperature']);
    expect(layout.chartHours, 168);
    expect(layout.density, 'compact');
  });

  testWidgets('chart reflects the selected history window', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PowerChart(data: Telemetry.demo(), hours: 168)),
      ),
    );
    expect(find.text('Production · last 7 days'), findsOneWidget);
  });
}
