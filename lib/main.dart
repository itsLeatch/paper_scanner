import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class FocusPoint {
  final Offset offset;
  DateTime lastUpdated = DateTime.now();

  FocusPoint(this.offset, {DateTime? lastUpdated}) {
    if (lastUpdated != null) {
      this.lastUpdated = lastUpdated;
    }
  }
}

class FocusPointBlob extends CustomPainter {
  final List<FocusPoint> focusPoints;

  FocusPointBlob(this.focusPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final List<FocusPoint> _activeFocusPoints = focusPoints;

    for (var element in _activeFocusPoints) {
      canvas.drawCircle(
        element.offset,
        10,
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  // Since this Sky painter has no fields, it always paints
  // the same thing and semantics information is the same.
  // Therefore we return false here. If we had fields (set
  // from the constructor) then we would return true if any
  // of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(FocusPointBlob oldDelegate) => true;
  @override
  bool shouldRebuildSemantics(FocusPointBlob oldDelegate) => false;
}

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  late CameraController controller;
  List<FocusPoint> focusPoints = [];
  int selectedCamera = 0;
  double currentZoom = 1.0;
  double _baseSclaeFactor = 1.0;

  double maxZoom = 1.0;
  double minZoom = 8.0;

  @override
  void initState(){
    super.initState();
    initCamera();
  }

  void initCamera(){
    controller =
        CameraController(_cameras[selectedCamera], ResolutionPreset.max);
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
   // controller.getMinZoomLevel().then((value) => minZoom = value);
   // controller.getMaxZoomLevel().then((value) => maxZoom = value);
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

    currentZoom = 1.0;
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
    return Stack(
      children: [
        Center(
            child: GestureDetector(
          child: CameraPreview(controller,
              child: CustomPaint(
                painter: FocusPointBlob(focusPoints),
              )),
          onTapDown: (details) {
            if (controller.value.focusPointSupported) {
              controller.setFocusPoint(Offset(
                  details.localPosition.dx / MediaQuery.of(context).size.width,
                  details.localPosition.dy /
                      MediaQuery.of(context).size.height));
            }
            if (controller.value.exposurePointSupported) {
              controller.setExposurePoint(Offset(
                  details.localPosition.dx / MediaQuery.of(context).size.width,
                  details.localPosition.dy /
                      MediaQuery.of(context).size.height));
            }
            setState(() {
              var focusPoint = FocusPoint(details.localPosition);
              focusPoints.add(focusPoint);
              Timer(const Duration(seconds: 2), () {
                setState(() {
                  focusPoints.remove(focusPoint);
                });
              });
            });
          },
          onScaleStart: (details) {
            _baseSclaeFactor = currentZoom;
          },
          onScaleUpdate: (details) {
            currentZoom = _baseSclaeFactor * details.scale;
            currentZoom = currentZoom.clamp(1.0, 100.0);
            controller.setZoomLevel(currentZoom);
            print(details.scale);
          },

        )),
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
                      controller.takePicture().then((XFile file) {
                        if (file != null) {
                          print('Picture saved to ${file.path}');
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(0),
                        shape: CircleBorder(
                            side: BorderSide(color: Colors.grey, width: 8))),
                    child: Icon(
                      Icons.camera_alt,
                      size: 64,
                    )),
              ),
            )),
      ],
    );
  }
}
