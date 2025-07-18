import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/screens/ventas/historial_ventas.dart';

class VentaLibreScreen extends StatefulWidget {
  const VentaLibreScreen({super.key});

  @override
  State<VentaLibreScreen> createState() => _VentaLibreScreenState();
}

class _VentaLibreScreenState extends State<VentaLibreScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  String _tipoPagoSeleccionado = 'Efectivo';
  String? _proveedorSeleccionado;
  String? _clienteSeleccionadoId;
  String? _clienteSeleccionadoNombre;
  DateTime? _fechaSeleccionada;
  String _rolUsuario = 'usuario'; // Variable para almacenar el rol del usuario

  final List<String> _tiposPago = [
    'Efectivo',
    'Tarjeta',
    'Transferencia',
    'Crédito',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Esto evita seleccionar fechas futuras
      helpText: 'Selecciona la fecha de la venta',
    );

    if (fecha != null) {
      // Validación adicional por si acaso
      if (fecha.isAfter(DateTime.now())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pueden registrar ventas con fecha futura'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _fechaSeleccionada = fecha;
        });
      }
    }
  }

  Future<void> _seleccionarCliente() async {
    final clientes = await FirebaseFirestore.instance
        .collection('clientes')
        .get();

    final resultado = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar cliente'),
        children: [
          ...clientes.docs.map((doc) {
            final data = doc.data();
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, {
                  'id': doc.id,
                  'nombre': (data['nombre'] ?? 'Sin nombre').toString(),
                });
              },
              child: Text((data['nombre'] ?? 'Sin nombre').toString()),
            );
          }),
          const Divider(),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: const Text('Cancelar selección'),
          ),
        ],
      ),
    );

    if (resultado != null) {
      setState(() {
        _clienteSeleccionadoId = resultado['id'];
        _clienteSeleccionadoNombre = resultado['nombre'];
      });
    }
  }

  Future<void> _registrarVentaLibre() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Obtener el rol del usuario (si existe)
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      // Si no existe el campo 'rol', se usará 'usuario' por defecto
      final rol = userDoc.data()?['rol']?.toString() ?? 'usuario';

      setState(() {
        _rolUsuario = rol; // Actualizamos el estado si lo necesitamos después
      });

      // Combinar fecha seleccionada con hora actual
      DateTime now = DateTime.now();
      DateTime fechaCombinada = _fechaSeleccionada != null
          ? DateTime(
              _fechaSeleccionada!.year,
              _fechaSeleccionada!.month,
              _fechaSeleccionada!.day,
              now.hour,
              now.minute,
              now.second,
            )
          : now;

      final ventaData = {
        'nombre': _nombreController.text.trim(),
        'valor': double.parse(_valorController.text),
        'tipoPago': _tipoPagoSeleccionado,
        'usuarioId': user.uid,
        'usuarioNombre': user.displayName ?? user.email,
        'fecha': Timestamp.fromDate(fechaCombinada),
        'esVentaLibre': true,
        'rolUsuario': rol, // Añadimos el rol al documento
      };

      // Agregar cliente si fue seleccionado
      if (_clienteSeleccionadoId != null) {
        ventaData['clienteId'] = _clienteSeleccionadoId;
        ventaData['clienteNombre'] = _clienteSeleccionadoNombre;
      }

      // Agregar proveedor si fue seleccionado
      if (_proveedorSeleccionado != null) {
        ventaData['proveedorId'] = _proveedorSeleccionado;
      }

      await FirebaseFirestore.instance.collection('ventas').add(ventaData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta libre registrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar el formulario
        _formKey.currentState?.reset();
        _nombreController.clear();
        _valorController.clear();
        _proveedorSeleccionado = null;
        _clienteSeleccionadoId = null;
        _clienteSeleccionadoNombre = null;
        _fechaSeleccionada = null;
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar venta libre: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta Libre'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistorialVentasScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la venta*',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un nombre para la venta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor de la venta*',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el valor de la venta';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingrese un valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selector de cliente
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person),
                      label: Text(
                        _clienteSeleccionadoNombre != null
                            ? 'Cliente: $_clienteSeleccionadoNombre'
                            : 'Seleccionar cliente (opcional)',
                      ),
                      onPressed: _seleccionarCliente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.secondary,
                      ),
                    ),
                  ),
                  if (_clienteSeleccionadoNombre != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _clienteSeleccionadoId = null;
                          _clienteSeleccionadoNombre = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Selector de proveedor
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('proveedores')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final proveedores = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _proveedorSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Proveedor (opcional)',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Ninguno'),
                      ),
                      ...proveedores.map((proveedor) {
                        return DropdownMenuItem<String>(
                          value: proveedor.id,
                          child: Text(proveedor['nombre'] ?? 'Sin nombre'),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _proveedorSeleccionado = newValue;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Selector de tipo de pago
              DropdownButtonFormField<String>(
                value: _tipoPagoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de pago*',
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _tiposPago.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _tipoPagoSeleccionado = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione un tipo de pago';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selector de fecha
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _fechaSeleccionada != null
                            ? 'Fecha: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}'
                            : 'Seleccionar fecha',
                      ),
                      onPressed: () => _seleccionarFecha(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón de registro
              ElevatedButton(
                onPressed: _registrarVentaLibre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Registrar Venta Libre',
                  style: TextStyle(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
