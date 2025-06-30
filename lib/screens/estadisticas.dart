import 'package:flutter/material.dart';

class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Aquí se mostrarán las estadísticas',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
