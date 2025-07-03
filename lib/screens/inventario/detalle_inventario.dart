import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class DetalleProductoScreen extends StatefulWidget {
  final DocumentSnapshot producto;

  const DetalleProductoScreen({super.key, required this.producto});

  @override
  State<DetalleProductoScreen> createState() => _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _cantidadController;
  late TextEditingController _precioController;
  late TextEditingController _descripcionController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto['nombre']);
    _cantidadController = TextEditingController(
      text: widget.producto['cantidad'].toString(),
    );
    _precioController = TextEditingController(
      text: widget.producto['precio'].toString(),
    );
    _descripcionController = TextEditingController(
      text: widget.producto['descripcion'],
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    await FirebaseFirestore.instance
        .collection('inventario')
        .doc(widget.producto.id)
        .update({
          'nombre': _nombreController.text,
          'cantidad': int.tryParse(_cantidadController.text) ?? 0,
          'precio': double.tryParse(_precioController.text) ?? 0,
          'descripcion': _descripcionController.text,
        });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
      Navigator.pop(context);
    }
  }

  void _eliminarProducto() async {
    await FirebaseFirestore.instance
        .collection('inventario')
        .doc(widget.producto.id)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ← Mantiene el fondo fijo
      appBar: AppBar(
        title: const Text(
          'Detalle del Producto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo fijo
          Positioned.fill(
            child: Image.asset('assets/images/planeta.png', fit: BoxFit.cover),
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

                        _buildCampo(
                          'Nombre',
                          _nombreController,
                          Icons.shopping_bag,
                        ),
                        const SizedBox(height: 16),

                        _buildCampo(
                          'Cantidad',
                          _cantidadController,
                          Icons.inventory,
                          isNumber: true,
                        ),
                        const SizedBox(height: 16),

                        _buildCampo(
                          'Precio (\$)',
                          _precioController,
                          Icons.attach_money,
                          isNumber: true,
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
                            onPressed: _eliminarProducto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Eliminar Producto',
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
