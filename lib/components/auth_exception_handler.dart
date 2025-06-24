import 'package:flutter/material.dart';

class AuthExceptionHandler {
  static void showSnackbar(BuildContext context, String errorCode) {
    String errorMessage;

    switch (errorCode) {
      case 'email-already-in-use':
        errorMessage = 'El correo ya está registrado';
        break;
      case 'invalid-email':
        errorMessage = 'Correo electrónico inválido';
        break;
      case 'weak-password':
        errorMessage = 'La contraseña debe tener al menos 6 caracteres';
        break;
      case 'user-disabled':
        errorMessage = 'Cuenta deshabilitada';
        break;
      case 'user-not-found':
        errorMessage = 'Usuario no encontrado';
        break;
      case 'wrong-password':
        errorMessage = 'Contraseña incorrecta';
        break;
      default:
        errorMessage = 'Error desconocido';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
  }
}
