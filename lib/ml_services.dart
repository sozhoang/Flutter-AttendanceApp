import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLService {
  late Interpreter interpreter;

  initInterpreter() async {
    try {
      interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<List?> runInference(img.Image image) async {
    List input = _imageToByteListFloat32(image);
    input = input.reshape([1, 112, 112, 3]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    await initInterpreter();
    interpreter.run(input, output);
    output = output.reshape([192]);
    List predict = List.from(output);
    return predict;
  }

  euclideanDistance(List l1, List l2) {
    double sum = 0;
    for (int i = 0; i < l1.length; i++) {
      sum += pow((l1[i] - l2[i]), 2);
    }

    return pow(sum, 0.5);
  }

  Float32List _imageToByteListFloat32(img.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel)) / 255;
        buffer[pixelIndex++] = (img.getGreen(pixel)) / 255;
        buffer[pixelIndex++] = (img.getBlue(pixel)) / 255;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}
