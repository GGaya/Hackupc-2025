import 'dart:io';
import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  final File imageFile;

  const SearchPage({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView( // por si se desborda
        child: Column(
          children: [
            // 🟦 Imagen principal en su propio contenedor
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 80, left: 24, right: 24),
                padding: const EdgeInsets.all(16),
                width: 300,
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
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.file(imageFile),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 🌀 Carrusel de imágenes más grandes y separadas
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                      child: Image.file(imageFile),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
