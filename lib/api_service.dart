import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Default to localhost for development
  // Android emulator → use http://10.0.2.2:5000
  static const String base = 'http://127.0.0.1:5000';

  // ───────────────────── GET ALERT ─────────────────────
  static Future<Map<String, dynamic>?> getDummyAlert({
    String style = 'banner',
  }) async {
    final url = Uri.parse('$base/dummy/alert?style=$style');
    final r = await http.get(url);

    // Debug output
    // ignore: avoid_print
    print('ApiService.getDummyAlert -> ${r.statusCode}: ${r.body}');

    if (r.statusCode != 200) return null;

    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // ───────────────────── ACK ALERT ─────────────────────
  static Future<void> ackNotification({
    required String endpoint,
    Map<String, dynamic>? payload,
  }) async {
    final url = Uri.parse('$base$endpoint');

    await http.post(
      url,
      body: jsonEncode(payload ?? {}),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
}
