import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/seleccionar_productos.dart';
import 'package:intl/intl.dart';

class RegistroGastosScreen extends StatefulWidget {
  const RegistroGastosScreen({super.key});

  @override
  State<RegistroGastosScreen> createState() => _RegistroGastosScreenState();
}

class _RegistroGastosScreenState extends State<RegistroGastosScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _proveedorController = TextEditingController();

  String _categoriaSeleccionada = 'Servicios públicos';
  String _tipoPagoSeleccionado = 'Efectivo';
  String? _proveedorSeleccionado;
  List<Map<String, dynamic>> _productosSeleccionados = [];
  double _valorTotalProductos = 0.0;

  final List<String> _categorias = [
    'Servicios públicos',
    'Arriendo',
    'Nómina',
    'Gastos administrativos',
    'Mercadeo y publicidad',
    'Transporte',
    'Mantenimiento y reparaciones',
    'Equipos',
    'Compra de productos e insumos',
    'Otros',
  ];

  final List<String> _tiposPago = [
    'Efectivo',
    'Tarjeta',
    'Transferencia bancaria',
  ];

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _valorController.dispose();
    _fechaController.dispose();
    _proveedorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fechaController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _mostrarSeleccionProductos() async {
    final productos = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarProductosGastosScreen(
          productosSeleccionados: _productosSeleccionados,
          onProductosSeleccionados: (productos) {
            return productos;
          },
        ),
      ),
    );

    if (productos != null) {
      setState(() {
        _productosSeleccionados = List<Map<String, dynamic>>.from(productos);
        _calcularTotalProductos();
      });
    }
  }

  void _calcularTotalProductos() {
    double total = 0.0;
    for (var producto in _productosSeleccionados) {
      total +=
          (producto['precio'] ?? 0) * (producto['cantidadSeleccionada'] ?? 1);
    }
    setState(() {
      _valorTotalProductos = total;
      if (_categoriaSeleccionada == 'Compra de productos e insumos') {
        _valorController.text = total.toStringAsFixed(2);
      }
    });
  }

  Future<void> _registrarGasto() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final gastoData = {
        'nombre': _nombreController.text.isNotEmpty
            ? _nombreController.text
            : null,
        'categoria': _categoriaSeleccionada,
        'valor': _categoriaSeleccionada == 'Compra de productos e insumos'
            ? _valorTotalProductos
            : double.parse(_valorController.text),
        'fecha': _fechaController.text,
        'tipoPago': _tipoPagoSeleccionado,
        'usuarioId': user.uid,
        'usuarioNombre': user.displayName ?? user.email,
        'fechaRegistro': FieldValue.serverTimestamp(),
      };

      if (_proveedorSeleccionado != null) {
        gastoData['proveedorId'] = _proveedorSeleccionado;
      }

      if (_categoriaSeleccionada == 'Compra de productos e insumos' &&
          _productosSeleccionados.isNotEmpty) {
        gastoData['productos'] = _productosSeleccionados;

        final batch = FirebaseFirestore.instance.batch();

        for (var producto in _productosSeleccionados) {
          final productoRef = FirebaseFirestore.instance
              .collection('inventario')
              .doc(producto['id']);

          // Asegúrate de incrementar la cantidad correctamente
          batch.update(productoRef, {
            'cantidad': FieldValue.increment(
              producto['cantidadSeleccionada'] ?? 1,
            ),
          });
        }

        await batch.commit();
      }

      await FirebaseFirestore.instance.collection('gastos').add(gastoData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto registrado exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al registrar gasto: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Gasto'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del gasto (opcional)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categorias.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _categoriaSeleccionada = newValue!;
                    if (newValue != 'Compra de productos e insumos') {
                      _valorController.text = '';
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_categoriaSeleccionada != 'Compra de productos e insumos')
                TextFormField(
                  controller: _valorController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Valor del gasto',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el valor del gasto';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingrese un valor válido';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              if (_categoriaSeleccionada == 'Compra de productos e insumos')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _mostrarSeleccionProductos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Seleccionar Productos',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Valor total: \$${_valorTotalProductos.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 8),
                    if (_productosSeleccionados.isNotEmpty)
                      Column(
                        children: [
                          const Text(
                            'Productos seleccionados:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ..._productosSeleccionados.map((producto) {
                            return ListTile(
                              title: Text(producto['nombre'] ?? 'Sin nombre'),
                              subtitle: Text(
                                'Cantidad: ${producto['cantidadSeleccionada'] ?? 1} - Precio: \$${(producto['precio'] ?? 0).toStringAsFixed(2)}',
                              ),
                              trailing: Text(
                                '\$${((producto['precio'] ?? 0) * (producto['cantidadSeleccionada'] ?? 1)).toStringAsFixed(2)}',
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    const SizedBox(height: 16),
                  ],
                ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('proveedores')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final proveedores = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _proveedorSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Proveedor (opcional)',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Ninguno'),
                      ),
                      ...proveedores.map((proveedor) {
                        return DropdownMenuItem<String>(
                          value: proveedor.id,
                          child: Text(proveedor['nombre'] ?? 'Sin nombre'),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _proveedorSeleccionado = newValue;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _tipoPagoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de pago',
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _tiposPago.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _tipoPagoSeleccionado = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione un tipo de pago';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _fechaController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onTap: () => _seleccionarFecha(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione una fecha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _registrarGasto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Registrar Gasto',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
