import 'package:flutter/material.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/ventas/venta_libre.dart';
import 'package:pasos_flutter/screens/ventas/venta_inventario.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipo de Venta'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón para Venta Libre
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 30,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.secondary,
                  minimumSize: const Size(double.infinity, 110), // más alto
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                  ), // más espacio interno
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VentaLibreScreen(),
                    ),
                  );
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 30),
                    SizedBox(height: 10), // más separación
                    Text('Venta Libre', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),

            // Botón para Venta con Inventario
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 20,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 110), // más alto
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                  ), // más espacio interno
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VentaInventarioScreen(),
                    ),
                  );
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory, size: 30),
                    SizedBox(height: 10), // más separación
                    Text(
                      'Venta con Inventario',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),
            // Texto explicativo
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Selecciona el tipo de venta que deseas realizar:\n\n'
                '• Venta Libre: Para servicios o productos sin control de inventario\n'
                '• Venta con Inventario: Para productos con control de stock',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
