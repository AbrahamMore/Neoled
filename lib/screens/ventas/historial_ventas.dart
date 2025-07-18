import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
              final esVentaLibre = data['esVentaLibre'] ?? false;

              // Datos comunes
              final nombreVenta = esVentaLibre
                  ? data['nombre'] ?? 'Venta libre sin nombre'
                  : data['nombreVenta'] ?? 'Venta sin nombre';
              final clienteNombre = data['clienteNombre'];
              final proveedorId = data['proveedorId'];
              final tipoPago = data['tipoPago'] ?? 'No especificado';
              final total = esVentaLibre
                  ? data['valor'] ?? 0.0
                  : data['total'] ?? 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  leading: Icon(
                    esVentaLibre ? Icons.receipt_long : Icons.inventory,
                    color: AppColors.primary,
                  ),
                  title: Text(nombreVenta),
                  subtitle: Text(
                    '${fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(fecha) : 'Fecha desconocida'} - ${tipoPago.toUpperCase()}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tipo de venta
                          _buildInfoRow(
                            'Tipo de venta:',
                            esVentaLibre
                                ? 'Venta Libre'
                                : 'Venta con Inventario',
                            isImportant: true,
                          ),

                          // Información básica de la venta
                          _buildInfoRow(
                            'Vendedor:',
                            data['usuarioNombre'] ?? 'No especificado',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Tipo de pago:',
                            tipoPago,
                            isImportant: true,
                          ),

                          // Cliente si existe
                          if (clienteNombre != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow('Cliente:', clienteNombre),
                          ],

                          // Proveedor si existe
                          if (proveedorId != null) ...[
                            const SizedBox(height: 8),
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('proveedores')
                                  .doc(proveedorId)
                                  .get(),
                              builder: (context, proveedorSnapshot) {
                                if (proveedorSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return _buildInfoRow(
                                    'Proveedor:',
                                    'Cargando...',
                                  );
                                }
                                if (!proveedorSnapshot.hasData) {
                                  return _buildInfoRow(
                                    'Proveedor:',
                                    'No encontrado',
                                  );
                                }
                                final proveedorData =
                                    proveedorSnapshot.data!.data()
                                        as Map<String, dynamic>?;
                                return _buildInfoRow(
                                  'Proveedor:',
                                  proveedorData?['nombre'] ?? 'Sin nombre',
                                );
                              },
                            ),
                          ],

                          // Lista de productos (solo para ventas con inventario)
                          if (!esVentaLibre && data['productos'] != null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'PRODUCTOS:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.rojo,
                              ),
                            ),
                            const Divider(),
                            ...(data['productos'] as List).map((producto) {
                              final cantidad = producto['cantidad'] ?? 0;
                              final precio = producto['precio'] ?? 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${producto['nombre'] ?? 'Producto sin nombre'} x $cantidad',
                                      ),
                                    ),
                                    Text(
                                      '\$${(precio * cantidad).toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],

                          // Descripción para venta libre
                          if (esVentaLibre) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'DESCRIPCIÓN:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.rojo,
                              ),
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(data['nombre'] ?? 'Sin descripción'),
                            ),
                          ],

                          // Total
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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

  Widget _buildInfoRow(String label, String value, {bool isImportant = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
