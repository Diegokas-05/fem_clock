class DailyLog {
  final String userId;
  final String date;
  final String flow;
  final String mood;
  final String symptoms;
  final bool hasHeart; // 1. AGREGAR ESTA LÍNEA

  DailyLog({
    required this.userId,
    required this.date,
    required this.flow,
    required this.mood,
    required this.symptoms,
    this.hasHeart = false, // 2. AGREGAR AQUÍ CON VALOR POR DEFECTO
  });

  // Convertir a Mapa para Firebase / SQLite
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date,
      'flow': flow,
      'mood': mood,
      'symptoms': symptoms,
      'hasHeart': hasHeart ? 1 : 0, // En SQLite se guarda como 1 o 0. En Firestore puedes dejar 'hasHeart': hasHeart
    };
  }

  // Crear objeto desde Mapa venido de Firebase / SQLite
  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      userId: map['userId'] ?? '',
      date: map['date'] ?? '',
      flow: map['flow'] ?? 'Ninguno',
      mood: map['mood'] ?? '😊 Feliz',
      symptoms: map['symptoms'] ?? 'Ninguno',
      // Soporta tanto booleanos (Firestore) como enteros 1/0 (SQLite)
      hasHeart: map['hasHeart'] == true || map['hasHeart'] == 1, 
    );
  }
}