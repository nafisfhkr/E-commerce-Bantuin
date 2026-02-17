import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bantuin/Logic/config.dart';

class AIService {
  Future<Map<String, dynamic>> predictPrice({
    required String vehicleType,
    required String vehicleModel,
    required String complaint,
    required String location,
  }) async {
    try {
      final String prompt = """
        Bertindaklah sebagai mekanik ahli.
        Kendaraan: $vehicleType ($vehicleModel)
        Lokasi: $location
        Keluhan: "$complaint"

        Tugas:
        1. Analisis kerusakan.
        2. Perkirakan rentang biaya (Jasa + Sparepart) dalam Rupiah.
        
        Jawab HANYA format JSON ini:
        {
          "min_price": (integer),
          "max_price": (integer),
          "analysis": "(maks 2 kalimat)",
          "recommendation": "(saran singkat)"
        }
      """;

      final url = Uri.parse('$GEMINI_BASE_URL?key=$GEMINI_API_KEY');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiText = data['candidates'][0]['content']['parts'][0]['text'];
        aiText = aiText.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(aiText);
      } else {
        throw Exception('Gagal: ${response.statusCode}');
      }
    } catch (e) {
      return {
        "min_price": 0,
        "max_price": 0,
        "analysis": "Gagal memprediksi: $e",
        "recommendation": "Silakan cek manual.",
      };
    }
  }
}
