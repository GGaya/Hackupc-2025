import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}

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
        'shopURL': 'https://www.zara.com/es/en/v-nck-jrsy-14-p03039451.html',
        'imageURL': 'https://static.zara.net/assets/public/6bb0/b324/99c242d3a68a/cf1a037ca848/T0272791003-p/T0272791003-p.jpg?ts=1744131076418&w=750',
        'name': 'Camiseta blanca',
        'price': '19.99€',
        'brand': 'Zara',
        'isFavorite': false,
      },
      {
        'shopURL': 'https://www.zara.com/es/en/v-nck-jrsy-14-p03039451.html',
        'imageURL': 'https://static.zara.net/assets/public/6bb0/b324/99c242d3a68a/cf1a037ca848/T0272791003-p/T0272791003-p.jpg?ts=1744131076418&w=750',
        'name': 'Chaqueta denim',
        'price': '59.99€',
        'brand': 'Zara',
        'isFavorite': false,
      },
      {
        'shopURL': 'https://www.zara.com/es/en/v-nck-jrsy-14-p03039451.html',
        'imageURL': 'https://static.zara.net/assets/public/6bb0/b324/99c242d3a68a/cf1a037ca848/T0272791003-p/T0272791003-p.jpg?ts=1744131076418&w=750',
        'name': 'Pantalón beige',
        'price': '39.99€',
        'brand': 'Zara',
        'isFavorite': false,
      },
      {
        'shopURL': 'https://www.zara.com/es/en/v-nck-jrsy-14-p03039451.html',
        'imageURL': 'https://static.zara.net/assets/public/6bb0/b324/99c242d3a68a/cf1a037ca848/T0272791003-p/T0272791003-p.jpg?ts=1744131076418&w=750',
        'name': 'Zapatos negros',
        'price': '89.99€',
        'brand': 'Zara',
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
              height: 300,
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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      widget.imageFile,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 60,
                      color: Colors.white54, // blanco con opacidad
                    ),
                  ),
                ],
              ),
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
                            Image.network(
                              item['imageURL'],
                              fit: BoxFit.cover,
                              width: 150,
                              height: 150,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return CircularProgressIndicator(); // muestra mientras carga
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.error); // muestra si falla
                              },
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
          const SizedBox(height: 8),
          Text(
            items[_currentIndex]['brand'],
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
