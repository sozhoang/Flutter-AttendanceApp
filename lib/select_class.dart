// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:image/image.dart' as img;
import 'package:flutter/cupertino.dart';
import 'camera.dart';
import 'list_class.dart';

class SelectClass extends StatelessWidget {
  const SelectClass({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          backgroundColor: Color.fromARGB(255, 247, 25, 9),
          middle: Text(
            'Select Class',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.white,
        child: Center(
          child: Column(children: [
            const SizedBox(height: 20),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 243, 187, 183),
                    surfaceTintColor: const Color.fromARGB(255, 244, 122, 113)),
                onPressed: () {
                  Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const CameraScreen(),
                      ));
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(
                        '143823 - Time Series Analysis - MI4050',
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      SizedBox(height: 0.5),
                      Text(
                        'Lecturers: Nguyen Thi Ngoc Anh',
                        style: TextStyle(fontSize: 10, color: Colors.black),
                      )
                    ],
                  ),
                )),
            // const SizedBox(height: 20),
            // CupertinoButton.filled(
            //     child: ListTile(
            //         leading: Text(
            //           "1",
            //           style: const TextStyle(fontSize: 24, color: Colors.white),
            //         ),
            //         title: Text(
            //           '143823 - Time Series Analysis - MI4050',
            //           style: TextStyle(color: Colors.white),
            //         ),
            //         subtitle: Text(
            //           'Lecturers: Nguyen Thi Ngoc Anh',
            //           style: TextStyle(color: Colors.white),
            //         )),
            //     onPressed: () {
            //       Navigator.push(
            //           context,
            //           CupertinoPageRoute(
            //             builder: (context) => const ListClass(),
            //           ));
            //     })
          ]),
        ));
  }
}
