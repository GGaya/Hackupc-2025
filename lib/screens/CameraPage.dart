import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/file_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class CameraAwesomeApp extends StatelessWidget {
  const CameraAwesomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'camerAwesome',
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
        // Puedes mostrar un diálogo o redirigir al usuario
        debugPrint('Permiso de cámara denegado');
      }
    }
  }



  Future<void> uploadImage(File imageFile) async {
    var uri = Uri.parse('http://172.20.10.4:8000/upload-image/');

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Imagen enviada con éxito');
    } else {
      print('Fallo al enviar la imagen');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraPermissionGranted) {
      return const Scaffold(
        body: Center(
          child: Text('Esperando permiso de cámara...'),
        ),
      );
    }

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: CameraAwesomeBuilder.awesome(
          onMediaCaptureEvent: (event) {
            switch ((event.status, event.isPicture, event.isVideo)) {
              case (MediaCaptureStatus.capturing, true, false):
                debugPrint('Capturing picture...');
              case (MediaCaptureStatus.success, true, false):
                event.captureRequest.when(
                  single: (single) {
                    uploadImage(File(single.file!.path));
                    debugPrint('Picture saved: ${single.file?.path}');
                  },
                  multiple: (multiple) {
                    multiple.fileBySensor.forEach((key, value) {
                      debugPrint('multiple image taken: $key ${value?.path}');
                    });
                  },
                );
              case (MediaCaptureStatus.failure, true, false):
                debugPrint('Failed to capture picture: ${event.exception}');
              case (MediaCaptureStatus.capturing, false, true):
                debugPrint('Capturing video...');
              default:
                debugPrint('Unknown event: $event');
            }
          },
          saveConfig: SaveConfig.photo(
            pathBuilder: (sensors) async {
              final Directory extDir = await getTemporaryDirectory();
              final testDir = await Directory(
                '${extDir.path}/camerawesome',
              ).create(recursive: true);
              if (sensors.length == 1) {
                final String filePath =
                    '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                return SingleCaptureRequest(filePath, sensors.first);
              }
              return MultipleCaptureRequest(
                {
                  for (final sensor in sensors)
                    sensor:
                    '${testDir.path}/${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg',
                },
              );
            },
            exifPreferences: ExifPreferences(saveGPSLocation: false),
          ),
          sensorConfig: SensorConfig.single(
            sensor: Sensor.position(SensorPosition.back),
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
                debugPrint('single: ${single.file?.path}');
                single.file?.open();
              },
              multiple: (multiple) {
                multiple.fileBySensor.forEach((key, value) {
                  debugPrint('multiple file taken: $key ${value?.path}');
                  value?.open();
                });
              },
            );
          },
          availableFilters: awesomePresetFiltersList,
        ),
      ),
    );
  }
}
