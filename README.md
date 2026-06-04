# FemClock Pro 🌸
**Sistema de Monitoreo y Predicción del Ciclo Menstrual** *Desarrollado como proyecto avanzado para la materia de Aplicaciones Móviles.*

FemClock Pro es una aplicación móvil híbrida diseñada para el seguimiento integral de la salud menstrual. Combina la velocidad de almacenamiento local con la seguridad del respaldo en la nube, ofreciendo a las usuarias predicciones dinámicas, registro analítico de síntomas y recomendaciones de salud diarias.

---

## 🛠️ Arquitectura y Tecnologías Utilizadas

La aplicación implementa una arquitectura desacoplada y orientada a servicios, garantizando capacidades *Offline-First*:

* **Frontend:** [Flutter](https://flutter.dev) & [Dart](https://dart.dev) (Estructura de estado nativa, programación reactiva con Streams/Futures y renders personalizados con `CustomPainter`).
* **Base de Datos Local:** [SQLite](https://www.sqlite.org) (`sqflite`) para el almacenamiento inmediato de registros, optimizando el rendimiento del dispositivo.
* **Servicios en la Nube:** [Firebase](https://firebase.google.com) (Cloud Firestore para la sincronización multi-dispositivo y Firebase Auth para el control de sesiones).
* **Consumo de Red:** Paquete oficial `http` con decodificación de objetos JSON.

---

## 📂 Estructura Principal del Código (`lib/`)

```text
lib/
├── database/
│   └── db_helper.dart           # Manejo del Singleton de SQLite y consultas locales
├── models/
│   └── daily_log.dart           # Modelo de datos y mapeo dual (Map <-> Objeto Dart)
├── screens/
│   ├── calendar_screen.dart     # Gestión del calendario y registro de síntomas
│   ├── home_screen.dart         # Canvas del ciclo y renderizado analítico del anillo
│   ├── login_screen.dart        # Flujo de Firebase Auth y configuración inicial
│   ├── main_navigation.dart     # Enrutamiento de la barra de navegación
│   ├── profile_screen.dart      # Gestión de datos biológicos de la usuaria
│   └── stats_screen.dart        # Historial clínico y pintor del gráfico estadístico
└── services/
    └── advice_api_service.dart  # Cliente HTTP para el consumo de la API de salud
