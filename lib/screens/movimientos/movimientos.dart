import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/movimientos/movimientos_widgets.dart';
import 'package:rxdart/rxdart.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filtroSeleccionado = 'todos'; // 'dia', 'mes', 'año', 'todos'
  DateTime? _fechaSeleccionada;
  final List<String> _tiposMovimiento = ['todos', 'ventas', 'gastos'];
  String _tipoSeleccionado = 'todos';

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Stream<List<DocumentSnapshot>> _obtenerMovimientos() {
    Query ventasQuery = _firestore
        .collection('ventas')
        .orderBy('fecha', descending: true);
    Query gastosQuery = _firestore
        .collection('gastos')
        .orderBy('fecha', descending: true);

    if (_tipoSeleccionado == 'ventas') {
      return _aplicarFiltrosTemporales(
        ventasQuery,
      ).snapshots().map((snap) => snap.docs);
    } else if (_tipoSeleccionado == 'gastos') {
      return _aplicarFiltrosTemporales(
        gastosQuery,
      ).snapshots().map((snap) => snap.docs);
    } else {
      final ventasStream = _aplicarFiltrosTemporales(
        ventasQuery,
      ).snapshots().map((s) => s.docs);
      final gastosStream = _aplicarFiltrosTemporales(
        gastosQuery,
      ).snapshots().map((s) => s.docs);

      return CombineLatestStream.combine2<
        List<DocumentSnapshot>,
        List<DocumentSnapshot>,
        List<DocumentSnapshot>
      >(ventasStream, gastosStream, (ventas, gastos) {
        final combined = [...ventas, ...gastos];
        combined.sort((a, b) {
          final aFecha =
              (a.data() as Map<String, dynamic>)['fecha'] as Timestamp;
          final bFecha =
              (b.data() as Map<String, dynamic>)['fecha'] as Timestamp;
          return bFecha.compareTo(aFecha);
        });
        return combined;
      });
    }
  }

  Query _aplicarFiltrosTemporales(Query query) {
    if (_fechaSeleccionada == null) return query;

    switch (_filtroSeleccionado) {
      case 'dia':
        final inicioDia = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month,
          _fechaSeleccionada!.day,
        );
        final finDia = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month,
          _fechaSeleccionada!.day + 1,
        );
        return query
            .where(
              'fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia),
            )
            .where('fecha', isLessThan: Timestamp.fromDate(finDia));
      case 'mes':
        final inicioMes = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month,
          1,
        );
        final finMes = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month + 1,
          1,
        );
        return query
            .where(
              'fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes),
            )
            .where('fecha', isLessThan: Timestamp.fromDate(finMes));
      case 'año':
        final inicioAno = DateTime(_fechaSeleccionada!.year, 1, 1);
        final finAno = DateTime(_fechaSeleccionada!.year + 1, 1, 1);
        return query
            .where(
              'fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(inicioAno),
            )
            .where('fecha', isLessThan: Timestamp.fromDate(finAno));
      default:
        return query;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Movimientos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          FiltrosMovimientos(
            filtroSeleccionado: _filtroSeleccionado,
            tipoSeleccionado: _tipoSeleccionado,
            tiposMovimiento: _tiposMovimiento,
            fechaSeleccionada: _fechaSeleccionada,
            onFiltroChanged: (value) {
              setState(() {
                _filtroSeleccionado = value;
                if (_filtroSeleccionado == 'todos') {
                  _fechaSeleccionada = null;
                }
              });
            },
            onTipoChanged: (value) {
              setState(() {
                _tipoSeleccionado = value;
              });
            },
            onFechaSeleccionada: () => _seleccionarFecha(context),
            onClearFecha: () {
              setState(() {
                _fechaSeleccionada = null;
              });
            },
          ),
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _obtenerMovimientos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No hay movimientos registrados'),
                  );
                }

                return ListaMovimientos(movimientos: snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }
}
