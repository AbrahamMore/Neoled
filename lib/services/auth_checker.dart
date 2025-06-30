import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pasos_flutter/screens/main_navigation.dart';
import 'package:pasos_flutter/screens/bienvenida.dart';

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          if (user.emailVerified) {
            return const MainNavigation(); // Usuario autenticado y email verificado
          } else {
            return const WelcomeScreen(); // Email no verificado
          }
        } else {
          return const WelcomeScreen(); // Usuario no autenticado
        }
      },
    );
  }
}
