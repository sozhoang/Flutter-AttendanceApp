import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as imglib;
import 'check_list.dart';
import 'list_class.dart';
import 'dart:developer';
import 'ml_services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

enum DetectionStatus { noFace, fail, success }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  late WebSocketChannel channel;
  DetectionStatus? status;
  bool isProcessing = false;
  String name = "";
  imglib.Image? yourImage;
  final MLService _mlService = MLService();
  List? recognitionsList;
  late FaceDetector _faceDetector;

  List<Face> faceDetected = [];

  List<Map<String, dynamic>> _allUsers = [];

  // String get currentStatus {
  //   if (status == null) {
  //     return "Initializing...";
  //   }
  //   switch (status!) {
  //     case DetectionStatus.noFace:
  //       return "No Face Detected in the screen";
  //     case DetectionStatus.fail:
  //       return "Unrecognized Face Detected";
  //     case DetectionStatus.success:
  //       return "Hi " + name;
  //   }
  // }

  // Color get currentStatusColor {
  //   if (status == null) {
  //     return Colors.grey;
  //   }
  //   switch (status!) {
  //     case DetectionStatus.noFace:
  //       return Colors.grey;
  //     case DetectionStatus.fail:
  //       return Colors.red;
  //     case DetectionStatus.success:
  //       return Colors.greenAccent;
  //   }
  // }

  @override
  void initState() {
    super.initState();
    readJsonData();
    initializeCamera();
  }

  void updatePresentStatus(String message) {
    for (var user in _allUsers) {
      if (user['name'] == message) {
        user['present'] = true;
        break;
      }
    }
  }

  Future<void> readJsonData() async {
    String jsonString = await rootBundle.loadString('assets/Class_256.json');
    List<Map<String, dynamic>> jsonData =
        jsonDecode(jsonString).cast<Map<String, dynamic>>();

    // Add "present" field with initial value false to each element
    jsonData.forEach((element) {
      element['present'] = false;

      var vector = element['vector'];
      if (vector is List && vector.isNotEmpty && vector[0] is List) {
        vector = vector[0];
      }
      element['vector'] = (vector as List<dynamic>).map<double>((v) {
        try {
          return v.toDouble();
        } catch (e) {
          print('Error converting value to double: $v, error: $e');
          return 0.0;
        }
      }).toList();
    });

    _allUsers = jsonData;
  }

  Future<Map<String, dynamic>> findNearestObject(
      List<Map<String, dynamic>> jsonData, List<dynamic> embedding) async {
    double minDistance = double.infinity;
    Map<String, dynamic>? nearestObject;

    for (var object in jsonData) {
      List<dynamic> vector = object['vector'];
      double distance = _mlService.euclideanDistance(embedding, vector);

      if (distance < minDistance) {
        minDistance = distance;
        nearestObject = object;
      }
    }

    return nearestObject ?? {};
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras[0]; // back 0th index & front 1st index

    controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await controller!.initialize();
    loadDetector();
    setState(() {});

    await controller!.startImageStream((CameraImage image) async {
      if (!isProcessing) {
        isProcessing = true;
        embeddingImage(image);
      }
    });

    Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        isProcessing = false;
      } catch (e) {
        print('Error: $e');
      }
    });
  }

  Future<void> embeddingImage(CameraImage image) async {
    try {
      runDetector(image);

      setState(() {});
    } catch (e) {
      print('Error: $e');
    }
  }

  imglib.Image? convertToImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888(image);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        return _convertNV21(image);
      }
      throw Exception('Image format not supported');
    } catch (e) {
      inspect("ERROR:" + e.toString());
    }
    return null;
  }

  imglib.Image _convertBGRA8888(CameraImage image) {
    return imglib.Image.fromBytes(
      image.width,
      image.height,
      image.planes[0].bytes,
      format: imglib.Format.bgra,
    );
  }

  imglib.Image _convertYUV420(CameraImage image) {
    int width = image.width;
    int height = image.height;
    var img = imglib.Image(width, height);
    const int hexFF = 0xFF000000;
    final int uvyButtonStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex = uvPixelStride! * (x / 2).floor() +
            uvyButtonStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        img.data[index] = hexFF | (b << 16) | (g << 8) | r;
      }
    }

    return img;
  }

  imglib.Image _convertNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final Uint8List yuv420sp = image.planes[0].bytes;
    final imglib.Image outImg = imglib.Image(width, height);
    final int frameSize = width * height;

    for (int j = 0, yp = 0; j < height; j++) {
      int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
      for (int i = 0; i < width; i++, yp++) {
        int y = (0xff & yuv420sp[yp]) - 16;
        if (y < 0) y = 0;
        if ((i & 1) == 0) {
          v = (0xff & yuv420sp[uvp++]) - 128;
          u = (0xff & yuv420sp[uvp++]) - 128;
        }
        int y1192 = 1192 * y;
        int r = (y1192 + 1634 * v);
        int g = (y1192 - 833 * v - 400 * u);
        int b = (y1192 + 2066 * u);

        if (r < 0)
          r = 0;
        else if (r > 262143) r = 262143;
        if (g < 0)
          g = 0;
        else if (g > 262143) g = 262143;
        if (b < 0)
          b = 0;
        else if (b > 262143) b = 262143;

        outImg.setPixelRgba(i, j, ((r << 6) & 0xff0000) >> 16,
            ((g >> 2) & 0xff00) >> 8, (b >> 10) & 0xff);
      }
    }

    return outImg;
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('$path');

    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }

  InputImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  imglib.Image _cropFace(CameraImage image, Face faceDetected) {
    imglib.Image? convertedImage = convertToImage(image);
    double x = faceDetected.boundingBox.left;
    double y = faceDetected.boundingBox.top;
    double w = faceDetected.boundingBox.width;
    double h = faceDetected.boundingBox.height;

    return imglib.copyCrop(
        convertedImage!, x.round(), y.round(), w.round(), h.round());
  }

  Future<void> runDetector(CameraImage cameraImage) async {
    try {
      InputImage _visionImage = InputImage.fromBytes(
          bytes: cameraImage!.planes.first.bytes,
          metadata: InputImageMetadata(
              size: Size(
                  cameraImage.width.toDouble(), cameraImage.height.toDouble()),
              rotation: rotationIntToImageRotation(0), // used only in Android
              format: InputImageFormat.nv21,
              bytesPerRow: cameraImage.planes.first.bytesPerRow));

      faceDetected = await _faceDetector.processImage(_visionImage);
      inspect(faceDetected.first.boundingBox);
      yourImage = _cropFace(cameraImage, faceDetected.first);
      yourImage = imglib.copyRotate(yourImage!, 90);

      // recognitionsList = faceDetected;

      imglib.Image? crop_img = imglib.copyResizeCropSquare(yourImage!, 128);
      List? predict = await _mlService.runInference(crop_img);
      Map<String, dynamic> nearestCandicate =
          await findNearestObject(_allUsers, predict!);
      if (nearestCandicate.isNotEmpty) {
        status = DetectionStatus.success;
        name = nearestCandicate['name'];
        updatePresentStatus(name);
      } else {
        status = DetectionStatus.fail;
      }
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadDetector() async {
    _faceDetector = await GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (recognitionsList == null) return [];

    List<Widget> box = [];
    double factorX = screen.width;
    double factorY = screen.height;

    box.add(Positioned(
      // get top, left, width, height where result is Rect
      left: recognitionsList?.first.boundingBox.left,
      top: recognitionsList?.first.boundingBox.top,
      width: recognitionsList?.first.boundingBox.width,
      height: recognitionsList?.first.boundingBox.height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
          border: Border.all(color: Colors.pink, width: 1.0),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: FittedBox(
            child: Container(
              color: Colors.pink,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));

    return box;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(controller?.value.isInitialized ?? false)) {
      return const SizedBox();
    }
    Size size = MediaQuery.of(context).size;

    List<Widget> list = [];
    list.add(
      Positioned(
        top: 0.0,
        left: 0.0,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height - 100,
        child: Center(
          // Sử dụng Center để căn giữa widget
          child: Container(
            height: MediaQuery.of(context).size.height - 100,
            child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: CameraPreview(controller!),
            ),
          ),
        ),
      ),
    );
    // list.add(
    //   Align(
    //     alignment: const Alignment(0, -0.9),
    //     child: ElevatedButton(
    //       style: ElevatedButton.styleFrom(surfaceTintColor: currentStatusColor),
    //       child: Text(
    //         currentStatus,
    //         style: const TextStyle(fontSize: 20),
    //       ),
    //       onPressed: () {},
    //     ),
    //   ),
    // );
    list.add(Align(
      alignment: const Alignment(0, 0.90),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: Text(
          "End Process",
          style: const TextStyle(fontSize: 22, color: Colors.white),
        ),
        onPressed: () {
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => CheckList(allUsers: _allUsers),
              ));
        },
      ),
    ));

    // if (yourImage != null) {
    //   list.add(
    //     Align(
    //       alignment: Alignment.topRight,
    //       child: Image.memory(
    //         Uint8List.fromList(imglib.encodePng(yourImage!)),
    //         width: 100, // set the desired width
    //         height: 100, // set the desired height
    //       ),
    //     ),
    //   );
    // }

    if (yourImage != null) {
      list.add(
        Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Image.memory(
                Uint8List.fromList(imglib.encodePng(yourImage!)),
                width: 100, // set the desired width
                height: 100, // set the desired height
              ),
            ),
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   right: 0,
            //   child: Container(
            //     padding: EdgeInsets.all(10.0),
            //     child: Image.memory(
            //       Uint8List.fromList(imglib.encodePng(yourImage!)),
            //       width: 100, // set the desired width
            //       height: 100, // set the desired height
            //     ),
            //   ),
            // ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8.0), // adjust padding as needed
                // color: Colors.black.withOpacity(0.5), // overlay color
                child: Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.0,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    list.addAll(displayBoxesAroundRecognizedObjects(size));

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color.fromARGB(255, 247, 25, 9),
        middle: Text(
          'Attendance',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      child: Stack(
        children: list,
      ),
    );
  }
}
