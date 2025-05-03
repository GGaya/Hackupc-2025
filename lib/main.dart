import 'dart:io';

// import 'package:better_open_file/better_open_file.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'utils/file_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() {
  runApp(const MaterialApp(
    home: CameraPage(),
  ));
}
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  Future<void> uploadImage(File imageFile) async {
    var uri = Uri.parse('http://4.231.114.132:8000/upload-image/');

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
    if (!_hasPermission) {
      return const Scaffold(
        body: Center(child: Text('Esperando permiso de cámara...')),
      );
    }

    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        onMediaCaptureEvent: (event) {
          switch ((event.status, event.isPicture, event.isVideo)) {
            case (MediaCaptureStatus.capturing, true, false):
              debugPrint('Capturando foto...');
            case (MediaCaptureStatus.success, true, false):
              event.captureRequest.when(
                single: (single) {
                  uploadImage(File(single.file!.path));
                  debugPrint('Foto guardada: ${single.file?.path}');
                },
                multiple: (multiple) {
                  multiple.fileBySensor.forEach((key, value) {
                    debugPrint('Foto múltiple: $key ${value?.path}');
                  });
                },
              );
            case (MediaCaptureStatus.failure, true, false):
              debugPrint('Error al capturar foto: ${event.exception}');
            case (MediaCaptureStatus.capturing, false, true):
              debugPrint('Grabando video...');
            case (MediaCaptureStatus.success, false, true):
              event.captureRequest.when(
                single: (single) {
                  debugPrint('Video guardado: ${single.file?.path}');
                },
                multiple: (multiple) {
                  multiple.fileBySensor.forEach((key, value) {
                    debugPrint('Video múltiple: $key ${value?.path}');
                  });
                },
              );
            case (MediaCaptureStatus.failure, false, true):
              debugPrint('Error al grabar video: ${event.exception}');
            default:
              debugPrint('Evento desconocido: $event');
          }
        },
        saveConfig: SaveConfig.photoAndVideo(
          initialCaptureMode: CaptureMode.photo,
          photoPathBuilder: (sensors) async {
            final dir = await getTemporaryDirectory();
            final folder = await Directory('${dir.path}/camerawesome').create(recursive: true);
            return SingleCaptureRequest('${folder.path}/${DateTime.now().millisecondsSinceEpoch}.jpg', sensors.first);
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
        availableFilters: awesomePresetFiltersList,
        onMediaTap: (media) {
          media.captureRequest.when(
            single: (single) => single.file?.open(),
            multiple: (multiple) {
              multiple.fileBySensor.forEach((_, file) => file?.open());
            },
          );
        },
      ),
    );
  }
}
