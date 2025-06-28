import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pasos_flutter/core/app_colors.dart';
import 'package:pasos_flutter/components/custom_bottom.dart';
import 'package:pasos_flutter/screens/agregar_cliente.dart';
import 'package:pasos_flutter/screens/detalle_cliente.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  int currentIndex = 0;
  String searchText = '';
  bool showSearch = false;
  int limit = 10;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
    Query query = FirebaseFirestore.instance
        .collection('clientes')
        .orderBy('nombre')
        .limit(limit);

    if (searchText.isNotEmpty) {
      final searchLower = searchText.toLowerCase();
      query = query
          .where('nombreLower', isGreaterThanOrEqualTo: searchLower)
          .where('nombreLower', isLessThanOrEqualTo: '$searchLower\uf8ff');
    }

    return query;
  }

  void loadMore() {
    setState(() {
      limit += 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.secondary),
          onPressed: () {},
        ),
        title: showSearch
            ? TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchText = value.trim()),
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar cliente...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'Clientes',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              showSearch ? Icons.close : Icons.search,
              color: AppColors.secondary,
            ),
            onPressed: () {
              setState(() {
                showSearch = !showSearch;
                if (!showSearch) {
                  searchText = '';
                  _searchController.clear();
                }
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

                      final clientes = snapshot.data!.docs;

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: clientes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == clientes.length) {
                            return Center(
                              child: TextButton(
                                onPressed: loadMore,
                                child: const Text(
                                  'Cargar más...',
                                  style: TextStyle(color: AppColors.accent),
                                ),
                              ),
                            );
                          }

                          final cliente = clientes[index];
                          final nombre = cliente['nombre'];
                          final telefono = cliente['telefono'];

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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: onTapNav,
      ),
    );
  }
}
