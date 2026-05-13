import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image picker helper with quality and size optimization
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick single image from gallery
  static Future<File?> pickFromGallery({
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 80,
  }) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
    );
    return image != null ? File(image.path) : null;
  }

  /// Take photo with camera
  static Future<File?> takePhoto({
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 80,
  }) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
    );
    return image != null ? File(image.path) : null;
  }

  /// Pick multiple images from gallery
  static Future<List<File>> pickMultipleFromGallery({
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 80,
    int limit = 5,
  }) async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
      limit: limit,
    );
    return images.map((xfile) => File(xfile.path)).toList();
  }

  /// Show image source picker dialog
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    if (source == ImageSource.camera) {
      return takePhoto();
    } else {
      return pickFromGallery();
    }
  }

  /// Get file size in human readable format
  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Copy image to app documents directory (for persistence)
  static Future<File> saveToAppDirectory(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
    final savedFile = await file.copy('${appDir.path}/$fileName');
    return savedFile;
  }
}
