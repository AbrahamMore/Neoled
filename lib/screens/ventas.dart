import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final List<Map<String, dynamic>> _productosSeleccionados = [];
  double _totalVenta = 0.0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _agregarProducto(Map<String, dynamic> producto) {
    setState(() {
      // Verificar si el producto ya está en la lista
      final index = _productosSeleccionados.indexWhere(
        (p) => p['id'] == producto['id'],
      );

      if (index != -1) {
        // Si ya existe, incrementar la cantidad
        _productosSeleccionados[index]['cantidadSeleccionada'] += 1;
      } else {
        // Si no existe, agregarlo con cantidad 1
        _productosSeleccionados.add({...producto, 'cantidadSeleccionada': 1});
      }

      _calcularTotal();
    });
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
    if (_productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos seleccionados'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar que haya suficiente stock
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
      // Obtener información del usuario actual
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

      // Crear documento de venta
      final ventaRef = await _firestore.collection('ventas').add({
        'usuarioId': user.uid,
        'usuarioNombre': user.displayName ?? 'Sin nombre',
        'fecha': FieldValue.serverTimestamp(),
        'total': _totalVenta,
        'productos': _productosSeleccionados.map((producto) {
          return {
            'id': producto['id'],
            'nombre': producto['nombre'],
            'precio': producto['precio'],
            'cantidad': producto['cantidadSeleccionada'],
          };
        }).toList(),
      });

      // Actualizar inventario para cada producto
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

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Venta #${ventaRef.id} registrada con éxito'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar la lista de productos seleccionados
      setState(() {
        _productosSeleccionados.clear();
        _totalVenta = 0.0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar la venta: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Nueva Venta'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistorialVentasScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _busqueda = '';
                            _busquedaController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _busqueda = value.toLowerCase();
                });
              },
            ),
          ),

          // Lista de productos seleccionados
          Expanded(
            flex: 2,
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

          // Total y botón de finalizar venta
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

          // Lista de productos disponibles
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Productos Disponibles',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('inventario')
                  .where('cantidad', isGreaterThan: 0)
                  .orderBy('cantidad')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay productos disponibles'),
                  );
                }

                final productos = snapshot.data!.docs.where((doc) {
                  if (_busqueda.isEmpty) return true;
                  final nombre = doc['nombre']?.toString().toLowerCase() ?? '';
                  return nombre.contains(_busqueda);
                }).toList();

                return ListView.builder(
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    final data = producto.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.inventory, color: Colors.blue),
                      title: Text(data['nombre']),
                      subtitle: Text(
                        'Precio: \$${data['precio'].toStringAsFixed(2)} - Stock: ${data['cantidad']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Color.fromARGB(255, 34, 58, 35),
                        ),
                        onPressed: () =>
                            _agregarProducto({...data, 'id': producto.id}),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HistorialVentasScreen extends StatelessWidget {
  const HistorialVentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Historial de Ventas'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ventas')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay ventas registradas'));
          }

          final ventas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];
              final data = venta.data() as Map<String, dynamic>;
              final fecha = (data['fecha'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  leading: const Icon(Icons.receipt, color: AppColors.primary),
                  title: Text('Venta #${venta.id.substring(0, 8)}'),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(fecha)} - Total: \$${data['total'].toStringAsFixed(2)}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vendedor: ${data['usuarioNombre']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Productos:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...(data['productos'] as List).map((producto) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${producto['nombre']} x ${producto['cantidad']}',
                                    ),
                                  ),
                                  Text(
                                    '\$${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${data['total'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
