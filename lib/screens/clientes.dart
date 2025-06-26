import 'package:flutter/material.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/components/custom_bottom.dart'; // ← Import correcto
import 'package:pasos_flutter/screens/agregar_cliente.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final List<String> clientes = [
    'Alex Nicolin Segura',
    'Abraham Moreno Vasquez',
    'Alexis Ortega Dehesa',
    'Alex Nicolin Segura',
  ];

  int currentIndex = 0;

  void onTapNav(int index) {
    setState(() {
      currentIndex = index;
    });

    // Navegación de prueba
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/inicio');
        break;
      case 1:
        Navigator.pushNamed(context, '/ventas');
        break;
      case 2:
        Navigator.pushNamed(context, '/estadisticas');
        break;
      case 3:
        Navigator.pushNamed(context, '/movimientos');
        break;
      case 4:
        Navigator.pushNamed(context, '/cuenta');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.secondary),
          onPressed: () {},
        ),
        title: const Text(
          'Clientes',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.secondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/estrellas.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cafecin,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Nombres',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verde,
                        foregroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AgregarCliente(),
                          ),
                        );
                      },
                      child: const Text(
                        'Agregar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: clientes.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: AppColors.accent,
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.secondary,
                            child: Icon(Icons.person, color: AppColors.accent),
                          ),
                          title: Text(
                            clientes[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          onTap: () {
                            // Vista detallada del cliente (si deseas)
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTapNav,
      ),
    );
  }
}
