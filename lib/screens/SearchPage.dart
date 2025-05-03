import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/Item.dart';

Future<void> _launchURL(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir la URL')),
    );
  }
}

class SearchPage extends StatefulWidget {
  final File imageFile;
  final List<Item> items;

  const SearchPage({super.key, required this.imageFile, required this.items});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final PageController _pageController = PageController(viewportFraction: 0.6);
  int _currentIndex = 0;

  late final List<Item> items;

  @override
  void initState() {
    super.initState();
    items = widget.items; // ✅ Usa los que te pasan
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.05),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: screenWidth * 0.7,
              height: screenHeight * 0.35,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: screenWidth * 0.02,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.03),

          SizedBox(
            height: screenHeight * 0.35,
            child: items.isEmpty
                ? Center(
              child: Text(
                'No items found',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
                : PageView.builder(
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
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GestureDetector(
                              onTap: () => _launchURL(context, item.shopURL),
                              child: Image.network(
                                item.imageURL,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error);
                                },
                              ),
                            ),
                            Positioned(
                              top: screenHeight * 0.01,
                              right: screenWidth * 0.02,
                              child: GestureDetector (
                                onTap: () async {
                                  setState(() {
                                    item.isFavorite = !item.isFavorite;
                                  });
                                  await updateFavoriteInFile(items);
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black45,
                                  ),
                                  padding: EdgeInsets.all(screenWidth * 0.015),
                                  child: Icon(
                                    item.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: item.isFavorite ? Colors.red : Colors.white,
                                    size: screenWidth * 0.05,
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

          SizedBox(height: screenHeight * 0.03),

          if (items.isNotEmpty) ...[
            Text(
              items[_currentIndex].name,
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              items[_currentIndex].price,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              items[_currentIndex].brand,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.black,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
