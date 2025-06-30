import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class AgregarProveedorScreen extends StatefulWidget {
  const AgregarProveedorScreen({super.key});

  @override
  State<AgregarProveedorScreen> createState() => _AgregarProveedorScreenState();
}

class _AgregarProveedorScreenState extends State<AgregarProveedorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _guardarProveedor() async {
    final proveedor = {
      'nombre': _nombreController.text,
      'telefono': _telefonoController.text,
      'direccion': _direccionController.text,
      'descripcion': _descripcionController.text,
      'fecha': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('proveedores').add(proveedor);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor guardado exitosamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Agregar Proveedor',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/oficina.png', fit: BoxFit.cover),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    kToolbarHeight - // Altura del AppBar
                    MediaQuery.of(context).padding.top, // Altura del status bar
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del proveedor',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: AppColors.accent,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese el nombre'
                          : null,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                        filled: true,
                        fillColor: AppColors.accent,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese el teléfono'
                          : null,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _direccionController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                        filled: true,
                        fillColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                        filled: true,
                        fillColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 100),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _guardarProveedor();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Guardar Proveedor',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
