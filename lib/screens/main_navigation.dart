// lib/screens/main_navigation.dart
import 'package:flutter/material.dart';
import 'inicio.dart';
// import 'ventas.dart';
// import 'estadisticas.dart';
// import 'movimientos.dart';
// import 'cuenta.dart';

// main_navigation.dart
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    InicioScreen(),
    // MovimientosScreen(),
    // EstadisticasScreen(),
    // CuentaScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Ventas'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Movs'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }
}
