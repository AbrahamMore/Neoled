import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pie_chart/pie_chart.dart';

class ResultadoVentas {
  final double total;
  final List<Map<String, dynamic>> detalles;

  ResultadoVentas({required this.total, required this.detalles});
}

class ReportesFinancierosScreen extends StatefulWidget {
  const ReportesFinancierosScreen({super.key});

  @override
  State<ReportesFinancierosScreen> createState() =>
      _ReportesFinancierosScreenState();
}

class _ReportesFinancierosScreenState extends State<ReportesFinancierosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _valorInventario = 0.0;
  double _totalGastos = 0.0;
  double _totalVentas = 0.0;
  bool _loading = true;
  String _tipoReporte = 'mensual';
  int _mesSeleccionado = DateTime.now().month;
  int _anioSeleccionado = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);

    try {
      final ventas = await calcularTotalVentasFiltradas();
      final gastos = await calcularTotalGastosFiltrados();
      final inventario = await calcularValorInventarioFiltrado();

      setState(() {
        _totalVentas = ventas.total;
        _totalGastos = gastos;
        _valorInventario = inventario;
        _loading = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _loading = false);
    }
  }

  Future<ResultadoVentas> calcularTotalVentasFiltradas() async {
    try {
      Query query = _firestore.collection('ventas');

      if (_tipoReporte == 'mensual') {
        final inicioMes = DateTime(_anioSeleccionado, _mesSeleccionado, 1);
        final finMes = DateTime(_anioSeleccionado, _mesSeleccionado + 1, 1);
        query = query
            .where('fecha', isGreaterThanOrEqualTo: inicioMes)
            .where('fecha', isLessThan: finMes);
      } else {
        final inicioAnio = DateTime(_anioSeleccionado, 1, 1);
        final finAnio = DateTime(_anioSeleccionado + 1, 1, 1);
        query = query
            .where('fecha', isGreaterThanOrEqualTo: inicioAnio)
            .where('fecha', isLessThan: finAnio);
      }

      final snapshot = await query.get();
      double total = 0.0;
      List<Map<String, dynamic>> detalles = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ventaTotal = _parseDouble(data['total']);
        total += ventaTotal;
        detalles.add({
          'fecha': data['fecha'],
          'total': ventaTotal,
          'items': data['items'],
        });
      }

      return ResultadoVentas(total: total, detalles: detalles);
    } catch (e) {
      print('Error calculando ventas filtradas: $e');
      return ResultadoVentas(total: 0.0, detalles: []);
    }
  }

  Future<double> calcularTotalGastosFiltrados() async {
    try {
      Query query = _firestore.collection('gastos');

      if (_tipoReporte == 'mensual') {
        final inicioMes = DateTime(_anioSeleccionado, _mesSeleccionado, 1);
        final finMes = DateTime(_anioSeleccionado, _mesSeleccionado + 1, 1);
        query = query
            .where('fecha', isGreaterThanOrEqualTo: inicioMes)
            .where('fecha', isLessThan: finMes);
      } else {
        final inicioAnio = DateTime(_anioSeleccionado, 1, 1);
        final finAnio = DateTime(_anioSeleccionado + 1, 1, 1);
        query = query
            .where('fecha', isGreaterThanOrEqualTo: inicioAnio)
            .where('fecha', isLessThan: finAnio);
      }

      final snapshot = await query.get();
      double total = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += _parseDouble(data['valor']);
      }

      return total;
    } catch (e) {
      print('Error calculando gastos filtrados: $e');
      return 0.0;
    }
  }

  Future<double> calcularValorInventarioFiltrado() async {
    try {
      Query query = _firestore.collection('inventario');
      final snapshot = await query.get();
      double total = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final costo = _parseDouble(data['costo']);
        final cantidad = _parseInt(data['cantidad']);
        total += costo * cantidad;
      }

      return total;
    } catch (e) {
      print('Error calculando inventario filtrado: $e');
      return 0.0;
    }
  }

  double _parseDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildFiltros() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tipo de Reporte
            DropdownButtonFormField<String>(
              value: _tipoReporte,
              items: const [
                DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                DropdownMenuItem(value: 'anual', child: Text('Anual')),
              ],
              onChanged: (value) {
                setState(() => _tipoReporte = value!);
                _cargarDatos();
              },
              decoration: const InputDecoration(
                labelText: 'Tipo de Reporte',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              isExpanded: true,
            ),

            const SizedBox(height: 16),

            // Fila para Mes y Año
            Row(
              children: [
                if (_tipoReporte == 'mensual')
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _mesSeleccionado,
                      items: List.generate(12, (index) => index + 1)
                          .map(
                            (mes) => DropdownMenuItem(
                              value: mes,
                              child: Text(
                                DateFormat('MMMM').format(DateTime(2020, mes)),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _mesSeleccionado = value!);
                        _cargarDatos();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      isExpanded: true,
                    ),
                  ),

                if (_tipoReporte == 'mensual') const SizedBox(width: 16),

                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _anioSeleccionado,
                    items:
                        List.generate(
                              5,
                              (index) => DateTime.now().year - 2 + index,
                            )
                            .map(
                              (anio) => DropdownMenuItem(
                                value: anio,
                                child: Text(anio.toString()),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() => _anioSeleccionado = value!);
                      _cargarDatos();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    isExpanded: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCard(String titulo, double valor, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${valor.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double gananciasBrutas = _totalVentas - _totalGastos;
    final double margenGanancias = _totalVentas > 0
        ? (gananciasBrutas / _totalVentas) * 100
        : 0;

    final Map<String, double> dataMap = {
      'Ventas': _totalVentas,
      'Gastos': _totalGastos,
      'Inventario': _valorInventario,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reporte ${_tipoReporte == 'mensual' ? DateFormat('MMMM yyyy').format(DateTime(_anioSeleccionado, _mesSeleccionado)) : 'Año $_anioSeleccionado'}',
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFiltros(),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildResumenCard(
                        'Ventas Totales',
                        _totalVentas,
                        AppColors.verde,
                      ),
                      _buildResumenCard(
                        'Gastos Totales',
                        _totalGastos,
                        AppColors.rojo,
                      ),
                      _buildResumenCard(
                        'Ganancias',
                        gananciasBrutas,
                        gananciasBrutas >= 0 ? AppColors.verde : AppColors.rojo,
                      ),
                      _buildResumenCard(
                        'Valor Inventario',
                        _valorInventario,
                        AppColors.azul,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PieChart(dataMap: dataMap),
                ],
              ),
            ),
    );
  }
}
