import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/db_helper.dart';
import '../models/daily_log.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  String _selectedFlow = 'Ninguno';
  String _selectedMood = '😊 Feliz';
  String _selectedSymptom = 'Ninguno';
  
  // Controla el estado del corazón para el día seleccionado actualmente
  bool _hasHeart = false; 

  // NUEVO: Mapa global para pintar todos los corazones del mes a la vez
  Map<String, bool> _daysWithHearts = {};

  final List<String> _flows = ['Ninguno', 'Ligero', 'Moderado', 'Fuerte'];
  final List<String> _moods = ['😊 Feliz', '😔 Cansada', '😡 Irritable', '😴 Con sueño'];
  final List<String> _symptoms = ['Ninguno', 'Cólicos', 'Migraña', 'Hinchazón'];

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllLogs(); // 1. Carga todos los corazones guardados en el historial
    _loadDayData(); // 2. Carga los detalles del día seleccionado por defecto
  }

  // Carga TODO el historial de la DB local para identificar qué días llevan corazón
  void _loadAllLogs() async {
    if (user == null) return;
    List<DailyLog> allLogs = await DBHelper.instance.getAllLogs(user!.uid);
    
    Map<String, bool> tempHearts = {};
    for (var log in allLogs) {
      if (log.hasHeart) {
        tempHearts[log.date] = true;
      }
    }
    setState(() {
      _daysWithHearts = tempHearts;
    });
  }

  // Carga los datos específicos del día que la usuaria presionó
  void _loadDayData() async {
    if (user == null) return;
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    DailyLog? log = await DBHelper.instance.getLogByDate(formattedDate, user!.uid);
    setState(() {
      _selectedFlow = log?.flow ?? 'Ninguno';
      _selectedMood = log?.mood ?? '😊 Feliz';
      _selectedSymptom = log?.symptoms ?? 'Ninguno';
      _hasHeart = log?.hasHeart ?? false; // Carga si tiene corazón o no
    });
  }

  void _saveData() async {
    if (user == null) return;
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    
    DailyLog newLog = DailyLog(
      userId: user!.uid, 
      date: formattedDate, 
      flow: _selectedFlow, 
      mood: _selectedMood, 
      symptoms: _selectedSymptom,
      hasHeart: _hasHeart, // Guardamos el estado real del corazón
    );
    
    await DBHelper.instance.insertOrUpdateLog(newLog);
    
    // Actualizamos el mapa local al instante para que el corazón aparezca/desaparezca sin recargar la app
    setState(() {
      _daysWithHearts[formattedDate] = _hasHeart;
    });
    
    _loadDayData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Guardado para el $formattedDate'), backgroundColor: const Color(0xFFF472B6), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Toca un día para registrar", style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.white, 
        elevation: 0
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white, padding: const EdgeInsets.only(bottom: 15),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1), 
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat, 
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) { 
                  // BLOQUEO LÓGICO DE FECHAS FUTURAS
                  DateTime now = DateTime.now();
                  DateTime today = DateTime(now.year, now.month, now.day);
                  DateTime selected = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  
                  if (selected.isAfter(today)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No puedes registrar síntomas en el futuro"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
                    return;
                  }

                  setState(() { _selectedDay = selectedDay; _focusedDay = focusedDay; }); 
                  _loadDayData(); 
                },
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
                
                // Mantenemos una altura base por celda para que quepa el número y el corazón cómodamente
                rowHeight: 52,
                
                calendarStyle: const CalendarStyle(
                  // Estilos base desactivados para usar el control total de los builders personalizados abajo
                  isTodayHighlighted: false,
                ),

                // ==================== RE-DISEÑO DE LOS BUILDERS (CORAZÓN ABAJO) ====================
                calendarBuilders: CalendarBuilders(
                  
                  // 1. DÍAS NORMALES DEL MES (Con el corazón abajo del número)
                  defaultBuilder: (context, day, focusedDay) {
                    String formattedDate = DateFormat('yyyy-MM-dd').format(day);
                    final tieneCorazon = _daysWithHearts[formattedDate] ?? false;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${day.day}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15)),
                        const SizedBox(height: 3),
                        // Contenedor reservado para el corazón: si no tiene, ocupa el mismo espacio invisible para no desalinear
                        SizedBox(
                          height: 12,
                          child: tieneCorazon 
                            ? const Icon(Icons.favorite, color: Color(0xFFF472B6), size: 11)
                            : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },

                  // 2. EL DÍA DE HOY (Círculo rosa pálido, corazón abajo)
                  todayBuilder: (context, day, focusedDay) {
                    String formattedDate = DateFormat('yyyy-MM-dd').format(day);
                    final tieneCorazon = _daysWithHearts[formattedDate] ?? false;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Color(0xFFFCE7F3), shape: BoxShape.circle),
                          child: Text('${day.day}', style: const TextStyle(color: Color(0xFFF472B6), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 12,
                          child: tieneCorazon 
                            ? const Icon(Icons.favorite, color: Color(0xFFF472B6), size: 11)
                            : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },

                  // 3. DÍA SELECCIONADO (Círculo fucsia encendido, corazón blanco adentro o abajo)
                  selectedBuilder: (context, day, focusedDay) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(color: Color(0xFFF472B6), shape: BoxShape.circle),
                          child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          height: 12,
                          child: _hasHeart 
                            ? const Icon(Icons.favorite, color: Color(0xFFF472B6), size: 11)
                            : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                ),
                // ==============================================================================
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Editando el: ${DateFormat('dd de MMM').format(_selectedDay!)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF472B6))),
                      
                      // Botón de corazón interactivo en el panel de edición
                      IconButton(
                        icon: Icon(
                          _hasHeart ? Icons.favorite : Icons.favorite_border,
                          color: _hasHeart ? const Color(0xFFF472B6) : Colors.grey,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            _hasHeart = !_hasHeart;
                          });
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Flujo Menstrual", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildSelector(_flows, _selectedFlow, (val) => setState(() => _selectedFlow = val)),
                  const SizedBox(height: 20),
                  const Text("Estado de Ánimo", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildSelector(_moods, _selectedMood, (val) => setState(() => _selectedMood = val)),
                  const SizedBox(height: 20),
                  const Text("Síntomas Físicos", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _buildSelector(_symptoms, _selectedSymptom, (val) => setState(() => _selectedSymptom = val)),
                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: _saveData,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF472B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text("Guardar Estado", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSelector(List<String> options, String currentSelection, Function(String) onSelected) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == currentSelection;
          return GestureDetector(
            onTap: () => onSelected(option),
            child: Container(
              margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF472B6) : Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFF472B6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Center(child: Text(option, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
            ),
          );
        },
      ),
    );
  }
}