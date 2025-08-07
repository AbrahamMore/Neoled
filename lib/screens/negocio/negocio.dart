import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:pasos_flutter/screens/negocio/reportes.dart';

class NegocioScreen extends StatefulWidget {
  const NegocioScreen({super.key});

  @override
  State<NegocioScreen> createState() => _NegocioScreenState();
}

class _NegocioScreenState extends State<NegocioScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _valorInventario = 0.0;
  double _totalGastos = 0.0;
  double _totalVentas = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);

    try {
      final inventario = await calcularValorInventario();
      final gastos = await calcularTotalGastos();
      final ventas = await calcularTotalVentas();

      setState(() {
        _valorInventario = inventario;
        _totalGastos = gastos;
        _totalVentas = ventas;
        _loading = false;
      });
    } catch (e) {
      print('Error cargando datos: \$e');
      setState(() => _loading = false);
    }
  }

  Future<double> calcularValorInventario() async {
    try {
      final snapshot = await _firestore.collection('inventario').get();
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final costo = _parseDouble(data['costo']);
        final cantidad = _parseInt(data['cantidad']);
        total += costo * cantidad;
      }
      return total;
    } catch (e) {
      print('Error calculando inventario: \$e');
      return 0.0;
    }
  }

  Future<double> calcularTotalGastos() async {
    try {
      final snapshot = await _firestore.collection('gastos').get();
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += _parseDouble(data['valor']);
      }
      return total;
    } catch (e) {
      print('Error calculando gastos: \$e');
      return 0.0;
    }
  }

  Future<double> calcularTotalVentas() async {
    try {
      final snapshot = await _firestore.collection('ventas').get();
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        total += _parseDouble(data['total']);
      }
      return total;
    } catch (e) {
      print('Error calculando ventas: \$e');
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

  Widget _buildIndicadorFinanciero(
    String titulo,
    double valor,
    Color color, {
    bool esPorcentaje = false,
  }) {
    return ListTile(
      title: Text(titulo),
      trailing: Text(
        esPorcentaje
            ? '${valor.toStringAsFixed(2)}%'
            : '\$${valor.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 16,
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
    final double retornoInventario = _valorInventario > 0
        ? (_totalVentas / _valorInventario) * 100
        : 0;
    final double relacionGastosVentas = _totalVentas > 0
        ? (_totalGastos / _totalVentas) * 100
        : 0;

    final Map<String, double> dataMap = {
      'Ventas': _totalVentas,
      'Gastos': _totalGastos,
      'Inventario': _valorInventario,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte Financiero'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportesFinancierosScreen(),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Resumen Financiero',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildResumenCard(
                        'Inventario',
                        _valorInventario,
                        Colors.blue,
                      ),
                      _buildResumenCard(
                        'Ventas Totales',
                        _totalVentas,
                        Colors.green,
                      ),
                      _buildResumenCard(
                        'Gastos Totales',
                        _totalGastos,
                        Colors.red,
                      ),
                      _buildResumenCard(
                        'Ganancias',
                        gananciasBrutas,
                        gananciasBrutas >= 0 ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Indicadores Financieros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        _buildIndicadorFinanciero(
                          'Margen de ganancias',
                          margenGanancias,
                          margenGanancias >= 0 ? Colors.green : Colors.red,
                          esPorcentaje: true,
                        ),
                        _buildIndicadorFinanciero(
                          'Retorno sobre inventario',
                          retornoInventario,
                          Colors.blue,
                          esPorcentaje: true,
                        ),
                        _buildIndicadorFinanciero(
                          'Relación gastos/ventas',
                          relacionGastosVentas,
                          Colors.orange,
                          esPorcentaje: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            margenGanancias >= 0
                                ? 'La empresa está generando ganancias'
                                : 'La empresa está operando con pérdidas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: margenGanancias >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Distribución Financiera',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          PieChart(dataMap: dataMap),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
