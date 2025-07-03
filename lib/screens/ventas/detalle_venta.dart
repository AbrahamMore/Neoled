import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pasos_flutter/core/app_colors.dart';

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
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo identificar al usuario'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final ventaRef = await _firestore.collection('ventas').add({
        'usuarioId': user.uid,
        'usuarioNombre': user.displayName ?? 'Sin nombre',
        'fecha': FieldValue.serverTimestamp(),
        'total': _totalVenta,
        'nombreVenta': _nombreVentaController.text.trim(),
        'clienteId': _clienteSeleccionadoId,
        'clienteNombre': _clienteSeleccionadoNombre,
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
    clientes.docs.map((doc) {
      final data = doc.data();
      return SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, {
            'id': doc.id,
            'nombre': data['nombre'] ?? 'Sin nombre',
          });
        },
        child: Text(data['nombre'] ?? 'Sin nombre'),
      );
    }).toList();

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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person),
                        label: Text(
                          _clienteSeleccionadoNombre != null
                              ? 'Cliente: $_clienteSeleccionadoNombre'
                              : 'Seleccionar cliente',
                        ),
                        onPressed: _seleccionarCliente,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.secondary,
                        ),
                      ),
                    ),
                    if (_clienteSeleccionadoNombre != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _clienteSeleccionadoId = null;
                            _clienteSeleccionadoNombre = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _productosSeleccionados.isEmpty
                ? const Center(child: Text('No hay productos seleccionados'))
                : ListView.builder(
                    itemCount: _productosSeleccionados.length,
                    itemBuilder: (context, index) {
                      final producto = _productosSeleccionados[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.shopping_cart,
                            color: AppColors.secondary,
                          ),
                          title: Text(producto['nombre']),
                          subtitle: Text(
                            'Precio: \$${producto['precio'].toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (producto['cantidadSeleccionada'] > 1) {
                                    _actualizarCantidad(
                                      index,
                                      producto['cantidadSeleccionada'] - 1,
                                    );
                                  } else {
                                    _eliminarProducto(index);
                                  }
                                },
                              ),
                              Text(producto['cantidadSeleccionada'].toString()),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
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
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.rojo,
                                ),
                                onPressed: () => _eliminarProducto(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_totalVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _finalizarVenta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Finalizar Venta',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
