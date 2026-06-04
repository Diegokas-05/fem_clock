import 'dart:convert';
import 'package:http/http.dart' as http;

class AdviceApiService {
  static final List<String> _consejosSalud = [
    "Mantente hidratada hoy. Beber agua reduce los dolores de cabeza y la retención de líquidos.",
    "El ejercicio ligero, como caminar o hacer yoga, ayuda a aliviar los cólios menstruales.",
    "Escucha a tu cuerpo. Si te sientes muy cansada, prioriza descansar más esta noche.",
    "Los alimentos ricos en hierro, como las espinacas, son excelentes durante tu periodo.",
    "Registrar tus estados de ánimo te ayuda a identificar patrones emocionales cada mes."
  ];

  static Future<String> fetchDailyAdvice() async {
    try {
      final response = await http.get(Uri.parse('https://api.adviceslip.com/advice'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int id = data['slip']['id'] ?? 0;
        return _consejosSalud[id % _consejosSalud.length];
      }
      return _consejosSalud[0];
    } catch (e) {
      return _consejosSalud[1];
    }
  }
}