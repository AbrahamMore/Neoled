import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _loadUserData() async {
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final uid = user!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (doc.exists) {
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

        setState(() {
          _editando = false;
          userData?['nombre'] = _nombreController.text.trim();
          userData?['apellidos'] = _apellidosController.text.trim();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar la contraseña: $e')),
        );
      }
    }
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    // No navegamos manualmente, AuthChecker se encargará de mostrar pantalla correcta
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Mi Cuenta', style: TextStyle(color: Colors.white)),
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _editando
                      ? TextField(
                          controller: _nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                          ),
                        )
                      : Text(
                          'Nombre: ${userData!['nombre']}',
                          style: const TextStyle(fontSize: 18),
                        ),
                  const SizedBox(height: 10),
                  _editando
                      ? TextField(
                          controller: _apellidosController,
                          decoration: const InputDecoration(
                            labelText: 'Apellidos',
                          ),
                        )
                      : Text(
                          'Apellidos: ${userData!['apellidos']}',
                          style: const TextStyle(fontSize: 18),
                        ),
                  const SizedBox(height: 10),
                  Text(
                    'Correo: ${user!.email}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(_editando ? Icons.save : Icons.edit),
                        label: Text(_editando ? 'Guardar' : 'Editar'),
                        onPressed: () {
                          if (_editando) {
                            _guardarCambios();
                          } else {
                            setState(() => _editando = true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                        onPressed: _cerrarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock),
                    label: const Text('Cambiar contraseña'),
                    onPressed: _cambiarContrasena,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
