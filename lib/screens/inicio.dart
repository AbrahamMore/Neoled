import 'package:flutter/material.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/inventario.dart';
import 'package:pasos_flutter/screens/clientes.dart';
import 'package:pasos_flutter/screens/proveedores.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
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
            color: AppColors.secondary,
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
                        context,
                        Icons.person,
                        'Clientes',
                        AppColors.azul,
                      ),
                      _buildFixedToolCard(
                        context,
                        Icons.sell,
                        'Ventas',
                        AppColors.verde,
                      ),
                      _buildFixedToolCard(
                        context,
                        Icons.local_shipping,
                        'Proveedores',
                        AppColors.rojo,
                      ),
                      _buildFixedToolCard(
                        context,
                        Icons.people,
                        'Empleados',
                        AppColors.primary,
                      ),
                      _buildFixedToolCard(
                        context,
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
    );
  }

  Widget _buildFixedToolCard(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          switch (label) {
            case 'Clientes':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientesScreen()),
              );
              break;
            case 'Ventas':
              break;
            case 'Proveedores':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProveedoresScreen()),
              );
              break;
            case 'Empleados':
              // Cambia por la pantalla correcta si existe
              break;
            case 'Inventario':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventarioScreen()),
              );
              break;
          }
        },
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        splashColor: Colors.white.withOpacity(0.3),
        // ignore: deprecated_member_use
        highlightColor: Colors.white.withOpacity(0.15),
        child: Container(
          width: 140,
          height: 120,
          alignment: Alignment.center,
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
      ),
    );
  }
}
