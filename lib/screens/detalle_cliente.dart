import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/agregar_cliente.dart';

class DetalleCliente extends StatelessWidget {
  final String clienteId;
  final Map<String, dynamic> clienteData;

  const DetalleCliente({
    super.key,
    required this.clienteId,
    required this.clienteData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Detalle del Cliente',
          style: TextStyle(color: AppColors.secondary),
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/estrellas.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                buildInfoTile('Nombre', clienteData['nombre']),
                buildInfoTile('Teléfono', clienteData['telefono']),
                buildInfoTile('Correo', clienteData['correo']),
                buildInfoTile('Dirección', clienteData['direccion']),
                buildInfoTile('Notas', clienteData['notas']),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verde,
                        foregroundColor: AppColors.accent,
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AgregarCliente(
                              clienteId: clienteId,
                              clienteData: clienteData,
                            ),
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rojo,
                        foregroundColor: AppColors.secondary,
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Eliminar cliente'),
                            content: const Text(
                              '¿Estás seguro de eliminar este cliente? Esta acción no se puede deshacer.',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancelar'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.rojo,
                                ),
                                child: const Text('Eliminar'),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('clientes')
                              .doc(clienteId)
                              .delete();

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cliente eliminado correctamente',
                                ),
                                backgroundColor: AppColors.rojo,
                              ),
                            );
                          }
                        }
                      },
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

  Widget buildInfoTile(String label, String? value) {
    return Card(
      color: AppColors.accent,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        subtitle: Text(
          value ?? 'No especificado',
          style: const TextStyle(color: AppColors.rojo),
        ),
      ),
    );
  }
}
