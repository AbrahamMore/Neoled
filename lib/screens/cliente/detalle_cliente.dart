import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class DetalleCliente extends StatefulWidget {
  final String clienteId;
  final Map<String, dynamic> clienteData;

  const DetalleCliente({
    super.key,
    required this.clienteId,
    required this.clienteData,
  });

  @override
  State<DetalleCliente> createState() => _DetalleClienteState();
}

class _DetalleClienteState extends State<DetalleCliente> {
  late TextEditingController _nombreController;
  late TextEditingController _telefonoController;
  late TextEditingController _correoController;
  late TextEditingController _direccionController;
  late TextEditingController _notasController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.clienteData['nombre'],
    );
    _telefonoController = TextEditingController(
      text: widget.clienteData['telefono'],
    );
    _correoController = TextEditingController(
      text: widget.clienteData['correo'],
    );
    _direccionController = TextEditingController(
      text: widget.clienteData['direccion'],
    );
    _notasController = TextEditingController(text: widget.clienteData['notas']);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    await FirebaseFirestore.instance
        .collection('clientes')
        .doc(widget.clienteId)
        .update({
          'nombre': _nombreController.text,
          'telefono': _telefonoController.text,
          'correo': _correoController.text,
          'direccion': _direccionController.text,
          'notas': _notasController.text,
        });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente actualizado correctamente')),
      );
      Navigator.pop(context);
    }
  }

  void _eliminarCliente() async {
    await FirebaseFirestore.instance
        .collection('clientes')
        .doc(widget.clienteId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cliente eliminado')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Detalle del Cliente',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/estrellas.jpg',
              fit: BoxFit.cover,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        _buildCampo('Nombre', _nombreController, Icons.person),
                        const SizedBox(height: 16),
                        _buildCampo(
                          'Teléfono',
                          _telefonoController,
                          Icons.phone,
                        ),
                        const SizedBox(height: 16),
                        _buildCampo('Correo', _correoController, Icons.email),
                        const SizedBox(height: 16),
                        _buildCampo(
                          'Dirección',
                          _direccionController,
                          Icons.location_on,
                        ),
                        const SizedBox(height: 16),
                        _buildCampo(
                          'Notas',
                          _notasController,
                          Icons.note,
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
                            onPressed: _eliminarCliente,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Eliminar Cliente',
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
  }) {
    return TextField(
      controller: controller,
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
