// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'select_class.dart';
// import 'package:camera/camera.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:image/image.dart' as img;

// import 'camera.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition Application',
      theme: ThemeData(useMaterial3: true),
      home: const Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.red,
        middle: Text(
          'Hust Attendance Demo',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      child: Center(
          child: Align(
              alignment: const Alignment(0, 0.5),
              child: Column(
                children: [
                  const SizedBox(height: 180),
                  Image.asset('assets/images/Logo_Hust.png',
                      width: 150, height: 200),
                  const SizedBox(height: 120),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        surfaceTintColor:
                            const Color.fromARGB(255, 244, 122, 113)),
                    child: const Text(
                      'Begin',
                      style: TextStyle(fontSize: 28, color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const SelectClass()),
                      );
                    },
                  ),
                ],
              ))),
    );
  }
}
