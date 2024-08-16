import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

List<CameraDescription> _cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Startscreen(),
    );
  }
}

class Startscreen extends StatefulWidget {
  const Startscreen({super.key});

  @override
  State<Startscreen> createState() => _StartscreenState();
}

class _StartscreenState extends State<Startscreen> {
  void takePicture() {
    ImagePicker()
        .pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.rear)
        .then((value) {
      if (value != null) {
        onImageTaken(value);
      }
    });
  }

  void onImageTaken(XFile image) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ImageScreen(image: image)));
  }

  @override
  void initState() {
    super.initState();
    takePicture();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
            onPressed: () => takePicture(), child: Text("New picture")),
      ),
    );
  }
}

class ImageScreen extends StatelessWidget {
  final XFile image;

  const ImageScreen({Key? key, required this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Uint8List>(
        future: image.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(child: Image.memory(snapshot.data!));
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
