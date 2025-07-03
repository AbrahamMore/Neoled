import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/ventas/historial_ventas.dart';
import 'package:pasos_flutter/screens/ventas/detalle_venta.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final List<Map<String, dynamic>> _productosSeleccionados = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _agregarProducto(Map<String, dynamic> producto) {
    setState(() {
      final index = _productosSeleccionados.indexWhere(
        (p) => p['id'] == producto['id'],
      );

      if (index != -1) {
        _productosSeleccionados[index]['cantidadSeleccionada'] += 1;
      } else {
        _productosSeleccionados.add({...producto, 'cantidadSeleccionada': 1});
      }
    });
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  if (_productosSeleccionados.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleVentaScreen(
                          productosSeleccionados: _productosSeleccionados,
                          onVentaFinalizada: () {
                            setState(() {
                              _productosSeleccionados.clear();
                            });
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
              if (_productosSeleccionados.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _productosSeleccionados.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _busquedaController,
              style: const TextStyle(
                color: Colors.yellow,
              ), // Texto ingresado amarillo
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                hintStyle: const TextStyle(
                  color: Colors.yellow,
                ), // Hint amarillo
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
              onChanged: (value) {
                setState(() {
                  _busqueda = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
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

                final productos = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    final data = producto.data() as Map<String, dynamic>;

                    if (_busqueda.isNotEmpty &&
                        !data['nombre'].toString().toLowerCase().contains(
                          _busqueda,
                        )) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.add_shopping_cart,
                          color: AppColors.azul,
                        ),

                        title: Text(data['nombre'] ?? ''),
                        subtitle: Text(
                          'Precio: \$${(data['precio'] ?? 0).toStringAsFixed(2)} - Stock: ${data['cantidad']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add, color: AppColors.rojo),
                          onPressed: () {
                            _agregarProducto({
                              'id': producto.id,
                              'nombre': data['nombre'],
                              'precio': (data['precio'] ?? 0).toDouble(),
                              'cantidad': (data['cantidad'] ?? 0).toInt(),
                            });
                          },
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
/*
StreamBuilder<QuerySnapshot>(
  stream: _firestore.collection('inventario').snapshots(), // Primero prueba sin filtros
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      debugPrint('Error al cargar inventario: ${snapshot.error}');
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      debugPrint('No hay documentos en la colección inventario');
      return const Center(child: Text('No hay productos disponibles'));
    }

    final productos = snapshot.data!.docs;
    debugPrint('Número de productos cargados: ${productos.length}');

    // Resto de tu código...
  },
)
 */