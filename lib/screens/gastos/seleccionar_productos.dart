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
  double _total = 0.0;
  bool _datosConfirmados = false;
  bool _hayCambiosSinGuardar = false;

  final Map<String, TextEditingController> _cantidadControllers = {};
  final Map<String, TextEditingController> _costoControllers = {};
  final Map<String, FocusNode> _cantidadFocusNodes = {};
  final Map<String, FocusNode> _costoFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _productosSeleccionadosInternos = List.from(widget.productosSeleccionados);
    _inicializarControladores();
    _calcularTotalManual();
    _datosConfirmados = _productosSeleccionadosInternos.isNotEmpty;
  }

  void _inicializarControladores() {
    for (var producto in _productosSeleccionadosInternos) {
      final id = producto['id'];
      _cantidadControllers[id] = TextEditingController(
        text: producto['cantidadComprada'].toString(),
      );
      _costoControllers[id] = TextEditingController(
        text: (producto['costoUnitario'] ?? producto['costo'] ?? 0).toString(),
      );
      _cantidadFocusNodes[id] = FocusNode();
      _costoFocusNodes[id] = FocusNode();
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    for (var controller in _cantidadControllers.values) {
      controller.dispose();
    }
    for (var controller in _costoControllers.values) {
      controller.dispose();
    }
    for (var node in _cantidadFocusNodes.values) {
      node.dispose();
    }
    for (var node in _costoFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _manejarCambioEnProducto() {
    if (!_hayCambiosSinGuardar) {
      setState(() {
        _hayCambiosSinGuardar = true;
        _datosConfirmados = false;
      });
    }
  }

  void _actualizarTodosLosProductosSeleccionados(
    List<DocumentSnapshot> productosDocs,
  ) {
    setState(() {
      for (var productoDoc in productosDocs) {
        final productoId = productoDoc.id;
        final data = productoDoc.data() as Map<String, dynamic>;

        final cantidadText = _cantidadControllers[productoId]?.text ?? '0';
        final costoText = _costoControllers[productoId]?.text ?? '0.0';

        final cantidad = int.tryParse(cantidadText) ?? 0;
        final costo =
            double.tryParse(costoText) ?? data['costo']?.toDouble() ?? 0.0;

        if (cantidad <= 0) {
          _eliminarProducto(productoId);
          continue;
        }

        final productoActualizado = {
          ...data,
          'id': productoId,
          'cantidadComprada': cantidad,
          'costoUnitario': costo,
          'subtotal': cantidad * costo,
        };

        final productoIndex = _productosSeleccionadosInternos.indexWhere(
          (p) => p['id'] == productoId,
        );

        if (productoIndex != -1) {
          _productosSeleccionadosInternos[productoIndex] = productoActualizado;
        } else {
          _productosSeleccionadosInternos.add(productoActualizado);
        }
      }

      _hayCambiosSinGuardar = false;
      _datosConfirmados = true;
      _calcularTotalManual();
      widget.onProductosSeleccionados(_productosSeleccionadosInternos);
    });
  }

  void _calcularTotalManual() {
    _total = _productosSeleccionadosInternos.fold(
      0.0,
      (total, producto) => total + (producto['subtotal'] ?? 0.0),
    );
  }

  void _eliminarProducto(String productoId) {
    final productoEliminado = _productosSeleccionadosInternos.firstWhere(
      (p) => p['id'] == productoId,
      orElse: () => {},
    );

    setState(() {
      _productosSeleccionadosInternos.removeWhere(
        (producto) => producto['id'] == productoId,
      );

      _cantidadControllers[productoId]?.text = '0';

      if (productoEliminado.isNotEmpty) {
        _costoControllers[productoId]?.text =
            (productoEliminado['costo'] ??
                    productoEliminado['costoUnitario'] ??
                    '0')
                .toString();
      } else {
        _costoControllers[productoId]?.text =
            _costoControllers[productoId]?.text ?? '0';
      }

      _hayCambiosSinGuardar = true;
      _datosConfirmados = false;
      _calcularTotalManual();
      widget.onProductosSeleccionados(_productosSeleccionadosInternos);
    });
  }

  void _guardarSeleccion() {
    if (_productosSeleccionadosInternos.isEmpty) {
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

    _cantidadControllers.putIfAbsent(
      productoId,
      () => TextEditingController(
        text: productoSeleccionado.isNotEmpty
            ? productoSeleccionado['cantidadComprada'].toString()
            : '0',
      ),
    );

    _costoControllers.putIfAbsent(
      productoId,
      () => TextEditingController(
        text: productoSeleccionado.isNotEmpty
            ? productoSeleccionado['costoUnitario'].toString()
            : data['costo']?.toString() ?? '0.0',
      ),
    );

    _cantidadFocusNodes.putIfAbsent(productoId, () => FocusNode());
    _costoFocusNodes.putIfAbsent(productoId, () => FocusNode());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (productoSeleccionado.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarProducto(productoId),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _cantidadControllers[productoId],
                    focusNode: _cantidadFocusNodes[productoId],
                    keyboardType: TextInputType.number,
                    onTap: () {
                      if (_cantidadControllers[productoId]?.text == '0') {
                        _cantidadControllers[productoId]?.clear();
                      }
                      _cantidadControllers[productoId]?.selection =
                          TextSelection(
                            baseOffset: 0,
                            extentOffset:
                                _cantidadControllers[productoId]!.text.length,
                          );
                    },
                    onChanged: (value) => _manejarCambioEnProducto(),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _costoControllers[productoId],
                    focusNode: _costoFocusNodes[productoId],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onTap: () {
                      if (_costoControllers[productoId]?.text == '0' ||
                          _costoControllers[productoId]?.text == '0.0') {
                        _costoControllers[productoId]?.clear();
                      }
                      _costoControllers[productoId]?.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset:
                            _costoControllers[productoId]!.text.length,
                      );
                    },
                    onChanged: (value) => _manejarCambioEnProducto(),
                    decoration: const InputDecoration(
                      labelText: 'Costo unitario',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (productoSeleccionado.isNotEmpty &&
                productoSeleccionado['subtotal'] != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal: \$${productoSeleccionado['subtotal'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Seleccionar Productos'),
            if (_hayCambiosSinGuardar &&
                _productosSeleccionadosInternos.isNotEmpty)
              const Padding(padding: EdgeInsets.only(left: 8.0)),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.black),
                tooltip: 'Actualizar totales',
                onPressed: () {
                  _firestore.collection('inventario').get().then((snapshot) {
                    _actualizarTodosLosProductosSeleccionados(snapshot.docs);
                  });
                },
              ),
              if (_hayCambiosSinGuardar &&
                  _productosSeleccionadosInternos.isNotEmpty)
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
            padding: const EdgeInsets.all(12.0),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _busqueda = value.toLowerCase();
                });
              },
            ),
          ),
          if (_productosSeleccionadosInternos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Productos seleccionados: ${_productosSeleccionadosInternos.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total: \$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: productos.length,
                  itemBuilder: (context, index) =>
                      _buildProductoItem(productos[index]),
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
            onPressed:
                _datosConfirmados && _productosSeleccionadosInternos.isNotEmpty
                ? _guardarSeleccion
                : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar', style: TextStyle(fontSize: 16)),
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
