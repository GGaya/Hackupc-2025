import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/Item.dart';
import 'package:url_launcher/url_launcher.dart';
class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  late Future<List<Item>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoritesFuture = loadFavoriteItems();
  }

  void _removeFavorite(Item item) async {
    item.isFavorite = false;
    await updateFavoriteInFile([item]);
    _loadFavorites(); // recarga la lista
    setState(() {});  // fuerza actualización de UI
  }

  void _showItemDialog(BuildContext context, Item item) {
    bool isUnliked = false; // ⬅️ Variable local para estado del favorito

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async {
                // ✅ Cuando se cierra el diálogo, si fue desmarcado, aplicar el cambio
                if (isUnliked) _removeFavorite(item);
                return true;
              },
              child: AlertDialog(
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        item.imageURL,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart),
                            onPressed: () async {
                              final uri = Uri.parse(item.shopURL);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isUnliked ? Icons.favorite_border : Icons.favorite,
                              color: isUnliked ? Colors.grey : Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                isUnliked = !isUnliked;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // También aplicamos la acción si el usuario cierra el diálogo tocando fuera
      if (isUnliked) _removeFavorite(item);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: FutureBuilder<List<Item>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading favorites'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('No favourite images yet', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final items = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return GestureDetector(
                onTap: () => _showItemDialog(context, item),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageURL,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
