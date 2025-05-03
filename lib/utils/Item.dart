
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

Future<List<Item>> saveItemsToFile(List<Item> newItems) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/Data.json');
  print('${dir.path}/Data.json');

  List<Item> existingItems = [];

  // Leer los existentes
  if (await file.exists()) {
    final content = await file.readAsString();
    final List decoded = jsonDecode(content);
    existingItems = decoded.map((e) => Item.fromJson(e)).toList();
  }

  // Crear mapa de existentes por shopURL
  final Map<String, Item> itemMap = {
    for (final item in existingItems) item.shopURL: item
  };

  // Lista final para guardar todo el archivo actualizado
  final Set<String> addedShopURLs = {};

  // Añadir nuevos, manteniendo isFavorite si ya existía
  for (final newItem in newItems) {
    final existing = itemMap[newItem.shopURL];
    if (existing != null) {
      newItem.isFavorite = existing.isFavorite;
    }

    // Aseguramos que se incluye en el mapa (ya sea nuevo o existente actualizado)
    itemMap[newItem.shopURL] = newItem;
    addedShopURLs.add(newItem.shopURL);
  }

  // Guardar el archivo completo (items antiguos + nuevos)
  final fullList = itemMap.values.toList();
  final jsonData = fullList.map((item) => item.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonData), flush: true);

  // Devolver solo los items correspondientes a newItems (con favoritos actualizados si ya existían)
  return newItems.map((i) => itemMap[i.shopURL]!).toList();
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

Future<List<Item>> loadFavoriteItems() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/Data.json');

  if (!await file.exists()) {
    return [];
  }

  try {
    final content = await file.readAsString();
    final List decoded = jsonDecode(content);
    final List<Item> allItems = decoded.map((e) => Item.fromJson(e)).toList();

    // Filtrar solo los favoritos
    final favorites = allItems.where((item) => item.isFavorite).toList();
    return favorites;
  } catch (e) {
    print('Error al leer favoritos: $e');
    return [];
  }
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
