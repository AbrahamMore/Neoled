import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class AgregarInventarioScreen extends StatefulWidget {
  const AgregarInventarioScreen({super.key});

  @override
  State<AgregarInventarioScreen> createState() =>
      _AgregarInventarioScreenState();
}

class _AgregarInventarioScreenState extends State<AgregarInventarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codigoBarrasController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void dispose() {
    _codigoBarrasController.dispose();
    _nombreController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _guardarProducto() async {
    final producto = {
      'codigo_barras': _codigoBarrasController.text,
      'nombre': _nombreController.text,
      'cantidad': int.parse(_cantidadController.text),
      'precio': double.parse(_precioController.text),
      'descripcion': _descripcionController.text,
      'fecha': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('inventario').add(producto);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado exitosamente')),
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
      resizeToAvoidBottomInset:
          false, // <-- evita que la imagen se mueva con el teclado
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Agregar Producto',
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
          // Imagen de fondo fija
          Positioned.fill(
            child: Image.asset('assets/images/oficina.png', fit: BoxFit.cover),
          ),

          // Formulario con scroll
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    // Código de barras
                    TextFormField(
                      controller: _codigoBarrasController,
                      decoration: InputDecoration(
                        labelText: 'Código de barras',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.qr_code),
                        filled: true,
                        fillColor: AppColors.accent,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el código';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Nombre del producto
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del producto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.shopping_bag),
                        filled: true,
                        fillColor: AppColors.accent,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Cantidad y precio
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cantidadController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cantidad',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.inventory),
                              filled: true,
                              fillColor: AppColors.accent,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa la cantidad';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _precioController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Precio (\$)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.attach_money),
                              filled: true,
                              fillColor: AppColors.accent,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa el precio';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Descripción
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

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _guardarProducto();
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
                          'Guardar Producto',
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
