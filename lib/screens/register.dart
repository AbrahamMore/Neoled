import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/components/auth_exception_handler.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passController.text.trim();
      final nombre = nameController.text.trim();
      final apellidos = lastNameController.text.trim();

      // Crear usuario
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user!;

      await user.updateDisplayName('$nombre $apellidos');
      await user.sendEmailVerification();

      // Obtener número de usuarios existentes
      final usuarios = await FirebaseFirestore.instance
          .collection('usuarios')
          .get();

      final esPrimerUsuario = usuarios.docs.isEmpty;

      // Guardar datos en Firestore con merge para evitar duplicados
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'nombre': nombre,
            'apellidos': apellidos,
            'email': email,
            'rol': esPrimerUsuario ? 'admin' : 'empleado',
            'fechaRegistro': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Si es el primer usuario, crea también el doc /config/admin
      if (esPrimerUsuario) {
        await FirebaseFirestore.instance.collection('config').doc('admin').set({
          'adminPrincipal': user.uid,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Verifica tu correo electrónico.'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar campos
      nameController.clear();
      lastNameController.clear();
      emailController.clear();
      passController.clear();
      confirmPassController.clear();

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'email-already-in-use') {
        // El usuario ya está registrado
        final userMethods = FirebaseAuth.instance;
        final signInMethods = await userMethods.fetchSignInMethodsForEmail(
          emailController.text.trim(),
        );

        if (signInMethods.contains('password')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Este correo ya está registrado. Inicia sesión o verifica tu email.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Correo ya en uso con otro método de autenticación.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        AuthExceptionHandler.showSnackbar(context, e.code);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: Image.asset(
                'assets/images/carga.png',
                fit: BoxFit.cover,
                height: screenHeight * 0.38,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Form(
                key: _formKey,
                child: Container(
                  height: screenHeight * 0.73,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/logo.png', height: 80),
                          const SizedBox(height: 10),
                          const Text(
                            'Regístrate ahora',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextFormField(
                            controller: nameController,
                            label: 'Nombre',
                            validator: (value) => value!.isEmpty
                                ? 'Por favor ingresa tu nombre'
                                : null,
                          ),
                          _buildTextFormField(
                            controller: lastNameController,
                            label: 'Apellidos',
                            validator: (value) => value!.isEmpty
                                ? 'Por favor ingresa tus apellidos'
                                : null,
                          ),
                          _buildTextFormField(
                            controller: emailController,
                            label: 'E-mail',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => !value!.contains('@')
                                ? 'Ingresa un email válido'
                                : null,
                          ),
                          _buildPasswordField(
                            controller: passController,
                            label: 'Contraseña',
                            obscure: _obscurePassword,
                            toggle: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            validator: (value) => value!.length < 6
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          _buildPasswordField(
                            controller: confirmPassController,
                            label: 'Confirmar contraseña',
                            obscure: _obscureConfirmPassword,
                            toggle: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            validator: (value) => value != passController.text
                                ? 'Las contraseñas no coinciden'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.secondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: AppColors.secondary,
                                      strokeWidth: 2,
                                    )
                                  : const Text(
                                      'Registrarse',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: toggle,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
