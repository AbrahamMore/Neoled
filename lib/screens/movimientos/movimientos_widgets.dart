import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class ListaMovimientos extends StatelessWidget {
  final List<DocumentSnapshot> movimientos;
  final bool mostrarTipo;

  const ListaMovimientos({
    super.key,
    required this.movimientos,
    required this.mostrarTipo,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: movimientos.length,
      itemBuilder: (context, index) => MovimientoItem(
        documento: movimientos[index],
        mostrarTipo: mostrarTipo,
      ),
    );
  }
}

class MovimientoItem extends StatelessWidget {
  final DocumentSnapshot documento;
  final bool mostrarTipo;

  const MovimientoItem({
    super.key,
    required this.documento,
    required this.mostrarTipo,
  });

  @override
  Widget build(BuildContext context) {
    final data = documento.data() as Map<String, dynamic>;
    final fecha = (data['fecha'] as Timestamp).toDate();
    final esVenta = documento.reference.path.contains('ventas');
    final total = data['total'] ?? 0.0;
    final colorPrincipal = esVenta ? Colors.green : AppColors.rojo;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colorPrincipal.withOpacity(0.1),
          child: Icon(
            esVenta ? Icons.shopping_cart : Icons.money_off,
            color: colorPrincipal,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            if (mostrarTipo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorPrincipal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  esVenta ? 'VENTA' : 'GASTO',
                  style: TextStyle(
                    color: colorPrincipal,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (mostrarTipo) const SizedBox(width: 8),
            Expanded(
              child: Text(
                esVenta
                    ? data['nombreVenta'] ?? 'Venta sin nombre'
                    : data['descripcion'] ?? 'Gasto',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy - HH:mm').format(fecha),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: TextStyle(
                color: colorPrincipal,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              esVenta ? 'Venta' : 'Gasto',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (esVenta) ...[
                  _buildInfoRow(
                    'Vendedor:',
                    data['usuarioNombre'] ?? 'No especificado',
                  ),
                  if (data['clienteNombre'] != null)
                    _buildInfoRow('Cliente:', data['clienteNombre']),
                ] else ...[
                  _buildInfoRow(
                    'Descripción:',
                    data['descripcion'] ?? 'Sin descripción',
                  ),
                  _buildInfoRow(
                    'Proveedor:',
                    data['proveedorNombre'] ?? 'No especificado',
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Text(
                  'DETALLES:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildItemsList(data['productos'] ?? []),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorPrincipal,
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
  }

  List<Widget> _buildItemsList(List<dynamic> items) {
    if (items.isEmpty) {
      return [const Text('No hay items registrados')];
    }

    return items.map<Widget>((item) {
      final cantidad = item['cantidad'] ?? 0;
      final precio = item['precio'] ?? 0.0;
      final subtotal = cantidad * precio;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                item['nombre'] ?? 'Item sin nombre',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'x$cantidad',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '\$${subtotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
