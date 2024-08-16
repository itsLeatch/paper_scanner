import 'dart:ffi';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      home: const Camera(),
    );
  }
}

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  late CameraController controller;
  int selectedCamera = 0;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  void initCamera() {
    controller = CameraController(_cameras[selectedCamera], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.max,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(cameraController.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CameraPreview(controller,
        child: Stack(
          children: [
            //top right rotate camera button
            SafeArea(
              child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: SizedBox.square(
                      dimension: 64,
                      child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            selectedCamera++;
                            if (selectedCamera >= _cameras.length) {
                              selectedCamera = 0;
                            }
                            _onNewCameraSelected(_cameras[selectedCamera]);
                          },
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(0),
                              shape: CircleBorder()),
                          child: Icon(
                            Icons.flip_camera_ios,
                            size: 32,
                          )),
                    ),
                  )),
            ),

            //take picture button
            Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(64.0),
                  child: SizedBox.square(
                    dimension: 100,
                    child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          //TODO: implement take picture
                        },
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(0),
                            shape: CircleBorder(
                                side:
                                    BorderSide(color: Colors.grey, width: 8))),
                        child: Icon(
                          Icons.camera_alt,
                          size: 64,
                        )),
                  ),
                )),
          ],
        ));
  }
}
