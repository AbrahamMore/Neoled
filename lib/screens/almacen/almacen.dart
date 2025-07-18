import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:intl/intl.dart';

class AlmacenScreen extends StatefulWidget {
  const AlmacenScreen({super.key});

  @override
  State<AlmacenScreen> createState() => _AlmacenScreenState();
}

class _AlmacenScreenState extends State<AlmacenScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _usuarioSeleccionado = '';
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _productosFiltrados = [];
  List<String> _usuarios = [];
  bool _showHistory = false;
  List<String> _productosSeleccionados = [];
  Map<String, int> _cantidadesPorProducto = {};

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _cargarUsuarios();
    _searchController.addListener(_filtrarProductos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('inventario')
        .where('cantidad', isGreaterThan: 0)
        .get();

    setState(() {
      _productos = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
      _productosFiltrados = List.from(_productos);
    });
  }

  Future<void> _cargarUsuarios() async {
    // Reemplaza esto con tu consulta a Firestore para usuarios
    setState(() {
      _usuarios = [
        'Juan Pérez',
        'María García',
        'Carlos López',
        'Ana Martínez',
      ];
      if (_usuarios.isNotEmpty) {
        _usuarioSeleccionado = _usuarios.first;
      }
    });
  }

  void _filtrarProductos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _productosFiltrados = _productos.where((producto) {
        return producto['nombre'].toString().toLowerCase().contains(query) ||
            producto['codigo_barras'].toString().contains(query);
      }).toList();
    });
  }

  void _toggleSeleccionProducto(String productoId) {
    setState(() {
      if (_productosSeleccionados.contains(productoId)) {
        _productosSeleccionados.remove(productoId);
        _cantidadesPorProducto.remove(productoId);
      } else {
        _productosSeleccionados.add(productoId);
        _cantidadesPorProducto[productoId] = 1;
      }
    });
  }

  void _actualizarCantidad(String productoId, int cantidad) {
    setState(() {
      _cantidadesPorProducto[productoId] = cantidad;
    });
  }

  Future<void> _registrarSalidas() async {
    if (_productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona al menos un producto'),
          backgroundColor: Colors.red, // Color rojo para advertencia
        ),
      );
      return;
    }

    if (_usuarioSeleccionado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona un usuario'),
          backgroundColor: Colors.red, // Color rojo para advertencia
        ),
      );
      return;
    }

    // Validar cantidades
    for (var productoId in _productosSeleccionados) {
      final producto = _productos.firstWhere((p) => p['id'] == productoId);
      final cantidad = _cantidadesPorProducto[productoId] ?? 1;

      if (cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cantidad inválida para ${producto['nombre']}'),
            backgroundColor: Colors.red, // Color rojo para advertencia
          ),
        );
        return;
      }

      if (cantidad > producto['cantidad']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No hay suficiente stock de ${producto['nombre']}. Disponible: ${producto['cantidad']}',
            ),
            backgroundColor: Colors.red, // Color rojo para advertencia
          ),
        );
        return;
      }
    }

    final batch = FirebaseFirestore.instance.batch();
    final ahora = Timestamp.now();

    try {
      // Registrar cada movimiento y actualizar inventario
      for (var productoId in _productosSeleccionados) {
        final producto = _productos.firstWhere((p) => p['id'] == productoId);
        final cantidad = _cantidadesPorProducto[productoId] ?? 1;

        // Registrar movimiento
        final movimientoRef = FirebaseFirestore.instance
            .collection('almacen')
            .doc();
        batch.set(movimientoRef, {
          'producto_id': productoId,
          'producto_nombre': producto['nombre'],
          'usuario': _usuarioSeleccionado,
          'cantidad': cantidad,
          'fecha': ahora,
          'tipo': 'salida',
        });

        // Actualizar inventario
        final inventarioRef = FirebaseFirestore.instance
            .collection('inventario')
            .doc(productoId);
        batch.update(inventarioRef, {
          'cantidad': FieldValue.increment(-cantidad),
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salidas registradas correctamente'),
          backgroundColor: Colors.green, // Color verde para éxito
        ),
      );

      // Limpiar y recargar
      setState(() {
        _productosSeleccionados.clear();
        _cantidadesPorProducto.clear();
      });
      _cargarProductos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar: $e'),
          backgroundColor: Colors.red, // Color rojo para error
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          _showHistory ? 'Historial de Almacén' : 'Registrar Salidas',
          style: const TextStyle(color: AppColors.secondary),
        ),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.add : Icons.history),
            onPressed: () {
              setState(() {
                _showHistory = !_showHistory;
                if (!_showHistory) {
                  _productosSeleccionados.clear();
                  _cantidadesPorProducto.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _showHistory ? _buildHistorial() : _buildRegistroSalida(),
    );
  }

  Widget _buildRegistroSalida() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Buscador de productos
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar producto',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.accent,
            ),
          ),
          const SizedBox(height: 20),

          // Selección de usuario
          DropdownButtonFormField<String>(
            value: _usuarioSeleccionado.isNotEmpty
                ? _usuarioSeleccionado
                : null,
            decoration: InputDecoration(
              labelText: 'Persona que retira',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: AppColors.accent,
            ),
            items: _usuarios.map((usuario) {
              return DropdownMenuItem<String>(
                value: usuario,
                child: Text(usuario),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _usuarioSeleccionado = value!;
              });
            },
          ),
          const SizedBox(height: 20),

          // Botón para registrar salida
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registrarSalidas,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Registrar Salidas',
                style: TextStyle(fontSize: 16, color: AppColors.secondary),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Lista de productos filtrados con selección múltiple
          if (_productosFiltrados.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _productosFiltrados.length,
              itemBuilder: (context, index) {
                final producto = _productosFiltrados[index];
                final isSelected = _productosSeleccionados.contains(
                  producto['id'],
                );
                final cantidad = _cantidadesPorProducto[producto['id']] ?? 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _toggleSeleccionProducto(producto['id']),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) =>
                                    _toggleSeleccionProducto(producto['id']),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      producto['nombre'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('Disponible: ${producto['cantidad']}'),
                                    Text(
                                      'Código: ${producto['codigo_barras']}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Cantidad: '),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: cantidad.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                    ),
                                    onChanged: (value) {
                                      final nuevaCantidad =
                                          int.tryParse(value) ?? 1;
                                      _actualizarCantidad(
                                        producto['id'],
                                        nuevaCantidad,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildHistorial() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('almacen')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final movimientos = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: movimientos.length,
          itemBuilder: (context, index) {
            final movimiento =
                movimientos[index].data() as Map<String, dynamic>;
            final fecha = (movimiento['fecha'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(movimiento['producto_nombre']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Retiró: ${movimiento['usuario']}'),
                    Text('Cantidad: ${movimiento['cantidad']}'),
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(fecha)),
                  ],
                ),
                // Se ha eliminado el icono de flecha
              ),
            );
          },
        );
      },
    );
  }
}
