import 'package:flutter/material.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/components/custom_bottom.dart'; // ← aquí

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'NEOLEDMEX',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/iconos.png', fit: BoxFit.contain),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 360,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Herramientas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildFixedToolCard(
                        Icons.person,
                        'Clientes',
                        AppColors.azul,
                      ),
                      _buildFixedToolCard(
                        Icons.sell,
                        'Ventas',
                        AppColors.verde,
                      ),
                      _buildFixedToolCard(
                        Icons.local_shipping,
                        'Proveedores',
                        AppColors.rojo,
                      ),
                      _buildFixedToolCard(
                        Icons.people,
                        'Empleados',
                        AppColors.primary,
                      ),
                      _buildFixedToolCard(
                        Icons.inventory,
                        'Inventario',
                        AppColors.morado,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0, // ← este será el índice activo
        onTap: (index) {
          // Puedes manejar navegación aquí si lo deseas
          // Navigator.pushNamed(context, '/ventas');
        },
      ),
    );
  }

  Widget _buildFixedToolCard(IconData icon, String label, Color color) {
    return Container(
      width: 140,
      height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.accent),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
