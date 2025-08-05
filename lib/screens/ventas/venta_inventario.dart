import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/ventas/historial_ventas.dart';
import 'package:pasos_flutter/screens/ventas/detalle_ventaInventario.dart';

class VentaInventarioScreen extends StatefulWidget {
  const VentaInventarioScreen({super.key});

  @override
  State<VentaInventarioScreen> createState() => _VentaInventarioScreenState();
}

class _VentaInventarioScreenState extends State<VentaInventarioScreen> {
  final List<Map<String, dynamic>> _productosSeleccionados = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _busquedaController = TextEditingController();
  String _busqueda = '';
  double _totalVenta = 0.0;
  bool _datosConfirmados = false;
  bool _hayCambiosSinGuardar = false;

  final Map<String, TextEditingController> _cantidadControllers = {};
  final Map<String, TextEditingController> _precioControllers = {};

  @override
  void dispose() {
    _busquedaController.dispose();
    for (var controller in _cantidadControllers.values) {
      controller.dispose();
    }
    for (var controller in _precioControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _agregarProducto(Map<String, dynamic> producto) {
    final productoId = producto['id'];

    setState(() {
      if (!_productosSeleccionados.any((p) => p['id'] == productoId)) {
        _productosSeleccionados.add({
          ...producto,
          'cantidadSeleccionada': 1,
          'precioVenta': producto['precio'],
          'subtotal': producto['precio'] * 1,
        });

        _cantidadControllers[productoId] = TextEditingController(text: '1');
        _precioControllers[productoId] = TextEditingController(
          text: producto['precio'].toStringAsFixed(2),
        );
        _hayCambiosSinGuardar = true;
        _datosConfirmados = false;
      }
    });
  }

  void _actualizarTodosLosProductosSeleccionados() {
    setState(() {
      for (var producto in _productosSeleccionados) {
        final productoId = producto['id'];
        final cantidad =
            int.tryParse(_cantidadControllers[productoId]?.text ?? '0') ?? 0;
        final precio =
            double.tryParse(_precioControllers[productoId]?.text ?? '0') ?? 0.0;

        if (cantidad <= 0) {
          _eliminarProducto(productoId);
          continue;
        }

        if (cantidad > producto['cantidad']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No hay suficiente stock de ${producto['nombre']}'),
            ),
          );
          continue;
        }

        producto['cantidadSeleccionada'] = cantidad;
        producto['precioVenta'] = precio;
        producto['subtotal'] = cantidad * precio;
      }

      _hayCambiosSinGuardar = false;
      _datosConfirmados = true;
      _calcularTotal();
    });
  }

  void _calcularTotal() {
    _totalVenta = _productosSeleccionados.fold(
      0.0,
      (total, producto) => total + (producto['subtotal'] ?? 0.0),
    );
  }

  void _eliminarProducto(String productoId) {
    setState(() {
      _productosSeleccionados.removeWhere((p) => p['id'] == productoId);
      _cantidadControllers.remove(productoId);
      _precioControllers.remove(productoId);
      _hayCambiosSinGuardar = true;
      _datosConfirmados = false;
      _calcularTotal();
    });
  }

  void _manejarCambioEnProducto() {
    if (!_hayCambiosSinGuardar) {
      setState(() {
        _hayCambiosSinGuardar = true;
        _datosConfirmados = false;
      });
    }
  }

  void _confirmarVenta() {
    if (_productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un producto')),
      );
      return;
    }

    if (_hayCambiosSinGuardar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor actualiza los cambios primero'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleVentaScreen(
          productosSeleccionados: _productosSeleccionados,
          onVentaFinalizada: () {
            setState(() {
              _productosSeleccionados.clear();
              _cantidadControllers.clear();
              _precioControllers.clear();
              _totalVenta = 0.0;
              _datosConfirmados = false;
              _hayCambiosSinGuardar = false;
            });
          },
        ),
      ),
    );
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistorialVentasScreen(),
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.black),
                tooltip: 'Actualizar totales',
                onPressed: () {
                  if (_productosSeleccionados.isNotEmpty) {
                    _actualizarTodosLosProductosSeleccionados();
                  }
                },
              ),
              if (_hayCambiosSinGuardar && _productosSeleccionados.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
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
              style: const TextStyle(color: Colors.yellow),
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
          if (_productosSeleccionados.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Productos: ${_productosSeleccionados.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total: \$${_totalVenta.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
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
                    final productoSeleccionado = _productosSeleccionados
                        .firstWhere(
                          (p) => p['id'] == productoId,
                          orElse: () => {},
                        );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['nombre'] ?? 'Sin nombre',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stock: ${data['cantidad'] ?? 0}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (productoSeleccionado.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _eliminarProducto(productoId),
                                  ),
                              ],
                            ),

                            if (productoSeleccionado.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller:
                                          _cantidadControllers[productoId],
                                      keyboardType: TextInputType.number,
                                      onTap: () {
                                        if (_cantidadControllers[productoId]
                                                ?.text ==
                                            '0') {
                                          _cantidadControllers[productoId]
                                              ?.clear();
                                        }
                                        _cantidadControllers[productoId]
                                            ?.selection = TextSelection.collapsed(
                                          offset:
                                              _cantidadControllers[productoId]!
                                                  .text
                                                  .length,
                                        );
                                      },
                                      onChanged: (value) =>
                                          _manejarCambioEnProducto(),
                                      decoration: const InputDecoration(
                                        labelText: 'Cantidad',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller:
                                          _precioControllers[productoId],
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      onTap: () {
                                        if (_precioControllers[productoId]
                                                    ?.text ==
                                                '0' ||
                                            _precioControllers[productoId]
                                                    ?.text ==
                                                '0.0') {
                                          _precioControllers[productoId]
                                              ?.clear();
                                        }
                                        _precioControllers[productoId]
                                                ?.selection =
                                            TextSelection.collapsed(
                                              offset:
                                                  _precioControllers[productoId]!
                                                      .text
                                                      .length,
                                            );
                                      },
                                      onChanged: (value) =>
                                          _manejarCambioEnProducto(),
                                      decoration: const InputDecoration(
                                        labelText: 'Precio',
                                        prefixText: '\$ ',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (productoSeleccionado['subtotal'] != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Subtotal: \$${(productoSeleccionado['subtotal'] ?? 0).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                            ] else ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text('Agregar'),
                                  onPressed: () => _agregarProducto({
                                    'id': productoId,
                                    'nombre': data['nombre'],
                                    'precio': (data['precio'] ?? 0).toDouble(),
                                    'cantidad': (data['cantidad'] ?? 0).toInt(),
                                  }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.azul,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _datosConfirmados && _productosSeleccionados.isNotEmpty
                ? _confirmarVenta
                : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'Confirmar Venta',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}
