// ... (tus imports siguen igual)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class CuentaScreen extends StatefulWidget {
  const CuentaScreen({super.key});

  @override
  _CuentaScreenState createState() => _CuentaScreenState();
}

class _CuentaScreenState extends State<CuentaScreen> {
  User? user;
  Map<String, dynamic>? userData;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();

  bool _editando = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      // ✅ Solución: Se agregó la verificación de `mounted`
      if (doc.exists && mounted) {
        setState(() {
          userData = doc.data();
          _nombreController.text = userData?['nombre'] ?? '';
          _apellidosController.text = userData?['apellidos'] ?? '';
        });
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (user != null) {
      final uid = user!.uid;

      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .update({
              'nombre': _nombreController.text.trim(),
              'apellidos': _apellidosController.text.trim(),
            });

        // ✅ Solución: Se agregó la verificación de `mounted`
        if (mounted) {
          setState(() {
            _editando = false;
            userData?['nombre'] = _nombreController.text.trim();
            userData?['apellidos'] = _apellidosController.text.trim();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos actualizados correctamente')),
          );
        }
      } catch (e) {
        // ✅ Solución: Se agregó la verificación de `mounted`
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
        }
      }
    }
  }

  Future<void> _cambiarContrasena() async {
    final nueva = TextEditingController();
    final confirmar = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nueva,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            ),
            TextField(
              controller: confirmar,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () {
              if (nueva.text == confirmar.text && nueva.text.length >= 6) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Las contraseñas no coinciden o son muy cortas (mínimo 6 caracteres)',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );

    if (resultado == true) {
      try {
        await user!.updatePassword(nueva.text.trim());
        // ✅ Solución: Se agregó la verificación de `mounted`
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña actualizada')),
          );
        }
      } catch (e) {
        // ✅ Solución: Se agregó la verificación de `mounted`
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cambiar la contraseña: $e')),
          );
        }
      }
    }
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  Widget _buildCampo(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.accent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.secondary),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: const Text(
          'Mi Cuenta',
          style: TextStyle(color: AppColors.secondary),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/grapa.png', fit: BoxFit.cover),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // Ícono de usuario centrado
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: AppColors.accent,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 30),

                        _buildCampo(
                          'Nombre',
                          _nombreController,
                          Icons.person,
                          enabled: _editando,
                        ),
                        const SizedBox(height: 16),
                        _buildCampo(
                          'Apellidos',
                          _apellidosController,
                          Icons.person_2,
                          enabled: _editando,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  user?.email ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Botón Guardar/Editar
                        FractionallySizedBox(
                          widthFactor: 0.66,
                          child: ElevatedButton.icon(
                            onPressed: _editando
                                ? _guardarCambios
                                : () {
                                    setState(() => _editando = true);
                                  },
                            icon: Icon(_editando ? Icons.save : Icons.edit),
                            label: Text(
                              _editando ? 'Guardar Cambios' : 'Editar',
                              style: const TextStyle(
                                color: AppColors.secondary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Botón Cambiar Contraseña
                        FractionallySizedBox(
                          widthFactor: 0.66,
                          child: ElevatedButton.icon(
                            onPressed: _cambiarContrasena,
                            icon: const Icon(
                              Icons.lock,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              'Cambiar contraseña',
                              style: TextStyle(color: AppColors.primary),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 90),

                        // Botón Cerrar Sesión
                        FractionallySizedBox(
                          widthFactor: 0.66,
                          child: ElevatedButton.icon(
                            onPressed: _cerrarSesion,
                            icon: const Icon(
                              Icons.logout,
                              color: AppColors.accent,
                            ),
                            label: const Text(
                              'Cerrar sesión',
                              style: TextStyle(color: AppColors.accent),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.rojo,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
