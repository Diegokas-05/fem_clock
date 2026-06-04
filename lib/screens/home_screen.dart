import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../services/advice_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String _apiAdvice = "Cargando tu consejo de bienestar...";

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  void _loadAdvice() async {
    String advice = await AdviceApiService.fetchDailyAdvice();
    if(mounted) setState(() => _apiAdvice = advice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F7),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final userData = snapshot.data!;
          final String lastPeriodStr = userData['last_period_date'] ?? DateTime.now().toString();
          
          DateTime lastPeriodDate = DateTime.parse(lastPeriodStr);
          DateTime today = DateTime.now();
          int diffDays = today.difference(lastPeriodDate).inDays;
          int cycleDay = (diffDays % 28) + 1; 

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Align(alignment: Alignment.centerLeft, child: Text("Hola, ${userData['name'].split(' ')[0]}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  ),
                  
                  // TARJETA DE LA API REINTEGRADA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF472B6), Color(0xFFE9D5FF)]), borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [Icon(Icons.auto_awesome, color: Colors.white, size: 20), SizedBox(width: 8), Text("Tip del Día (API)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 10),
                          Text(_apiAdvice, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: SizedBox(
                      width: 320,
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(320, 320),
                            painter: CycleRingPainter(),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.water_drop, color: Color(0xFFFF4D4F), size: 30),
                              const SizedBox(height: 10),
                              const Text("Día del Ciclo", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                              Text("$cycleDay", style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFFE8E8), borderRadius: BorderRadius.circular(20)),
                                child: Text(cycleDay <= 5 ? "Días de Menstruación" : cycleDay >= 12 && cycleDay <= 16 ? "Ventana Fértil" : "Día normal del ciclo", style: const TextStyle(fontSize: 12, color: Colors.pink)),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class CycleRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    const double strokeWidth = 35.0; 
    const double sweepAngle = (2 * pi) / 28; 

    Color getColorForDay(int day) {
      if (day >= 1 && day <= 5) return const Color(0xFFFF4D4F); 
      if (day >= 12 && day <= 16) return const Color(0xFF73D13D); 
      return const Color(0xFFE2E8F0); 
    }

    for (int i = 0; i < 28; i++) {
      final paint = Paint()
        ..color = getColorForDay(i + 1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      final double startAngle = -pi / 2 + (i * sweepAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        sweepAngle - 0.02, 
        false,
        paint,
      );

      // DIBUJAR LOS NÚMEROS EN CADA CUADRITO
      final double middleAngle = startAngle + (sweepAngle / 2);
      final double textRadius = radius - (strokeWidth / 2);
      final double x = center.dx + textRadius * cos(middleAngle);
      final double y = center.dy + textRadius * sin(middleAngle);
      
      TextPainter textPainter = TextPainter(
        text: TextSpan(text: '${i + 1}', style: TextStyle(color: (i+1 >= 12 && i+1 <= 16) || (i+1 >= 1 && i+1 <= 5) ? Colors.white : Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}