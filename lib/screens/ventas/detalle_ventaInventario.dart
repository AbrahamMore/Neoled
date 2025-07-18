import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'detalle_venta_widgets.dart'; // Importamos el archivo de widgets

class DetalleVentaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> productosSeleccionados;
  final VoidCallback onVentaFinalizada;

  const DetalleVentaScreen({
    super.key,
    required this.productosSeleccionados,
    required this.onVentaFinalizada,
  });

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  late List<Map<String, dynamic>> _productosSeleccionados;
  double _totalVenta = 0.0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nombreVentaController = TextEditingController();
  String? _clienteSeleccionadoId;
  String? _clienteSeleccionadoNombre;
  DateTime? _fechaSeleccionada;
  String? _proveedorSeleccionado;
  String? _tipoPagoSeleccionado;
  final List<String> _tiposPago = [
    'Efectivo',
    'Tarjeta',
    'Transferencia',
    'Crédito',
  ];

  @override
  void initState() {
    super.initState();
    _productosSeleccionados = List.from(widget.productosSeleccionados);
    _calcularTotal();
  }

  @override
  void dispose() {
    _nombreVentaController.dispose();
    super.dispose();
  }

  void _eliminarProducto(int index) {
    setState(() {
      _productosSeleccionados.removeAt(index);
      _calcularTotal();
    });
  }

  void _actualizarCantidad(int index, int nuevaCantidad) {
    setState(() {
      _productosSeleccionados[index]['cantidadSeleccionada'] = nuevaCantidad;
      _calcularTotal();
    });
  }

  void _calcularTotal() {
    _totalVenta = _productosSeleccionados.fold(0.0, (total, producto) {
      return total + (producto['precio'] * producto['cantidadSeleccionada']);
    });
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha de la venta',
    );
    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _finalizarVenta() async {
    if (_nombreVentaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la venta es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar una fecha para la venta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tipoPagoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un tipo de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    for (var producto in _productosSeleccionados) {
      if (producto['cantidadSeleccionada'] > producto['cantidad']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No hay suficiente stock de ${producto['nombre']} (Disponibles: ${producto['cantidad']})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      DateTime now = DateTime.now();
      DateTime fechaConHora = DateTime(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        now.hour,
        now.minute,
        now.second,
      );

      final ventaRef = await _firestore.collection('ventas').add({
        'usuarioId': user.uid,
        'usuarioNombre': user.displayName ?? 'Sin nombre',
        'fecha': Timestamp.fromDate(fechaConHora),
        'total': _totalVenta,
        'nombreVenta': _nombreVentaController.text.trim(),
        'clienteId': _clienteSeleccionadoId,
        'clienteNombre': _clienteSeleccionadoNombre,
        'proveedorId': _proveedorSeleccionado,
        'tipoPago': _tipoPagoSeleccionado,
        'productos': _productosSeleccionados.map((producto) {
          return {
            'id': producto['id'],
            'nombre': producto['nombre'],
            'precio': producto['precio'],
            'cantidad': producto['cantidadSeleccionada'],
          };
        }).toList(),
      });

      final batch = _firestore.batch();
      for (var producto in _productosSeleccionados) {
        final productoRef = _firestore
            .collection('inventario')
            .doc(producto['id']);
        batch.update(productoRef, {
          'cantidad': FieldValue.increment(-producto['cantidadSeleccionada']),
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Venta #${ventaRef.id} registrada con éxito'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onVentaFinalizada();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar la venta: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seleccionarCliente() async {
    final clientes = await _firestore.collection('clientes').get();

    final resultado = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar cliente'),
        children: [
          ...clientes.docs.map((doc) {
            final data = doc.data();
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, {
                  'id': doc.id,
                  'nombre': (data['nombre'] ?? 'Sin nombre').toString(),
                });
              },
              child: Text((data['nombre'] ?? 'Sin nombre').toString()),
            );
          }),
          const Divider(),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: const Text('Cancelar selección'),
          ),
        ],
      ),
    );

    if (resultado != null) {
      setState(() {
        _clienteSeleccionadoId = resultado['id'];
        _clienteSeleccionadoNombre = resultado['nombre'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Resumen de Venta'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sección de formulario
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Campo de nombre de venta
                TextField(
                  controller: _nombreVentaController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la venta',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Selector de cliente
                ClienteSelector(
                  clienteNombre: _clienteSeleccionadoNombre,
                  onSeleccionar: _seleccionarCliente,
                  onEliminar: () {
                    setState(() {
                      _clienteSeleccionadoId = null;
                      _clienteSeleccionadoNombre = null;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Selector de fecha
                FechaSelector(
                  fecha: _fechaSeleccionada,
                  onSeleccionar: () => _seleccionarFecha(context),
                ),
                const SizedBox(height: 8),

                // Selector de proveedor
                ProveedorSelector(
                  proveedorSeleccionado: _proveedorSeleccionado,
                  onChanged: (String? newValue) {
                    setState(() {
                      _proveedorSeleccionado = newValue;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Selector de tipo de pago
                PagoSelector(
                  tipoPagoSeleccionado: _tipoPagoSeleccionado,
                  tiposPago: _tiposPago,
                  onChanged: (String? newValue) {
                    setState(() {
                      _tipoPagoSeleccionado = newValue;
                    });
                  },
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: _productosSeleccionados.isEmpty
                ? const Center(child: Text('No hay productos seleccionados'))
                : ListView.builder(
                    itemCount: _productosSeleccionados.length,
                    itemBuilder: (context, index) {
                      final producto = _productosSeleccionados[index];
                      return ProductoItem(
                        producto: producto,
                        onIncrement: () {
                          if (producto['cantidadSeleccionada'] <
                              producto['cantidad']) {
                            _actualizarCantidad(
                              index,
                              producto['cantidadSeleccionada'] + 1,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No hay suficiente stock de ${producto['nombre']}',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        onDecrement: () {
                          if (producto['cantidadSeleccionada'] > 1) {
                            _actualizarCantidad(
                              index,
                              producto['cantidadSeleccionada'] - 1,
                            );
                          } else {
                            _eliminarProducto(index);
                          }
                        },
                        onEliminar: () => _eliminarProducto(index),
                      );
                    },
                  ),
          ),

          // Panel de total y botón
          TotalPanel(total: _totalVenta, onFinalizar: _finalizarVenta),
        ],
      ),
    );
  }
}
