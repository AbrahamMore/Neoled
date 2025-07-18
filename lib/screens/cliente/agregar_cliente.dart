import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';

class AgregarCliente extends StatefulWidget {
  final String? clienteId;
  final Map<String, dynamic>? clienteData;

  const AgregarCliente({super.key, this.clienteId, this.clienteData});

  @override
  State<AgregarCliente> createState() => _AgregarClienteState();
}

class _AgregarClienteState extends State<AgregarCliente> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.clienteData != null) {
      _nombreController.text = widget.clienteData!['nombre'] ?? '';
      _apellidosController.text = widget.clienteData!['apellidos'] ?? '';
      _direccionController.text = widget.clienteData!['direccion'] ?? '';
      _telefonoController.text = widget.clienteData!['telefono'] ?? '';
      _correoController.text = widget.clienteData!['correo'] ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo con imagen
        Positioned.fill(
          child: Image.asset('assets/images/estrellas.jpg', fit: BoxFit.cover),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            centerTitle: true,
            title: Text(
              widget.clienteId == null ? 'Agregar Cliente' : 'Editar Cliente',
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            child: Column(
              children: [
                Center(child: _buildAvatar()),
                const SizedBox(height: 15),
                _buildFormField('Nombre*', Icons.person, _nombreController),
                const SizedBox(height: 15),
                _buildFormField(
                  'Apellidos',
                  Icons.person_outline,
                  _apellidosController,
                ),
                const SizedBox(height: 15),
                _buildFormField(
                  'Dirección',
                  Icons.location_on,
                  _direccionController,
                ),
                const SizedBox(height: 15),
                _buildFormField(
                  'Teléfono*',
                  Icons.phone,
                  _telefonoController,
                  TextInputType.phone,
                ),
                const SizedBox(height: 15),
                _buildFormField(
                  'Correo Electrónico',
                  Icons.email,
                  _correoController,
                  TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _guardarCliente(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.verde,
                foregroundColor: AppColors.accent,
                minimumSize: const Size(
                  double.infinity,
                  50,
                ), // Esto va aquí, no dentro del shape
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: AppColors.accent)
                  : const Text(
                      'Guardar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 115,
          height: 115,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
          ),
        ),
        IconButton(
          iconSize: 60,
          icon: const Icon(Icons.camera_alt, color: AppColors.azul),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    IconData icon,
    TextEditingController controller, [
    TextInputType? type,
  ]) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(
        color: AppColors.secondary,
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: AppColors.secondary),
        filled: true,
        fillColor: AppColors.accent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }

  Future<void> _guardarCliente(BuildContext context) async {
    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();
    final correo = _correoController.text.trim();

    // Validar solo campos obligatorios
    if (nombre.isEmpty || telefono.isEmpty) {
      _mostrarMensajeError(
        'Por favor completa los campos obligatorios (Nombre y Telefono)',
      );
      return;
    }

    // Validar formato de correo solo si se proporcionó
    if (correo.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
      if (!emailRegex.hasMatch(correo)) {
        _mostrarMensajeError('Correo electrónico inválido');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final clientesRef = FirebaseFirestore.instance.collection('clientes');

      // Verificar si el teléfono ya existe
      final telefonoQuery = await clientesRef
          .where('telefono', isEqualTo: telefono)
          .get();

      bool telefonoExiste = telefonoQuery.docs.any(
        (doc) => doc.id != widget.clienteId,
      );

      // Verificar si el correo ya existe solo si se proporcionó
      bool correoExiste = false;
      if (correo.isNotEmpty) {
        final correoQuery = await clientesRef
            .where('correo', isEqualTo: correo)
            .get();
        correoExiste = correoQuery.docs.any(
          (doc) => doc.id != widget.clienteId,
        );
      }

      if (telefonoExiste && correoExiste) {
        _mostrarMensajeError(
          'El teléfono y el correo electrónico ya están registrados',
        );
        return;
      } else if (telefonoExiste) {
        _mostrarMensajeError('El teléfono ya está registrado');
        return;
      } else if (correoExiste) {
        _mostrarMensajeError('El correo electrónico ya está registrado');
        return;
      }

      // Preparar datos para guardar
      final clienteData = {
        'nombre': nombre,
        'telefono': telefono,
        'fecha_registro': FieldValue.serverTimestamp(),
      };

      // Agregar campos opcionales solo si tienen valor
      final apellidos = _apellidosController.text.trim();
      if (apellidos.isNotEmpty) clienteData['apellidos'] = apellidos;

      final direccion = _direccionController.text.trim();
      if (direccion.isNotEmpty) clienteData['direccion'] = direccion;

      if (correo.isNotEmpty) clienteData['correo'] = correo;

      if (widget.clienteId != null) {
        await clientesRef.doc(widget.clienteId).update(clienteData);
        _mostrarMensajeExito('Cliente actualizado exitosamente');
      } else {
        await clientesRef.add(clienteData);
        _mostrarMensajeExito('Cliente agregado exitosamente');
      }

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _mostrarMensajeError('Error al guardar: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
