
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

Future<List<Item>> saveItemsToFile(List<Item> newItems) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/Data.json');

  List<Item> existingItems = [];

  // Leer los existentes
  if (await file.exists()) {
    final content = await file.readAsString();
    final List decoded = jsonDecode(content);
    existingItems = decoded.map((e) => Item.fromJson(e)).toList();
  }

  // Crear mapa para evitar duplicados (por ejemplo usando shopURL como clave)
  final Map<String, Item> itemMap = {
    for (final item in existingItems) item.shopURL: item
  };

  // Agregar nuevos, pero solo si no existen ya
  for (final item in newItems) {
    if (!itemMap.containsKey(item.shopURL)) {
      itemMap[item.shopURL] = item;
    } else {
      // Si ya existe, usamos el que ya estaba para conservar isFavorite
      final existing = itemMap[item.shopURL]!;
      item.isFavorite = existing.isFavorite;
    }
  }

  final updatedList = itemMap.values.toList();

  // Guardar todo de nuevo
  final jsonData = updatedList.map((item) => item.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonData), flush: true);

  return updatedList;
}



Future<void> updateFavoriteInFile(List<Item> updatedItems) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/Data.json');

  if (!await file.exists()) return;

  final content = await file.readAsString();
  final List decoded = jsonDecode(content);
  final List<Item> existingItems = decoded.map((e) => Item.fromJson(e)).toList();

  // Mapear por shopURL para acceso rápido
  final Map<String, Item> itemMap = {
    for (final item in existingItems) item.shopURL: item
  };

  // Actualizar los favoritos
  for (final item in updatedItems) {
    if (itemMap.containsKey(item.shopURL)) {
      itemMap[item.shopURL]!.isFavorite = item.isFavorite;
    }
  }

  final jsonData = itemMap.values.map((e) => e.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonData), flush: true);
}


class Item {
  final String shopURL;
  final String imageURL;
  final String name;
  final String price;
  final String brand;
  bool isFavorite;

  Item({
    required this.shopURL,
    required this.imageURL,
    required this.name,
    required this.price,
    required this.brand,
    this.isFavorite = false,
  });

  // Convertir desde un Map (útil para JSON o Firebase)
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      shopURL: map['shopURL'] ?? '',
      imageURL: map['imageURL'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      brand: map['brand'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  // Convertir a Map (útil para guardar datos)
  Map<String, dynamic> toMap() {
    return {
      'shopURL': shopURL,
      'imageURL': imageURL,
      'name': name,
      'price': price,
      'brand': brand,
      'isFavorite': isFavorite,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      price: json['price'],
      shopURL: json['shopURL'],
      imageURL: json['imageURL'],
      brand: json['brand'],
      isFavorite: json['isFavorite']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'shopURL': shopURL,
      'imageURL': imageURL,
      'brand': brand,
      'isFavorite': isFavorite
    };
  }
}
