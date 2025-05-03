import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:indi_search/utils/file_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'SearchPage.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'FavouritesPage.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _cameraPermissionGranted = false;
  SensorPosition _sensorPosition = SensorPosition.back;
  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavouritesPage()),
    );
  }

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

  Future<void> uploadImage(File imageFile) async {
    var uri = Uri.parse('https://4.231.114.132:8000/upload-image');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    var response = await request.send();
    if (response.statusCode == 200) {
      print('Imagen enviada con éxito');
    } else {
      print('Fallo al enviar la imagen');
    }
  }

  void _openGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GalleryPage(imagePath: pickedFile.path),
        ),
      );
    }
  }

  /*void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoritesPage()),
    );
  }*/

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
                    single: (single) {
                      final file = File(single.file!.path);
                      uploadImage(file);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchPage(imageFile: file),
                        ),
                      );
                    },
                    multiple: (multiple) {
                      multiple.fileBySensor.forEach((key, value) {
                        debugPrint('multiple image taken: $key ${value?.path}');
                      });
                    },
                  );
                case (MediaCaptureStatus.failure, true, false):
                  debugPrint('Failed to capture picture: ${event.exception}');
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
          // Botón galería - ABAJO A LA DERECHA
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
          // Botón favoritos - ARRIBA DEL BOTÓN DE GALERÍA
          Positioned(
            right: 264, // 40 | Aquest valor fa que la icona estigui a l'esquerra
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
        ],
      ),
    );
  }
}

class GalleryPage extends StatelessWidget {
  final String imagePath;
  const GalleryPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galería')),
      body: Center(child: Image.file(File(imagePath))),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: const Center(child: Text('Aquí irán tus fotos favoritas.')),
    );
  }
}
