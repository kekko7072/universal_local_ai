import 'dart:convert';

import 'package:flutter_local_ai/flutter_local_ai.dart';

class AiService {
  static Future<Map<String, dynamic>?> generateLayout(
    String goal,
    Map<String, dynamic> telemetry,
  ) async {
    try {
      final engine = FlutterLocalAi();
      final response = await engine.generateText(
        prompt:
            'User request: $goal. Available telemetry keys: ${telemetry.keys.join(', ')}. Return only JSON.',
        instructions: 'You compose a solar dashboard. Output one JSON object with: title string; sections array using hero, metrics, chart; metrics array using total, temperature, voltage, updated; chart_hours integer 6-168; density compact or comfortable. Do not output markdown.',
        config: const GenerationConfig(maxTokens: 300, temperature: .2),
      );
      final text = response.text;
      final start = text.indexOf('{'), end = text.lastIndexOf('}');
      return start >= 0 && end > start
          ? Map<String, dynamic>.from(
              jsonDecode(text.substring(start, end + 1)),
            )
          : null;
    } catch (_) {
      return null;
    }
  }
}
