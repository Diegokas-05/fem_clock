import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart'; 

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(), 
    const CalendarScreen(), 
    const StatsScreen(),
    const ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFFF472B6),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed, 
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.wb_sunny_outlined), activeIcon: Icon(Icons.wb_sunny), label: 'Hoy'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Ciclo'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Análisis'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}