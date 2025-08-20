import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/gastos/seleccionar_productos.dart';
import 'package:pasos_flutter/screens/gastos/Historial_gastos.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _proveedorController = TextEditingController();

  String _categoriaSeleccionada = 'Servicios públicos';
  String _rolUsuario = 'usuario';
  String _tipoPagoSeleccionado = 'Efectivo';
  String? _proveedorSeleccionado;
  List<Map<String, dynamic>> _productosSeleccionados = [];
  double _valorTotalProductos = 0.0;
  DateTime? _fechaSeleccionada;

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
  void dispose() {
    _nombreController.dispose();
    _valorController.dispose();
    _proveedorController.dispose();
    super.dispose();
  }

  Future<void> _mostrarSeleccionProductos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarProductosGastosScreen(
          productosSeleccionados: _productosSeleccionados,
          onProductosSeleccionados: (productos) {
            setState(() {
              _productosSeleccionados = List<Map<String, dynamic>>.from(
                productos,
              );
              _calcularTotalProductos();
            });
            return productos;
          },
        ),
      ),
    );
  }

  void _calcularTotalProductos() {
    double total = 0.0;
    for (var producto in _productosSeleccionados) {
      total +=
          (producto['costoUnitario'] ?? producto['costo'] ?? 0) *
          (producto['cantidadComprada'] ?? 1);
    }
    setState(() {
      _valorTotalProductos = total;
      if (_categoriaSeleccionada == 'Compra de productos e insumos') {
        _valorController.text = total.toStringAsFixed(2);
      }
    });
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Selecciona la fecha del gasto',
    );

    if (fecha != null) {
      if (fecha.isAfter(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pueden registrar gastos con fecha futura'),
              backgroundColor: AppColors.rojo,
            ),
          );
        }
      } else {
        setState(() {
          _fechaSeleccionada = fecha;
        });
      }
    }
  }

  Future<void> _registrarGasto() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nombreController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre del gasto es obligatorio'),
            backgroundColor: AppColors.rojo,
          ),
        );
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final rol = userDoc.data()?['rol']?.toString() ?? 'usuario';

      setState(() {
        _rolUsuario = rol;
      });

      DateTime fechaActual = DateTime.now();
      DateTime fechaCombinada = _fechaSeleccionada != null
          ? DateTime(
              _fechaSeleccionada!.year,
              _fechaSeleccionada!.month,
              _fechaSeleccionada!.day,
              fechaActual.hour,
              fechaActual.minute,
              fechaActual.second,
            )
          : fechaActual;

      final gastoData = {
        'nombre': _nombreController
            .text, // Ahora siempre tiene valor (no puede ser null)
        'categoria': _categoriaSeleccionada,
        'valor': _categoriaSeleccionada == 'Compra de productos e insumos'
            ? _valorTotalProductos
            : double.parse(_valorController.text),
        'tipoPago': _tipoPagoSeleccionado,
        'usuarioId': user.uid,
        'usuarioNombre': user.displayName ?? user.email,
        'fecha': Timestamp.fromDate(fechaCombinada),
        'rolUsuario': rol,
      };

      if (_proveedorSeleccionado != null) {
        gastoData['proveedorId'] = _proveedorSeleccionado;
      }

      if (_categoriaSeleccionada == 'Compra de productos e insumos' &&
          _productosSeleccionados.isNotEmpty) {
        gastoData['productos'] = _productosSeleccionados.map((producto) {
          return {
            'id': producto['id'],
            'nombre': producto['nombre'],
            'cantidadComprada': producto['cantidadComprada'],
            'costoUnitario': producto['costoUnitario'] ?? producto['costo'],
            'subtotal':
                (producto['costoUnitario'] ?? producto['costo']) *
                (producto['cantidadComprada'] ?? 1),
          };
        }).toList();

        final batch = FirebaseFirestore.instance.batch();

        for (var producto in _productosSeleccionados) {
          final productoRef = FirebaseFirestore.instance
              .collection('inventario')
              .doc(producto['id']);

          batch.update(productoRef, {
            'cantidad': FieldValue.increment(producto['cantidadComprada'] ?? 1),
          });
        }

        await batch.commit();
      }

      await FirebaseFirestore.instance.collection('gastos').add(gastoData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gasto registrado exitosamente'),
            backgroundColor: AppColors.verde,
          ),
        );

        _formKey.currentState?.reset();
        _nombreController.clear();
        _valorController.clear();
        _proveedorSeleccionado = null;
        _productosSeleccionados = [];
        _valorTotalProductos = 0.0;
        _fechaSeleccionada = null;
        setState(() {});
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistorialGastosScreen(),
                ),
              );
            },
          ),
        ],
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
                  labelText:
                      'Nombre del gasto', // Cambiado de "(opcional)" a obligatorio
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorStyle: TextStyle(
                    color: AppColors.rojo,
                  ), // Mensaje de error en rojo
                ),
                validator: (value) {
                  // Añadir validador
                  if (value == null || value.isEmpty) {
                    return 'El nombre del gasto es obligatorio';
                  }
                  return null;
                },
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
                        style: TextStyle(color: AppColors.secondary),
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
                                'Cantidad: ${producto['cantidadComprada'] ?? 1} - Costo: \$${(producto['costoUnitario'] ?? producto['costo'] ?? 0).toStringAsFixed(2)}',
                              ),
                              trailing: Text(
                                '\$${((producto['costoUnitario'] ?? producto['costo'] ?? 0) * (producto['cantidadComprada'] ?? 1)).toStringAsFixed(2)}',
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

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _fechaSeleccionada != null
                            ? 'Fecha: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}'
                            : 'Seleccionar fecha',
                      ),
                      onPressed: () => _seleccionarFecha(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

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
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
