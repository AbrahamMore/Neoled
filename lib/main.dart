import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_checker.dart';

// Importa tus pantallas
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/main_navigation.dart';
import 'screens/bienvenida.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoLedMex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthChecker(),
      routes: {
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
        '/main_navigation': (context) => const MainNavigation(),
        '/welcome': (context) => const WelcomeScreen(),
        // Agrega aquí más rutas si tienes otras pantallas
      },
    );
  }
}
