import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as img;
import 'check_list.dart';
import 'list_class.dart';

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
  String name = "";
  final List<Map<String, dynamic>> _allUsers = [
    {"id": 1, "name": "Nguyen Duc Anh", "mssv": 20204811, "present": false},
    {"id": 2, "name": "Nguyen Viet Anh", "mssv": 20200039, "present": false},
    {"id": 3, "name": "Nguyen Bao Anh", "mssv": 20206110, "present": false},
    {"id": 4, "name": "Nguyen Sy Dat", "mssv": 20180036, "present": false},
    {"id": 5, "name": "Ho Van Dien", "mssv": 20160611, "present": false},
    {
      "id": 6,
      "name": "Nguyen Tai Quang Dinh",
      "mssv": 20200092,
      "present": false
    },
    {"id": 7, "name": "Ha Minh Dung", "mssv": 20200096, "present": false},
    {"id": 8, "name": "Nguyen Sy Huan", "mssv": 20200253, "present": false},
    {"id": 9, "name": "Dang Nhat Huy", "mssv": 20200271, "present": false},
    {"id": 10, "name": "Nguyen Dinh Huy", "mssv": 20200277, "present": false},
    {
      "id": 11,
      "name": "Nguyen Trinh Khang",
      "mssv": 20200313,
      "present": false
    },
    {"id": 12, "name": "Le Trung Kien", "mssv": 20195893, "present": false},
    {"id": 13, "name": "Mac Anh Kiet", "mssv": 20200307, "present": false},
    {"id": 14, "name": "Phan Thanh Long", "mssv": 20200369, "present": false},
    {"id": 15, "name": "Vu Hoai Nam", "mssv": 20190059, "present": false},
    {"id": 16, "name": "Nguyen Van Nghiem", "mssv": 20206206, "present": false},
    {"id": 17, "name": "Nguyen Hoang Nhat", "mssv": 20204772, "present": false},
    {"id": 18, "name": "Le Hai Phong", "mssv": 20200460, "present": false},
    {"id": 19, "name": "Nguyen Duc Quan", "mssv": 20200505, "present": false},
    {"id": 20, "name": "Nguyen Hoang Son", "mssv": 20206165, "present": false},
    {"id": 21, "name": "Do Dieu Thao", "mssv": 20200599, "present": false},
    {"id": 22, "name": "Dang Sy Tien", "mssv": 20200537, "present": false},
    {"id": 23, "name": "Dang Tran Tien", "mssv": 20195927, "present": false},
    {"id": 24, "name": "Tran Thanh Tung", "mssv": 20206184, "present": false}
  ];

  String get currentStatus {
    if (status == null) {
      return "Initializing...";
    }
    switch (status!) {
      case DetectionStatus.noFace:
        return "No Face Detected in the screen";
      case DetectionStatus.fail:
        return "Unrecognized Face Detected";
      case DetectionStatus.success:
        return "Hi " + name;
    }
  }

  Color get currentStatusColor {
    if (status == null) {
      return Colors.grey;
    }
    switch (status!) {
      case DetectionStatus.noFace:
        return Colors.grey;
      case DetectionStatus.fail:
        return Colors.red;
      case DetectionStatus.success:
        return Colors.greenAccent;
    }
  }

  @override
  void initState() {
    super.initState();
    initializeCamera();
    initializeWebSocket();
  }

  void updatePresentStatus(String message) {
    for (var user in _allUsers) {
      if (user['name'] == message) {
        user['present'] = true;
        break; // Khi tìm thấy, dừng vòng lặp
      }
    }
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras[0]; // back 0th index & front 1st index

    controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller!.initialize();
    setState(() {});

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final image = await controller!.takePicture();
        final compressedImageBytes = compressImage(image.path);
        channel.sink.add(compressedImageBytes);
      } catch (_) {}
    });
  }

  void initializeWebSocket() {
    // 0.0.0.0 -> 10.0.2.2 (emulator)
    channel = IOWebSocketChannel.connect('ws://10.0.2.2:8765');
    channel.stream.listen((dynamic data) {
      debugPrint(data);
      data = jsonDecode(data);
      if (data['data'] == null) {
        debugPrint('Server error occurred in recognizing face');
        return;
      }
      switch (data['data']) {
        case 0:
          status = DetectionStatus.noFace;
          break;
        case 1:
          status = DetectionStatus.fail;
          break;
        case 2:
          status = DetectionStatus.success;
          name = data['message'];
          updatePresentStatus(name);
          break;
        default:
          status = DetectionStatus.noFace;
          break;
      }
      setState(() {});
    }, onError: (dynamic error) {
      debugPrint('Error: $error');
    }, onDone: () {
      debugPrint('WebSocket connection closed');
    });
  }

  Uint8List compressImage(String imagePath, {int quality = 85}) {
    final image =
        img.decodeImage(Uint8List.fromList(File(imagePath).readAsBytesSync()))!;
    final compressedImage =
        img.encodeJpg(image, quality: quality); // lossless compression
    return compressedImage;
  }

  @override
  void dispose() {
    controller?.dispose();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!(controller?.value.isInitialized ?? false)) {
      return const SizedBox();
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color.fromARGB(255, 247, 25, 9),
        middle: Text(
          'Attendance',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: controller!.value.aspectRatio,
              child: CameraPreview(controller!),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.9),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  surfaceTintColor: currentStatusColor),
              child: Text(
                currentStatus,
                style: const TextStyle(fontSize: 20),
              ),
              onPressed: () {},
            ),
          ),
          Align(
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
          )
        ],
      ),
    );
  }
}
