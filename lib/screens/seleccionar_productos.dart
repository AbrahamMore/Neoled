import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class SeleccionarProductosGastosScreen extends StatefulWidget {
  final List<Map<String, dynamic>> productosSeleccionados;
  final Function(List<Map<String, dynamic>>) onProductosSeleccionados;

  const SeleccionarProductosGastosScreen({
    super.key,
    required this.productosSeleccionados,
    required this.onProductosSeleccionados,
  });

  @override
  State<SeleccionarProductosGastosScreen> createState() =>
      _SeleccionarProductosGastosScreenState();
}

class _SeleccionarProductosGastosScreenState
    extends State<SeleccionarProductosGastosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _busquedaController = TextEditingController();
  String _busqueda = '';
  List<Map<String, dynamic>> _productosSeleccionadosInternos = [];

  @override
  void initState() {
    super.initState();
    _productosSeleccionadosInternos = List.from(widget.productosSeleccionados);
  }

  void _modificarCantidad(Map<String, dynamic> producto, int cambio) {
    setState(() {
      final index = _productosSeleccionadosInternos.indexWhere(
        (p) => p['id'] == producto['id'],
      );

      if (index != -1) {
        final nuevaCantidad =
            _productosSeleccionadosInternos[index]['cantidadSeleccionada'] +
            cambio;

        if (nuevaCantidad > 0) {
          _productosSeleccionadosInternos[index]['cantidadSeleccionada'] =
              nuevaCantidad;
        } else {
          _productosSeleccionadosInternos.removeAt(index);
        }
      } else if (cambio > 0) {
        _productosSeleccionadosInternos.add({
          ...producto,
          'cantidadSeleccionada': cambio,
        });
      }
    });
  }

  void _eliminarProducto(String productoId) {
    setState(() {
      _productosSeleccionadosInternos.removeWhere((p) => p['id'] == productoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Productos'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              widget.onProductosSeleccionados(_productosSeleccionadosInternos);
              Navigator.pop(context, _productosSeleccionadosInternos);
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
                hintStyle: const TextStyle(color: Colors.yellow),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.primary),
                        onPressed: () {
                          setState(() {
                            _busqueda = '';
                            _busquedaController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.secondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) =>
                  setState(() => _busqueda = value.toLowerCase()),
            ),
          ),

          // Lista de productos seleccionados
          if (_productosSeleccionadosInternos.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Productos seleccionados:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ..._productosSeleccionadosInternos.map((producto) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(producto['nombre'] ?? 'Sin nombre'),
                        subtitle: Text(
                          'Cantidad: ${producto['cantidadSeleccionada']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarProducto(producto['id']),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          // Lista de productos disponibles
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('inventario').snapshots(),
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
                  final data = doc.data() as Map<String, dynamic>;
                  return _busqueda.isEmpty ||
                      (data['nombre']?.toString().toLowerCase().contains(
                            _busqueda,
                          ) ??
                          false);
                }).toList();

                return ListView.builder(
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    final data = producto.data() as Map<String, dynamic>;
                    final productoId = producto.id;
                    final cantidadSeleccionada =
                        _productosSeleccionadosInternos.firstWhere(
                          (p) => p['id'] == productoId,
                          orElse: () => {},
                        )['cantidadSeleccionada'] ??
                        0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(data['nombre'] ?? 'Sin nombre'),
                        subtitle: Text(
                          'Precio: \$${(data['precio'] ?? 0).toStringAsFixed(2)} - Stock: ${data['cantidad'] ?? 0}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cantidadSeleccionada > 0)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  color: Colors.red,
                                ),
                                onPressed: () => _modificarCantidad({
                                  'id': productoId,
                                  'nombre': data['nombre'],
                                  'precio': (data['precio'] ?? 0).toDouble(),
                                  'cantidad': (data['cantidad'] ?? 0).toInt(),
                                }, -1),
                              ),
                            Text(
                              cantidadSeleccionada > 0
                                  ? cantidadSeleccionada.toString()
                                  : '',
                              style: const TextStyle(fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () => _modificarCantidad({
                                'id': productoId,
                                'nombre': data['nombre'],
                                'precio': (data['precio'] ?? 0).toDouble(),
                                'cantidad': (data['cantidad'] ?? 0).toInt(),
                              }, 1),
                            ),
                          ],
                        ),
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
