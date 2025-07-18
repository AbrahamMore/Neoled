import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class ClienteSelector extends StatelessWidget {
  final String? clienteNombre;
  final VoidCallback onSeleccionar;
  final VoidCallback onEliminar;

  const ClienteSelector({
    super.key,
    required this.clienteNombre,
    required this.onSeleccionar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person),
            label: Text(
              clienteNombre != null
                  ? 'Cliente: $clienteNombre'
                  : 'Seleccionar cliente',
            ),
            onPressed: onSeleccionar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.secondary,
            ),
          ),
        ),
        if (clienteNombre != null)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onEliminar,
          ),
      ],
    );
  }
}

class FechaSelector extends StatelessWidget {
  final DateTime? fecha;
  final VoidCallback onSeleccionar;

  const FechaSelector({
    super.key,
    required this.fecha,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              fecha != null
                  ? 'Fecha: ${fecha!.day}/${fecha!.month}/${fecha!.year}'
                  : 'Seleccionar fecha',
            ),
            onPressed: onSeleccionar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class ProveedorSelector extends StatelessWidget {
  final String? proveedorSeleccionado;
  final Function(String?) onChanged;

  const ProveedorSelector({
    super.key,
    required this.proveedorSeleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('proveedores').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final proveedores = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: proveedorSeleccionado,
          decoration: InputDecoration(
            labelText: 'Proveedor (opcional)',
            prefixIcon: const Icon(Icons.business),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('Ninguno')),
            ...proveedores.map((proveedor) {
              return DropdownMenuItem<String>(
                value: proveedor.id,
                child: Text(proveedor['nombre'] ?? 'Sin nombre'),
              );
            }).toList(),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class PagoSelector extends StatelessWidget {
  final String? tipoPagoSeleccionado;
  final List<String> tiposPago;
  final Function(String?) onChanged;

  const PagoSelector({
    super.key,
    required this.tipoPagoSeleccionado,
    required this.tiposPago,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: tipoPagoSeleccionado,
      decoration: InputDecoration(
        labelText: 'Tipo de pago',
        prefixIcon: const Icon(Icons.payment),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: tiposPago.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleccione un tipo de pago';
        }
        return null;
      },
    );
  }
}

class ProductoItem extends StatelessWidget {
  final Map<String, dynamic> producto;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onEliminar;

  const ProductoItem({
    super.key,
    required this.producto,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.shopping_cart, color: AppColors.secondary),
        title: Text(producto['nombre']),
        subtitle: Text('Precio: \$${producto['precio'].toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.remove), onPressed: onDecrement),
            Text(producto['cantidadSeleccionada'].toString()),
            IconButton(icon: const Icon(Icons.add), onPressed: onIncrement),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.rojo),
              onPressed: onEliminar,
            ),
          ],
        ),
      ),
    );
  }
}

class TotalPanel extends StatelessWidget {
  final double total;
  final VoidCallback onFinalizar;

  const TotalPanel({super.key, required this.total, required this.onFinalizar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onFinalizar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Finalizar Venta',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
