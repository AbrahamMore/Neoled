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
  late List<Map<String, dynamic>> _productosSeleccionadosInternos;
  final Map<String, TextEditingController> _controladores = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _productosSeleccionadosInternos = List.from(widget.productosSeleccionados);
    _inicializarControladores();
  }

  void _inicializarControladores() {
    for (var producto in _productosSeleccionadosInternos) {
      final id = producto['id'];
      _controladores[id] = TextEditingController(
        text: producto['cantidadSeleccionada'].toString(),
      );
      _focusNodes[id] = FocusNode();
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    for (var controller in _controladores.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _actualizarCantidad(
    String productoId,
    String valorTexto,
    Map<String, dynamic> productoData,
  ) {
    // Si el campo está vacío, mostramos '0' como placeholder
    if (valorTexto.isEmpty) {
      _controladores[productoId]?.text = '0';
      return;
    }

    final cantidad = int.tryParse(valorTexto) ?? 0;
    final productoIndex = _productosSeleccionadosInternos.indexWhere(
      (p) => p['id'] == productoId,
    );

    // Eliminamos la validación de stock
    if (cantidad <= 0) {
      if (productoIndex != -1) {
        setState(() {
          _productosSeleccionadosInternos.removeAt(productoIndex);
          _controladores[productoId]?.text = '0';
          _focusNodes[productoId]?.unfocus();
        });
      }
      return;
    }

    if (productoIndex != -1) {
      setState(() {
        _productosSeleccionadosInternos[productoIndex]['cantidadSeleccionada'] =
            cantidad;
      });
    } else {
      setState(() {
        _productosSeleccionadosInternos.add({
          ...productoData,
          'id': productoId,
          'cantidadSeleccionada': cantidad,
        });
      });
    }
  }

  void _eliminarProducto(String productoId) {
    setState(() {
      _productosSeleccionadosInternos.removeWhere(
        (producto) => producto['id'] == productoId,
      );
      _controladores[productoId]?.text = '0'; // Volvemos al placeholder
      _focusNodes[productoId]?.unfocus(); // Quitamos el foco
    });
  }

  void _guardarSeleccion() {
    // Forzar actualización de todos los campos editados
    for (var entry in _controladores.entries) {
      final producto = _productosSeleccionadosInternos.firstWhere(
        (p) => p['id'] == entry.key,
        orElse: () => {},
      );
      if (producto.isNotEmpty) {
        _actualizarCantidad(entry.key, entry.value.text, producto);
      }
    }

    widget.onProductosSeleccionados(_productosSeleccionadosInternos);
    Navigator.pop(context, _productosSeleccionadosInternos);
  }

  Widget _buildProductoItem(DocumentSnapshot productoDoc) {
    final productoId = productoDoc.id;
    final data = productoDoc.data() as Map<String, dynamic>;
    final productoSeleccionado = _productosSeleccionadosInternos.firstWhere(
      (p) => p['id'] == productoId,
      orElse: () => {},
    );

    final stockDisponible = data['cantidad'] ?? 0;

    // Inicializamos el controlador con '0' como placeholder si no hay cantidad seleccionada
    _controladores.putIfAbsent(
      productoId,
      () => TextEditingController(
        text: productoSeleccionado.isNotEmpty
            ? productoSeleccionado['cantidadSeleccionada'].toString()
            : '0',
      ),
    );

    _focusNodes.putIfAbsent(productoId, () => FocusNode());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(data['nombre'] ?? 'Sin nombre'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Precio: \$${(data['precio'] ?? 0).toStringAsFixed(2)}'),
            Text(
              'Stock: $stockDisponible',
              style: TextStyle(
                color: stockDisponible <= 0 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (productoSeleccionado.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Eliminar producto',
                onPressed: () => _eliminarProducto(productoId),
              ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: _controladores[productoId],
                focusNode: _focusNodes[productoId],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: '0',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _actualizarCantidad(productoId, value, data);
                  }
                },
                onTap: () {
                  if (_controladores[productoId]?.text == '0') {
                    _controladores[productoId]?.clear();
                  }
                },
                // Elimina onEditingComplete para evitar cierre no deseado
                onSubmitted: (value) {
                  _actualizarCantidad(productoId, value, data);
                  _focusNodes[productoId]?.unfocus();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Productos'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.secondary),
            tooltip: 'Confirmar selección',
            onPressed: _guardarSeleccion,
          ),
        ],
      ),
      body: Column(
        children: [
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
          if (_productosSeleccionadosInternos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    'Productos seleccionados: ${_productosSeleccionadosInternos.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _productosSeleccionadosInternos.clear();
                        _controladores.forEach((key, controller) {
                          controller.text = '0'; // Resetear a placeholder
                        });
                      });
                    },
                    child: const Text(
                      'Limpiar todo',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
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
                  itemBuilder: (context, index) =>
                      _buildProductoItem(productos[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
