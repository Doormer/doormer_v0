import 'package:doormer/src/features/questions/presentation/params/camera_capture_params.dart';
import 'package:flutter/material.dart';

/// The capture screen: preview, and the shutter under it.
///
/// Black rather than themed. The preview is the only thing that matters here,
/// and any surface colour around it shifts how the frame reads.
class CameraCaptureTemplate extends StatelessWidget {
  final CameraCaptureParams params;

  const CameraCaptureTemplate({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(params.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(child: _body()),
      floatingActionButton: FloatingActionButton(
        key: const Key('camera_shutter'),
        onPressed: params.onCapture,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _body() {
    final preview = params.preview;
    if (params.status == CameraCaptureStatus.ready && preview != null) {
      return KeyedSubtree(
        key: const Key('camera_preview'),
        child: preview,
      );
    }
    if (params.status == CameraCaptureStatus.failed) {
      return Text(
        params.failureMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      );
    }
    return const CircularProgressIndicator();
  }
}
