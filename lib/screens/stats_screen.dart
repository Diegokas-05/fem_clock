import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/db_helper.dart';
import '../models/daily_log.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  void _deleteLog(String date) async {
    if (user != null) {
      await DBHelper.instance.deleteLog(date, user!.uid);
      setState(() {}); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro eliminado'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F7),
      appBar: AppBar(
        title: const Text("Análisis e Historial", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<DailyLog>>(
        future: user != null ? DBHelper.instance.getAllLogs(user!.uid) : Future.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay registros almacenados todavía.", style: TextStyle(color: Colors.grey)));
          }

          final logs = snapshot.data!;

          // 1. PROCESAMIENTO DE ESTADÍSTICAS PARA EL GRÁFICO
          int feliz = 0, triste = 0, ansiosa = 0, irritable = 0;
          for (var log in logs) {
            if (log.mood.contains('Feliz')) feliz++;
            if (log.mood.contains('Triste')) triste++;
            if (log.mood.contains('Ansiosa') || log.mood.contains('Ansi')) ansiosa++;
            if (log.mood.contains('Irritable')) irritable++;
          }

          return Column(
            children: [
              // 2. PANEL DEL GRÁFICO ESTADÍSTICO
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Frecuencia de Estados de Ánimo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 20),
                      CustomPaint(
                        size: const Size(double.infinity, 120),
                        painter: MoodBarChartPainter(
                          feliz: feliz,
                          triste: triste,
                          ansiosa: ansiosa,
                          irritable: irritable,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. SECCIÓN DEL HISTORIAL CLÍNICO
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                child: Align(alignment: Alignment.centerLeft, child: Text("Registros Anteriores", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
              ),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const Icon(Icons.health_and_safety, color: Color(0xFFF472B6), size: 30),
                        title: Text(log.date, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Síntomas: ${log.symptoms} \nÁnimo: ${log.mood} | Flujo: ${log.flow}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _deleteLog(log.date),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 4. PINTOR PERSONALIZADO PARA EL GRÁFICO DE BARRAS NATIVO
class MoodBarChartPainter extends CustomPainter {
  final int feliz;
  final int triste;
  final int ansiosa;
  final int irritable;

  MoodBarChartPainter({required this.feliz, required this.triste, required this.ansiosa, required this.irritable});

  @override
  void paint(Canvas canvas, Size size) {
    final List<int> values = [feliz, triste, ansiosa, irritable];
    final List<String> labels = ['Feliz', 'Triste', 'Ansiosa', 'Irritab.'];
    final List<Color> colors = [Colors.amber, Colors.blueAccent, Colors.purpleAccent, Colors.orangeAccent];

    int maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    if (maxVal == 0) maxVal = 1; // Prevenir división entre cero si todo está vacío

    double barWidth = 40.0;
    double gap = (size.width - (barWidth * values.length)) / (values.length + 1);

    for (int i = 0; i < values.length; i++) {
      // Calcular altura proporcional de la barra según el lienzo
      double barHeight = (values[i] / maxVal) * (size.height - 30); 
      
      double x = gap + i * (barWidth + gap);
      double y = size.height - 20 - barHeight;

      // Dibujar la barra con esquinas redondeadas
      final paint = Paint()..color = colors[i]..style = PaintingStyle.fill;
      RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);

      // Pintar la cantidad numérica arriba de la barra
      TextPainter valuePainter = TextPainter(
        text: TextSpan(text: '${values[i]}', style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      valuePainter.paint(canvas, Offset(x + (barWidth / 2) - (valuePainter.width / 2), y - 18));

      // Pintar la etiqueta de texto abajo de la barra
      TextPainter labelPainter = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(x + (barWidth / 2) - (labelPainter.width / 2), size.height - 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}