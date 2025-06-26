import 'package:flutter/material.dart';
import 'package:pasos_flutter/core/app_colors.dart'; // Ajusta la ruta

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agregar Producto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 45),
              // Campo: Código de barras
              TextFormField(
                controller: _codigoBarrasController,
                decoration: InputDecoration(
                  labelText: 'Código de barras',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el código';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Campo: Nombre del producto
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Campos: Cantidad y Precio (en fila)
              Row(
                children: [
                  // Campo: Cantidad
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
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa la cantidad';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16), // << Aumenta este valor
                  // Campo: Precio
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

              // Campo: Descripción
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 100),

              // Botón para guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Guardar el producto (aquí iría tu lógica o Firebase)
                      _guardarProducto();
                      Navigator.pop(context); // Regresa a la pantalla anterior
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
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardarProducto() {
    // Lógica para guardar en Firestore/SQLite/API
    final nuevoProducto = {
      'codigo_barras': _codigoBarrasController.text,
      'nombre': _nombreController.text,
      'cantidad': int.parse(_cantidadController.text),
      'precio': double.parse(_precioController.text),
      'descripcion': _descripcionController.text,
    };
    print(
      'Producto guardado: $nuevoProducto',
    ); // Reemplaza con tu implementación real
  }
}
