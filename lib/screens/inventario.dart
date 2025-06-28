import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'agregar_inventario.dart';
import 'detalle_producto.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String _busqueda = '';
  final TextEditingController _controllerBusqueda = TextEditingController();

  void limpiarBusqueda() {
    setState(() {
      _busqueda = '';
      _controllerBusqueda.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Inventario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false, // 👈 ¡Esto evita que se mueva el fondo!
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/oficina.png', fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Campo de búsqueda con botón de limpiar
                TextField(
                  controller: _controllerBusqueda,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: limpiarBusqueda,
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Imagen",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Nombre",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "Piezas",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('inventario')
                        .orderBy('nombre') // Orden alfabético A-Z
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No hay productos.'));
                      }

                      final productos = snapshot.data!.docs.where((doc) {
                        final nombre =
                            doc['nombre']?.toString().toLowerCase() ?? '';
                        return nombre.contains(_busqueda);
                      }).toList();

                      return ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final producto = productos[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetalleProductoScreen(producto: producto),
                                ),
                              );
                            },
                            child: _buildInventoryItem(
                              name: producto['nombre'],
                              price: producto['precio'],
                              quantity: producto['cantidad'].toString(),
                              imagePath: 'assets/producto.png',
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgregarInventarioScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildInventoryItem({
    required String name,
    required dynamic price,
    required String quantity,
    required String imagePath,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$${price.toString()}",
                    style: TextStyle(
                      fontSize: 14,
                      color: price > 0 ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                quantity,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
