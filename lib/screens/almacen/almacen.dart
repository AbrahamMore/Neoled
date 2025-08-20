import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart'; // Para el selector de fechas

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
  DateTime? _fechaFiltro;
  bool _mostrarResumenDiario = false;

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
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    if (_usuarioSeleccionado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selecciona un usuario'),
          backgroundColor: AppColors.rojo,
        ),
      );
      return;
    }

    for (var productoId in _productosSeleccionados) {
      final producto = _productos.firstWhere((p) => p['id'] == productoId);
      final cantidad = _cantidadesPorProducto[productoId] ?? 1;

      if (cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cantidad inválida para ${producto['nombre']}'),
            backgroundColor: AppColors.rojo,
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
            backgroundColor: AppColors.rojo,
          ),
        );
        return;
      }
    }

    final batch = FirebaseFirestore.instance.batch();
    final ahora = Timestamp.now();

    try {
      for (var productoId in _productosSeleccionados) {
        final producto = _productos.firstWhere((p) => p['id'] == productoId);
        final cantidad = _cantidadesPorProducto[productoId] ?? 1;

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
          backgroundColor: AppColors.verde,
        ),
      );

      setState(() {
        _productosSeleccionados.clear();
        _cantidadesPorProducto.clear();
      });
      _cargarProductos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar: $e'),
          backgroundColor: AppColors.rojo,
        ),
      );
    }
  }

  void _mostrarSelectorFecha() async {
    final DateTime? fechaSeleccionada = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime tempFecha = _fechaFiltro ?? DateTime.now();
        return AlertDialog(
          title: Text('Seleccionar fecha'),
          content: SizedBox(
            width: double.maxFinite,
            child: SfDateRangePicker(
              initialSelectedDate: tempFecha,
              maxDate: DateTime.now(),
              selectionMode: DateRangePickerSelectionMode.single,
              onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                tempFecha = args.value as DateTime;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempFecha),
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaFiltro = fechaSeleccionada;
        _mostrarResumenDiario = true;
      });
    }
  }

  void _limpiarFiltroFecha() {
    setState(() {
      _fechaFiltro = null;
      _mostrarResumenDiario = false;
    });
  }

  Widget _buildResumenDiario(List<QueryDocumentSnapshot> movimientos) {
    // Agrupar movimientos por producto
    Map<String, int> resumen = {};
    int totalPiezas = 0;

    for (var movimiento in movimientos) {
      final data = movimiento.data() as Map<String, dynamic>;
      final nombreProducto = data['producto_nombre'];
      final cantidad = data['cantidad'] as int;

      resumen[nombreProducto] = (resumen[nombreProducto] ?? 0) + cantidad;
      totalPiezas += cantidad;
    }

    // Convertir a lista y ordenar por cantidad (de mayor a menor)
    var items = resumen.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen del ${DateFormat('dd/MM/yyyy').format(_fechaFiltro!)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: _limpiarFiltroFecha,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Total de piezas: $totalPiezas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.rojo,
              fontSize: 19,
            ),
          ),
        ),
        SizedBox(height: 5),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              title: Text(item.key),
              trailing: Text(item.value.toString()),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          _showHistory
              ? _fechaFiltro != null
                    ? 'Historial ${DateFormat('dd/MM').format(_fechaFiltro!)}'
                    : 'Historial de Almacén'
              : 'Registrar Salidas',
          style: TextStyle(color: AppColors.secondary),
        ),
        actions: [
          if (_showHistory)
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: _mostrarSelectorFecha,
            )
          else
            IconButton(
              icon: Icon(Icons.history),
              onPressed: () {
                setState(() {
                  _showHistory = !_showHistory;
                  _fechaFiltro = null;
                  _mostrarResumenDiario = false;
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
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar producto',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.accent,
            ),
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _usuarioSeleccionado.isNotEmpty
                ? _usuarioSeleccionado
                : null,
            decoration: InputDecoration(
              labelText: 'Persona que retira',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.person),
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
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registrarSalidas,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Registrar Salidas',
                style: TextStyle(fontSize: 16, color: AppColors.secondary),
              ),
            ),
          ),
          SizedBox(height: 20),
          if (_productosFiltrados.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _productosFiltrados.length,
              itemBuilder: (context, index) {
                final producto = _productosFiltrados[index];
                final isSelected = _productosSeleccionados.contains(
                  producto['id'],
                );
                final cantidad = _cantidadesPorProducto[producto['id']] ?? 1;

                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _toggleSeleccionProducto(producto['id']),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
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
                                      style: TextStyle(
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
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Cantidad: '),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: cantidad.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
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
          return Center(child: CircularProgressIndicator());
        }

        final todosMovimientos = snapshot.data!.docs;

        // Filtrar por fecha si hay filtro aplicado
        final movimientosFiltrados = _fechaFiltro == null
            ? todosMovimientos
            : todosMovimientos.where((doc) {
                final fechaMovimiento = (doc['fecha'] as Timestamp).toDate();
                return fechaMovimiento.year == _fechaFiltro!.year &&
                    fechaMovimiento.month == _fechaFiltro!.month &&
                    fechaMovimiento.day == _fechaFiltro!.day;
              }).toList();

        if (_mostrarResumenDiario && _fechaFiltro != null) {
          return _buildResumenDiario(movimientosFiltrados);
        }

        if (movimientosFiltrados.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _fechaFiltro == null
                      ? 'No hay movimientos registrados'
                      : 'No hay movimientos para la fecha seleccionada',
                ),
                if (_fechaFiltro != null)
                  TextButton(
                    onPressed: _limpiarFiltroFecha,
                    child: Text('Limpiar filtro'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.0),
          itemCount: movimientosFiltrados.length,
          itemBuilder: (context, index) {
            final movimiento =
                movimientosFiltrados[index].data() as Map<String, dynamic>;
            final fecha = (movimiento['fecha'] as Timestamp).toDate();

            return Card(
              margin: EdgeInsets.only(bottom: 16),
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
              ),
            );
          },
        );
      },
    );
  }
}
