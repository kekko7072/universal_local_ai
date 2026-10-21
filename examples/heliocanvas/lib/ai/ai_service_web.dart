import 'dart:convert';

import 'package:http/http.dart' as http;

class AiService {
  static Future<Map<String, dynamic>?> generateLayout(
    String goal,
    Map<String, dynamic> telemetry,
  ) async {
    try {
      final r = await http
          .post(
            Uri.parse('/api/ai/layout'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'goal': goal, 'telemetry': telemetry}),
          )
          .timeout(const Duration(seconds: 45));
      return r.statusCode == 200
          ? Map<String, dynamic>.from(jsonDecode(r.body))
          : null;
    } catch (_) {
      return null;
    }
  }
}
