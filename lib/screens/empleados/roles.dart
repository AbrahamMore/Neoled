import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, List<String>> _permisos = {};
  final Map<String, bool> _modoEdicion = {};

  final List<String> etiquetasDisponibles = [
    'Clientes',
    'Proveedores',
    'Empleados',
    'Inventario',
    'Ventas',
    'Gastos',
    'Negocio',
    'Almacen',
  ];

  @override
  void initState() {
    super.initState();
    _verificarPrimerUsuario();
  }

  Future<void> _verificarPrimerUsuario() async {
    final empleadosSnapshot = await _firestore.collection('usuarios').get();
    if (empleadosSnapshot.docs.length == 1) {
      final doc = empleadosSnapshot.docs.first;
      if (doc['rol'] != 'admin') {
        await _firestore.collection('usuarios').doc(doc.id).update({
          'rol': 'admin',
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _obtenerEmpleados() async {
    final snapshot = await _firestore.collection('usuarios').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> _guardarPermisos(String uid) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'permisos': _permisos[uid] ?? [],
      });

      setState(() {
        _modoEdicion[uid] = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permisos actualizados')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    }
  }

  void _togglePermiso(String uid, String etiqueta) {
    if (!(_modoEdicion[uid] ?? false)) return;

    setState(() {
      _permisos[uid] ??= [];
      if (_permisos[uid]!.contains(etiqueta)) {
        _permisos[uid]!.remove(etiqueta);
      } else {
        _permisos[uid]!.add(etiqueta);
      }
    });
  }

  Future<void> _transferirRolAdmin(String nuevoAdminUid) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null || adminUid == nuevoAdminUid) return;

    try {
      // Usar batch para asegurar ambas operaciones
      final batch = _firestore.batch();

      // Quitar rol de admin actual
      batch.update(_firestore.collection('usuarios').doc(adminUid), {
        'rol': 'empleado',
        'permisos':
            FieldValue.delete(), // Opcional: limpiar permisos del ex-admin
      });

      // Asignar nuevo admin
      batch.update(_firestore.collection('usuarios').doc(nuevoAdminUid), {
        'rol': 'admin',
        'permisos':
            etiquetasDisponibles, // Dar todos los permisos al nuevo admin
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rol de administrador transferido exitosamente'),
        ),
      );

      // Actualizar la UI
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al transferir rol: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles y Permisos'),
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerEmpleados(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay empleados registrados.'));
          }

          final empleados = snapshot.data!;

          return ListView.builder(
            itemCount: empleados.length,
            itemBuilder: (context, index) {
              final empleado = empleados[index];
              final uid = empleado['uid'] as String;
              final nombre = empleado['nombre'] as String? ?? 'Sin nombre';
              final rol = empleado['rol'] as String? ?? 'empleado';
              final permisosActuales =
                  (empleado['permisos'] as List<dynamic>?)?.cast<String>() ??
                  [];

              // Inicializar estados para este usuario
              _modoEdicion.putIfAbsent(uid, () => false);
              _permisos.putIfAbsent(uid, () => List.from(permisosActuales));

              return _EmpleadoItem(
                key: ValueKey(uid),
                nombre: nombre,
                rol: rol,
                uid: uid,
                modoEdicion: _modoEdicion[uid]!,
                permisos: _permisos[uid]!,
                etiquetasDisponibles: etiquetasDisponibles,
                onEditPressed: () {
                  setState(() {
                    _modoEdicion[uid] = true;
                    _permisos[uid] = List.from(permisosActuales);
                  });
                },
                onSavePressed: () => _guardarPermisos(uid),
                onCancelPressed: () {
                  setState(() {
                    _modoEdicion[uid] = false;
                    _permisos[uid] = List.from(permisosActuales);
                  });
                },
                onTransferAdmin: () => _transferirRolAdmin(uid),
                onTogglePermiso: _togglePermiso,
              );
            },
          );
        },
      ),
    );
  }
}

class _EmpleadoItem extends StatelessWidget {
  final String nombre;
  final String rol;
  final String uid;
  final bool modoEdicion;
  final List<String> permisos;
  final List<String> etiquetasDisponibles;
  final VoidCallback onEditPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onCancelPressed;
  final VoidCallback onTransferAdmin;
  final Function(String, String) onTogglePermiso;

  const _EmpleadoItem({
    required Key key,
    required this.nombre,
    required this.rol,
    required this.uid,
    required this.modoEdicion,
    required this.permisos,
    required this.etiquetasDisponibles,
    required this.onEditPressed,
    required this.onSavePressed,
    required this.onCancelPressed,
    required this.onTransferAdmin,
    required this.onTogglePermiso,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$nombre - $rol',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (!modoEdicion) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black),
                    onPressed: onEditPressed,
                  ),
                  if (rol != 'admin')
                    IconButton(
                      icon: const Icon(Icons.shield, color: Colors.black),
                      tooltip: 'Transferir rol de admin',
                      onPressed: onTransferAdmin,
                    ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: etiquetasDisponibles.map((etiqueta) {
                return FilterChip(
                  label: Text(etiqueta),
                  selected: permisos.contains(etiqueta),
                  onSelected: modoEdicion
                      ? (_) => onTogglePermiso(uid, etiqueta)
                      : null,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            if (modoEdicion) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancelPressed,
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onSavePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
