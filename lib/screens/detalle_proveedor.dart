import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class DetalleProveedorScreen extends StatefulWidget {
  final DocumentSnapshot proveedor;

  const DetalleProveedorScreen({super.key, required this.proveedor});

  @override
  State<DetalleProveedorScreen> createState() => _DetalleProveedorScreenState();
}

class _DetalleProveedorScreenState extends State<DetalleProveedorScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;
  late TextEditingController _descripcionController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.proveedor['nombre']);
    _telefonoController = TextEditingController(
      text: widget.proveedor['telefono'],
    );
    _direccionController = TextEditingController(
      text: widget.proveedor['direccion'] ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.proveedor['descripcion'] ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    await FirebaseFirestore.instance
        .collection('proveedores')
        .doc(widget.proveedor.id)
        .update({
          'nombre': _nombreController.text,
          'telefono': _telefonoController.text,
          'direccion': _direccionController.text,
          'descripcion': _descripcionController.text,
        });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proveedor actualizado')));
      Navigator.pop(context);
    }
  }

  void _eliminarProveedor() async {
    await FirebaseFirestore.instance
        .collection('proveedores')
        .doc(widget.proveedor.id)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proveedor eliminado')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ← Mantiene el fondo fijo
      appBar: AppBar(
        title: const Text(
          'Detalle del Proveedor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo fijo
          Positioned.fill(
            child: Image.asset('assets/images/oficina.png', fit: BoxFit.cover),
          ),

          // Scroll con altura mínima para evitar espacio en blanco
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 30), // espacio bajo el AppBar

                        _buildCampo('Nombre', _nombreController, Icons.person),
                        const SizedBox(height: 16),

                        _buildCampo(
                          'Teléfono',
                          _telefonoController,
                          Icons.phone,
                          isNumber: false,
                        ),
                        const SizedBox(height: 16),

                        _buildCampo(
                          'Dirección',
                          _direccionController,
                          Icons.location_on,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        _buildCampo(
                          'Descripción',
                          _descripcionController,
                          Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Botón Guardar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _guardarCambios,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Guardar Cambios',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botón Eliminar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _eliminarProveedor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Eliminar Proveedor',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCampo(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.accent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
