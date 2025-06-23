import 'package:flutter/material.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/login.dart';
import 'package:pasos_flutter/screens/register.dart';

void main() {
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 120,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            Container(
              width: 320,
              height: 420,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/negocio.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 310,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 310,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Register()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Crear cuenta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
En primer lugar, se integró el CLI de Firebase al proyecto de Flutter, lo que permitió trabajar de manera eficiente con operaciones CRUD y consultas a la base de datos, asegurando una comunicación fluida entre la aplicación y el backend. Posteriormente, se configuró el proyecto móvil para garantizar el acceso seguro mediante verificaciones con Firebase, implementando autenticación y permisos adecuados para proteger los datos.
Se programó el CRUD para el inicio y registro de sesiones en la aplicación NeoLed app, se realizaron pruebas de emulación en distintos dispositivos móviles para verificar la ausencia de errores en la interfaz de usuario y posibles fallos funcionales, asegurando así un rendimiento óptimo en diferentes entornos.
*/
