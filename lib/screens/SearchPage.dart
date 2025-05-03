import 'dart:io';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final File imageFile;

  const SearchPage({super.key, required this.imageFile});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final PageController _pageController = PageController(viewportFraction: 0.6);
  int _currentIndex = 0;

  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();

    items = [
      {
        'image': widget.imageFile,
        'name': 'Camiseta blanca',
        'price': '19.99€',
        'isFavorite': false,
      },
      {
        'image': widget.imageFile,
        'name': 'Chaqueta denim',
        'price': '59.99€',
        'isFavorite': false,
      },
      {
        'image': widget.imageFile,
        'name': 'Pantalón beige',
        'price': '39.99€',
        'isFavorite': false,
      },
      {
        'image': widget.imageFile,
        'name': 'Zapatos negros',
        'price': '89.99€',
        'isFavorite': false,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const SizedBox(height: 50),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Image.file(widget.imageFile),
            ),
          ),

          const SizedBox(height: 20),

          // Carrusel
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final scale = _currentIndex == index ? 1.0 : 0.7;
                final item = items[index];

                return TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(begin: scale, end: scale),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              item['image'],
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    item['isFavorite'] = !item['isFavorite'];
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black45,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    item['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                                    color: item['isFavorite'] ? Colors.red : Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Texto debajo de la imagen seleccionada
          Text(
            items[_currentIndex]['name'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            items[_currentIndex]['price'],
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
