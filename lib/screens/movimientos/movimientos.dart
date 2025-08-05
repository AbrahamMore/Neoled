import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/movimientos/movimientos_widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _fechaSeleccionada;

  final List<String> _tabs = ['Todos', 'Ventas', 'Gastos'];
  int _currentIndex = 0;

  late PageController _pageController;

  // Cache de streams para evitar recargas
  late final List<Stream<List<DocumentSnapshot>>> _streams;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    _streams = List.generate(
      _tabs.length,
      (index) => _getStreamForIndex(index).shareReplay(),
    );
  }

  Stream<List<DocumentSnapshot>> _getStreamForIndex(int index) {
    Query ventasQuery = _firestore
        .collection('ventas')
        .orderBy('fecha', descending: true);
    Query gastosQuery = _firestore
        .collection('gastos')
        .orderBy('fecha', descending: true);

    Query applyDateFilter(Query query) {
      if (_fechaSeleccionada == null) return query;

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
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fecha', isLessThan: Timestamp.fromDate(finDia));
    }

    if (index == 1) {
      // Ventas
      return applyDateFilter(ventasQuery).snapshots().map((snap) => snap.docs);
    } else if (index == 2) {
      // Gastos
      return applyDateFilter(gastosQuery).snapshots().map((snap) => snap.docs);
    } else {
      // Todos
      final ventasStream = applyDateFilter(
        ventasQuery,
      ).snapshots().map((s) => s.docs);
      final gastosStream = applyDateFilter(
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

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
        // Actualizar streams con nueva fecha
        for (int i = 0; i < _tabs.length; i++) {
          _streams[i] = _getStreamForIndex(i).shareReplay();
        }
      });
    }
  }

  void _clearFechaFiltro() {
    setState(() {
      _fechaSeleccionada = null;
      for (int i = 0; i < _tabs.length; i++) {
        _streams[i] = _getStreamForIndex(i).shareReplay();
      }
    });
  }

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildTab(int index) {
    bool selected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[600],
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
              child: Text(_tabs[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovimientosList(int index) {
    return StreamBuilder<List<DocumentSnapshot>>(
      stream: _streams[index],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 50, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _fechaSeleccionada == null
                      ? 'No hay movimientos registrados'
                      : 'No hay movimientos en la fecha seleccionada',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListaMovimientos(
          movimientos: snapshot.data!,
          mostrarTipo: index == 0,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Movimientos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _seleccionarFecha(context),
            tooltip: 'Filtrar por fecha',
          ),
          if (_fechaSeleccionada != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFechaFiltro,
              tooltip: 'Limpiar filtro',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: List.generate(
                _tabs.length,
                (index) => _buildTab(index),
              ),
            ),
          ),
          if (_fechaSeleccionada != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    label: Text(
                      'Mostrando: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _tabs.length,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (_, index) => _buildMovimientosList(index),
            ),
          ),
        ],
      ),
    );
  }
}
