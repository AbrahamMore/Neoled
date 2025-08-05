import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:intl/intl.dart';

class HistorialGastosScreen extends StatelessWidget {
  const HistorialGastosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Gastos'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gastos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay gastos registrados'));
          }

          final gastos = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gastos.length,
            itemBuilder: (context, index) {
              final data = gastos[index].data();
              if (data is! Map<String, dynamic>) {
                return const SizedBox.shrink(); // Datos corruptos
              }

              final nombre = data['nombre'] is String
                  ? data['nombre']
                  : 'Gasto sin nombre';
              final categoria = data['categoria'] is String
                  ? (data['categoria'] == 'Compra de productos e insumos'
                        ? 'Productos/Insumos'
                        : data['categoria'])
                  : 'Sin categoría';
              final tipoPago = data['tipoPago'] is String
                  ? data['tipoPago']
                  : 'Desconocido';
              final usuarioNombre = data['usuarioNombre'] is String
                  ? data['usuarioNombre']
                  : 'Usuario desconocido';

              final valor = data['valor'];
              final valorFormateado = valor is num
                  ? valor.toStringAsFixed(2)
                  : '0.00';

              // Fecha
              DateTime fecha = DateTime.now();
              String fechaFormateada = '';
              String horaFormateada = '';

              if (data['fecha'] is Timestamp) {
                fecha = (data['fecha'] as Timestamp).toDate();
                fechaFormateada = DateFormat('dd/MM/yyyy').format(fecha);
                horaFormateada = DateFormat('HH:mm').format(fecha);
              }

              // Productos
              final productos = data['productos'];
              final tieneProductos = productos is List && productos.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila 1: nombre y fecha/hora
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(fechaFormateada),
                              Text(
                                horaFormateada,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Fila 2: detalles del gasto
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Categoría: $categoria'),
                              Text('Método: $tipoPago'),
                              Text(
                                'Registrado por: $usuarioNombre',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '\$$valorFormateado',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      // Fila 3: productos (si hay)
                      if (tieneProductos)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Text(
                              'Productos:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...(productos as List).map((producto) {
                              if (producto is! Map)
                                return const SizedBox.shrink();
                              final nombreProducto =
                                  producto['nombre'] ?? 'Sin nombre';
                              final cantidad =
                                  producto['cantidadSeleccionada'] ?? 1;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('- $nombreProducto (x$cantidad)'),
                              );
                            }).toList(),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
