import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class HistorialVentasScreen extends StatelessWidget {
  const HistorialVentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Historial de Ventas'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ventas')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay ventas registradas'));
          }

          final ventas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];
              final data = venta.data() as Map<String, dynamic>;
              final fecha = (data['fecha'] as Timestamp?)?.toDate();
              final nombreVenta = data['nombreVenta'] ?? 'Venta sin nombre';
              final clienteNombre = data['clienteNombre'];
              final total = data['total'] ?? 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  leading: const Icon(Icons.receipt, color: AppColors.primary),
                  title: Text(nombreVenta),
                  subtitle: Text(
                    '${fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) : 'Fecha desconocida'} - Total: \$${total.toStringAsFixed(2)}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vendedor: ${data['usuarioNombre'] ?? 'No especificado'}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (clienteNombre != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Cliente: $clienteNombre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            'Productos:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...(data['productos'] as List).map((producto) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${producto['nombre'] ?? 'Producto sin nombre'} x ${producto['cantidad'] ?? 0}',
                                    ),
                                  ),
                                  Text(
                                    '\$${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
