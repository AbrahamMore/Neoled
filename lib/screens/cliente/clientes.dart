import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
// import 'package:pasos_flutter/components/custom_bottom.dart';
import 'package:pasos_flutter/screens/cliente/detalle_cliente.dart';
import 'package:pasos_flutter/screens/cliente/agregar_cliente.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  int currentIndex = 0;
  bool _isSearching = false;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  void onTapNav(int index) {
    setState(() => currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/inicio');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/ventas');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/estadisticas');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/movimientos');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/cuenta');
        break;
    }
  }

  Query getClientesQuery() {
    return FirebaseFirestore.instance
        .collection('clientes')
        .orderBy('nombre'); // Orden alfabético por nombre
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.secondary),
                decoration: const InputDecoration(
                  hintText: 'Buscar cliente...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _searchText = value.toLowerCase());
                },
              )
            : const Text(
                'Clientes',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppColors.secondary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchText = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/estrellas.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Nombres',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.verde,
                        foregroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AgregarCliente(),
                          ),
                        );
                      },
                      child: const Text(
                        'Agregar',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: getClientesQuery().snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay clientes.',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final todosLosClientes = snapshot.data!.docs;

                      // Filtrar por nombre o teléfono
                      final clientesFiltrados = todosLosClientes.where((doc) {
                        final nombre = (doc['nombre'] ?? '')
                            .toString()
                            .toLowerCase();
                        final telefono = (doc['telefono'] ?? '')
                            .toString()
                            .toLowerCase();
                        return nombre.contains(_searchText) ||
                            telefono.contains(_searchText);
                      }).toList();

                      if (clientesFiltrados.isEmpty) {
                        return const Center(
                          child: Text(
                            'No se encontraron coincidencias.',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: clientesFiltrados.length,
                        itemBuilder: (context, index) {
                          final cliente = clientesFiltrados[index];
                          final nombre = cliente['nombre'] ?? 'Sin nombre';
                          final telefono =
                              cliente['telefono'] ?? 'Sin teléfono';

                          return Card(
                            color: AppColors.accent,
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  width: 45,
                                  height: 45,
                                  color: AppColors.secondary,
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              title: Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                              subtitle: Text(
                                'Tel: $telefono',
                                style: const TextStyle(color: AppColors.rojo),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetalleCliente(
                                      clienteId: cliente.id,
                                      clienteData:
                                          cliente.data()!
                                              as Map<String, dynamic>,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // bottomNavigationBar: CustomBottomNavBar(
      //   currentIndex: currentIndex,
      //   onTap: onTapNav,
      // ),
    );
  }
}
