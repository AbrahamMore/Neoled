import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class FiltrosMovimientos extends StatelessWidget {
  final String filtroSeleccionado;
  final String tipoSeleccionado;
  final List<String> tiposMovimiento;
  final DateTime? fechaSeleccionada;
  final Function(String) onFiltroChanged;
  final Function(String) onTipoChanged;
  final VoidCallback onFechaSeleccionada;
  final VoidCallback onClearFecha;

  const FiltrosMovimientos({
    super.key,
    required this.filtroSeleccionado,
    required this.tipoSeleccionado,
    required this.tiposMovimiento,
    required this.fechaSeleccionada,
    required this.onFiltroChanged,
    required this.onTipoChanged,
    required this.onFechaSeleccionada,
    required this.onClearFecha,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('Filtrar por:'),
                DropdownButton<String>(
                  value: filtroSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'dia', child: Text('Día')),
                    DropdownMenuItem(value: 'mes', child: Text('Mes')),
                    DropdownMenuItem(value: 'año', child: Text('Año')),
                  ],
                  onChanged: (value) => onFiltroChanged(value!),
                ),
                DropdownButton<String>(
                  value: tipoSeleccionado,
                  items: tiposMovimiento
                      .map(
                        (tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo.capitalize()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => onTipoChanged(value!),
                ),
              ],
            ),
            if (filtroSeleccionado != 'todos')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: onFechaSeleccionada,
                    child: Text(
                      fechaSeleccionada == null
                          ? 'Seleccionar fecha'
                          : DateFormat('dd/MM/yyyy').format(fechaSeleccionada!),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  if (fechaSeleccionada != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClearFecha,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class ListaMovimientos extends StatelessWidget {
  final List<DocumentSnapshot> movimientos;

  const ListaMovimientos({super.key, required this.movimientos});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: movimientos.length,
      itemBuilder: (context, index) =>
          MovimientoItem(documento: movimientos[index]),
    );
  }
}

class MovimientoItem extends StatelessWidget {
  final DocumentSnapshot documento;

  const MovimientoItem({super.key, required this.documento});

  @override
  Widget build(BuildContext context) {
    final data = documento.data() as Map<String, dynamic>;
    final fecha = (data['fecha'] as Timestamp).toDate();
    final esVenta = documento.reference.path.contains('ventas');
    final total = data['total'] ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          esVenta ? Icons.shopping_cart : Icons.money_off,
          color: esVenta ? Colors.green : Colors.red,
        ),
        title: Text(
          esVenta ? data['nombreVenta'] ?? 'Venta sin nombre' : 'Gasto',
          style: TextStyle(color: esVenta ? Colors.green : Colors.red),
        ),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy HH:mm').format(fecha)} - Total: \$${total.toStringAsFixed(2)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (esVenta) ...[
                  Text(
                    'Vendedor: ${data['usuarioNombre'] ?? 'No especificado'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (data['clienteNombre'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cliente: ${data['clienteNombre']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ] else ...[
                  Text(
                    'Descripción: ${data['descripcion'] ?? 'Sin descripción'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Proveedor: ${data['proveedorNombre'] ?? 'No especificado'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  esVenta ? 'Productos:' : 'Items:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(data['productos'] as List?)?.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item['nombre'] ?? 'Item sin nombre'} x ${item['cantidad'] ?? 0}',
                              ),
                            ),
                            Text(
                              '\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      );
                    }) ??
                    [const Text('No hay items registrados')],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: esVenta ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: esVenta ? Colors.green : Colors.red,
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
