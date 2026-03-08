// ignore_for_file: type=lint
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MinglitImageSourceSheet extends StatelessWidget {
  const MinglitImageSourceSheet({
    required this.onSourceSelected,
    super.key,
  });

  final void Function(ImageSource) onSourceSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('카메라로 촬영'),
            onTap: () {
              Navigator.pop(context);
              onSourceSelected(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('갤러리에서 선택'),
            onTap: () {
              Navigator.pop(context);
              onSourceSelected(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }
}
