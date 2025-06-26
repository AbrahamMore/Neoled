import 'package:flutter/material.dart';
import 'package:pasos_flutter/components/custom_bottom.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class AgregarCliente extends StatefulWidget {
  const AgregarCliente({super.key});

  @override
  State<AgregarCliente> createState() => _AgregarClienteState();
}

class _AgregarClienteState extends State<AgregarCliente> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo fijo fuera del Scaffold
        Positioned.fill(
          child: Image.asset('assets/images/estrellas.jpg', fit: BoxFit.cover),
        ),

        // Contenido sobre el fondo
        Scaffold(
          backgroundColor: Colors.transparent, // transparente para ver el fondo
          resizeToAvoidBottomInset: true, // permite scroll al aparecer teclado
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: const Text(
              'Clientes',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: AppColors.secondary),
              onPressed: () {},
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.secondary),
                onPressed: () {},
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    20,
                  ), // Padding fijo
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Center(child: _buildAvatar()),
                        const SizedBox(height: 15),
                        _buildFormField('Nombre', Icons.person),
                        const SizedBox(height: 15),
                        _buildFormField('Apellidos', Icons.person_outline),
                        const SizedBox(height: 15),
                        _buildFormField('Dirección', Icons.location_on),
                        const SizedBox(height: 15),
                        _buildFormField(
                          'Teléfono',
                          Icons.phone,
                          TextInputType.phone,
                        ),
                        const SizedBox(height: 15),
                        _buildFormField(
                          'Correo Electrónico',
                          Icons.email,
                          TextInputType.emailAddress,
                        ),
                        // Espacio para el teclado (opcional)
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom > 0
                              ? MediaQuery.of(context).viewInsets.bottom
                              : 0,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Botón fijo abajo
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: ElevatedButton(
                  onPressed: () => _guardarCliente(context),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(AppColors.verde),
                    foregroundColor: WidgetStateProperty.all(AppColors.accent),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    minimumSize: WidgetStateProperty.all(
                      const Size(double.infinity, 50),
                    ),
                    overlayColor: WidgetStateProperty.all(Colors.white24),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              CustomBottomNavBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                  _navigateTo(index, context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 115,
          height: 115,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
          ),
        ),
        IconButton(
          iconSize: 60,
          icon: const Icon(Icons.camera_alt, color: AppColors.azul),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFormField(String label, IconData icon, [TextInputType? type]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: TextFormField(
        keyboardType: type,
        style: const TextStyle(
          color: AppColors.rojo,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: Icon(icon, color: AppColors.secondary),
          filled: true,
          fillColor: AppColors.accent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  void _guardarCliente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente guardado exitosamente')),
    );
    Navigator.pop(context);
  }

  void _navigateTo(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        break;
      default:
        Navigator.pop(context);
    }
  }
}
