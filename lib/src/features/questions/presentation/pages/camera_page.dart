import 'package:camera/camera.dart';
import 'package:doormer/src/features/questions/presentation/params/camera_capture_params.dart';
import 'package:doormer/src/features/questions/presentation/templates/camera_capture_template.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw CameraException(
          'NoCamera',
          'No camera was found on this device.',
        );
      }

      // 优先使用后置摄像头
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      final initializeFuture = controller.initialize();

      setState(() {
        _controller = controller;
        _initializeControllerFuture = initializeFuture;
      });

      await initializeFuture;

      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.description ?? 'Could not open the camera.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An unexpected error occurred: $error',
          ),
        ),
      );
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    final initializeFuture = _initializeControllerFuture;

    if (controller == null || initializeFuture == null) return;

    try {
      await initializeFuture;

      if (controller.value.isTakingPicture) return;

      final image = await controller.takePicture();

      if (!mounted) return;

      // 把拍照结果返回 ask_by_photo_page.dart
      Navigator.of(context).pop(image);
    } on CameraException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.description ?? 'Failed to take picture.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initializeFuture = _initializeControllerFuture;

    if (controller == null || initializeFuture == null) {
      return CameraCaptureTemplate(
        params: _params(status: CameraCaptureStatus.starting),
      );
    }

    return FutureBuilder<void>(
      future: initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return CameraCaptureTemplate(
            params: _params(status: CameraCaptureStatus.failed),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return CameraCaptureTemplate(
            params: _params(
              status: CameraCaptureStatus.ready,
              preview: CameraPreview(controller),
            ),
          );
        }
        return CameraCaptureTemplate(
          params: _params(status: CameraCaptureStatus.starting),
        );
      },
    );
  }

  CameraCaptureParams _params({
    required CameraCaptureStatus status,
    Widget? preview,
  }) {
    return CameraCaptureParams(
      status: status,
      preview: preview,
      title: 'Take a photo',
      failureMessage: 'Unable to open camera',
      onCapture: _takePicture,
    );
  }
}
