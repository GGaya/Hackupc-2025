import 'dart:io';
import 'dart:convert';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';

import '../utils/Item.dart';
import 'SearchPage.dart';
import 'FavouritesPage.dart';

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'IndiSearch',
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _cameraPermissionGranted = false;
  bool _isLoading = false;
  SensorPosition _sensorPosition = SensorPosition.back;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _cameraPermissionGranted = true;
      });
    } else {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        setState(() {
          _cameraPermissionGranted = true;
        });
      } else {
        debugPrint('Permiso de cámara denegado');
      }
    }
  }

  Future<List<Item>> parseResponse(http.StreamedResponse response) async {
    final body = await response.stream.bytesToString();
    final List decoded = jsonDecode(body);
    return decoded.map((e) => Item.fromJson(e)).toList();
  }

  Future<List<Item>> uploadImage(File imageFile) async {
    try {
      var uri = Uri.parse('https://indisearch.study:8443/upload-image/');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final items = await parseResponse(response);
        return items;
      } else {
        print('Fallo al enviar la imagen: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error al enviar imagen: $e');
      return [];
    }
  }

  void _openGallery() async {
    if (_isLoading) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      final file = File(pickedFile.path);
      List<Item> items = await uploadImage(file);
      List<Item> itemsReviewed = await saveItemsToFile(items);
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchPage(imageFile: file, items: itemsReviewed),
        ),
      );
    }
  }

  void _openFavorites() {
    if (_isLoading) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavouritesPage()),
    );
  }

  void _toggleCamera() {
    setState(() {
      _sensorPosition = _sensorPosition == SensorPosition.back
          ? SensorPosition.front
          : SensorPosition.back;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraPermissionGranted) {
      return const Scaffold(
        body: Center(child: Text('Esperando permiso de cámara...')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraAwesomeBuilder.awesome(
            onMediaCaptureEvent: (event) {
              switch ((event.status, event.isPicture, event.isVideo)) {
                case (MediaCaptureStatus.success, true, false):
                  event.captureRequest.when(
                    single: (single) async {
                      final file = File(single.file!.path);
                      setState(() => _isLoading = true);
                      List<Item> items = await uploadImage(file);
                      List<Item> itemsReviewed = await saveItemsToFile(items);
                      setState(() => _isLoading = false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchPage(imageFile: file, items: itemsReviewed),
                        ),
                      );
                    },
                    multiple: (multiple) {
                      multiple.fileBySensor.forEach((key, value) {
                        debugPrint('multiple image taken: $key ${value?.path}');
                      });
                    },
                  );
                  break;
                default:
                  break;
              }
            },
            saveConfig: SaveConfig.photo(
              pathBuilder: (sensors) async {
                final Directory extDir = await getTemporaryDirectory();
                final testDir = await Directory('${extDir.path}/camerawesome').create(recursive: true);
                if (sensors.length == 1) {
                  final String filePath = '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                  return SingleCaptureRequest(filePath, sensors.first);
                }
                return MultipleCaptureRequest({
                  for (final sensor in sensors)
                    sensor: '${testDir.path}/${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg',
                });
              },
              exifPreferences: ExifPreferences(saveGPSLocation: false),
            ),
            sensorConfig: SensorConfig.single(
              sensor: Sensor.position(_sensorPosition),
              flashMode: FlashMode.auto,
              aspectRatio: CameraAspectRatios.ratio_4_3,
              zoom: 0.0,
            ),
            enablePhysicalButton: true,
            previewAlignment: Alignment.center,
            previewFit: CameraPreviewFit.contain,
            onMediaTap: (mediaCapture) {
              mediaCapture.captureRequest.when(
                single: (single) {
                  if (single.file != null) {
                    OpenFilex.open(single.file!.path);
                  }
                },
                multiple: (multiple) {
                  multiple.fileBySensor.forEach((key, value) {
                    if (value != null) OpenFilex.open(value.path);
                  });
                },
              );
            },
          ),

          // Botón galería
          Positioned(
            right: 32,
            bottom: 16,
            child: GestureDetector(
              onTap: _openGallery,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black45,
                ),
                child: const Icon(Icons.photo, color: Colors.white),
              ),
            ),
          ),

          // Botón favoritos
          Positioned(
            right: 264,
            bottom: 84,
            child: GestureDetector(
              onTap: _openFavorites,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black45,
                ),
                child: const Icon(Icons.favorite, color: Colors.white),
              ),
            ),
          ),

          // Overlay de carga
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Searching Results...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
