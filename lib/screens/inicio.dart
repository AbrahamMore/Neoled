import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/inventario/inventario.dart';
import 'package:pasos_flutter/screens/cliente/clientes.dart';
import 'package:pasos_flutter/screens/proveedor/proveedores.dart';
import 'package:pasos_flutter/screens/ventas/ventas.dart';
import 'package:pasos_flutter/screens/gastos/gastos.dart';
import 'package:pasos_flutter/screens/almacen/almacen.dart';
import 'package:pasos_flutter/screens/empleados/roles.dart';
import 'package:pasos_flutter/screens/negocio/negocio.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  Map<String, dynamic>? _usuario;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _error = 'Usuario no autenticado.';
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'No se encontró el usuario en la base de datos.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _usuario = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ocurrió un error al cargar la información del usuario.';
        _isLoading = false;
      });
    }
  }

  void _mostrarErrorPermisos() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: const Text('No tienes permisos para acceder a esta sección'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _tienePermiso(String modulo) {
    if (_usuario == null) return false;

    if (_usuario!['rol'] == 'admin') return true;

    final permisos = (_usuario!['permisos'] as List?)?.cast<String>() ?? [];
    return permisos.contains(modulo);
  }

  void _navegarSiTienePermiso(String modulo, Widget destino) {
    if (_tienePermiso(modulo)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
    } else {
      _mostrarErrorPermisos();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'NEOLEDMEX',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/iconos.png', fit: BoxFit.contain),
          ),
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  _buildAdminPanel(),
                  const SizedBox(height: 16),
                  _buildHerramientas(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanel() {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Administrar negocio',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAdminButton(
                  label: 'Negocio',
                  icon: Icons.store,
                  onTap: () =>
                      _navegarSiTienePermiso('Negocio', const NegocioScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdminButton(
                  label: 'Almacén',
                  icon: Icons.warehouse,
                  onTap: () =>
                      _navegarSiTienePermiso('Almacen', const AlmacenScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.secondary),
      label: Text(label, style: const TextStyle(color: AppColors.secondary)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildHerramientas() {
    final herramientas = [
      ('Clientes', Icons.person, AppColors.azul, const ClientesScreen()),
      (
        'Proveedores',
        Icons.local_shipping,
        AppColors.rojo,
        const ProveedoresScreen(),
      ),
      ('Empleados', Icons.people, AppColors.primary, const RolesScreen()),
      (
        'Inventario',
        Icons.inventory,
        AppColors.morado,
        const InventarioScreen(),
      ),
      ('Ventas', Icons.sell, AppColors.verde, const VentasScreen()),
      ('Gastos', Icons.money_off, AppColors.rosa, const GastosScreen()),
    ];

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Herramientas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: herramientas.map((h) {
              return _buildToolCard(
                label: h.$1,
                icon: h.$2,
                color: h.$3,
                destino: h.$4,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required String label,
    required IconData icon,
    required Color color,
    required Widget destino,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: () => _navegarSiTienePermiso(label, destino),
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.15),
        child: Container(
          width: 140,
          height: 120,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: AppColors.accent),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
