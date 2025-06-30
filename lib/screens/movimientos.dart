import 'package:flutter/material.dart';

class MovimientosScreen extends StatelessWidget {
  const MovimientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Aquí se mostrarán los movimientos',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
