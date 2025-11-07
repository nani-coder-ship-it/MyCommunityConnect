import 'package:flutter/material.dart';
import 'dart:convert';

class FullScreenImageViewer extends StatefulWidget {
  final String imageData;

  const FullScreenImageViewer({super.key, required this.imageData});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onDoubleTap: () {
          // Reset zoom on double tap
          _transformationController.value = Matrix4.identity();
        },
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: _buildImage(widget.imageData),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageData) {
    try {
      // Check if it's a base64 image
      if (imageData.startsWith('data:image')) {
        final base64String = imageData.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => const Center(
            child: Icon(Icons.broken_image, size: 100, color: Colors.white),
          ),
        );
      } else {
        // It's a URL
        return Image.network(
          imageData,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => const Center(
            child: Icon(Icons.broken_image, size: 100, color: Colors.white),
          ),
        );
      }
    } catch (e) {
      return const Center(
        child: Icon(Icons.broken_image, size: 100, color: Colors.white),
      );
    }
  }
}
