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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Roles'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados'));
          }

          final currentUserUid = _auth.currentUser?.uid;
          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final isCurrentUser = userData['uid'] == currentUserUid;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('${userData['nombre']} ${userData['apellidos']}'),
                  subtitle: Text(userData['email']),
                  trailing: DropdownButton<String>(
                    value: userData['rol'],
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem<String>(
                        value: role.name,
                        child: Text(role.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: isCurrentUser
                        ? null // No permitir cambiar el propio rol
                        : (newValue) {
                            _updateUserRole(user.id, newValue!);
                          },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({
        'rol': newRole,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rol actualizado a $newRole'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el rol'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Enum de roles (debe estar accesible desde varios archivos)
enum UserRole { admin, gerente, empleado, cliente }
