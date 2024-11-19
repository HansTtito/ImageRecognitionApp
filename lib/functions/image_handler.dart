// image_handler_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:ImageRecognition/functions/unique_name_generator.dart';
import 'package:ImageRecognition/services/s3_delete_services.dart';
import 'package:ImageRecognition/services/s3_upload_services.dart';

class ImageHandlerService {
  final BuildContext context;
  final Function(bool) setUploadingState;
  final String email;
  final String folderName;
  
  ImageHandlerService({
    required this.context,
    required this.setUploadingState,
    required this.email,
    required this.folderName,
  });

  void previewImage(CustomImageInfo image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Preview'),
            actions: [
              IconButton(
                icon: Icon(Icons.download),
                onPressed: () => downloadImage(image),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(image.path),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> downloadImage(CustomImageInfo image) async {
    try {
      if (Platform.isAndroid) {
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }
        if (!photosStatus.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photos permission is required'),
              action: SnackBarAction(
                label: 'Open Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
          return;
        }
      }

      final result = await ImageGallerySaverPlus.saveFile(
        image.path,
        name: image.originalName ?? 'downloaded_image',
      );

      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image downloaded successfully')),
        );
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error downloading image: $e');
    }
  }


  Future<void> pickImages({
    required Function(List<CustomImageInfo>) onImagesUploaded,
    required S3ImagePickerUploadService s3ServiceUpload,
    required String subject,
  }) async {
    try {
      // Indicate that uploading has started
      setUploadingState(true);

      // Use the S3 service to pick and upload images
      await s3ServiceUpload.pickAndUploadImages(
        context: context,
        email: email,
        folderName: folderName,
        subject: subject,
        onImagesUploaded: onImagesUploaded,
        setUploadingState: setUploadingState,
      );
    } catch (e) {
      print('Error while picking or uploading images: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar imágenes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Indicate that uploading has ended
      setUploadingState(false);
    }
  }


  Future<void> deleteImage({
    required CustomImageInfo image,
    required S3DeleteService s3DeleteService,
    required Function(String) onImageDeleted,
    required String subject
  }) async {
    try {
      await s3DeleteService.deleteImage(
        email: email,
        folderName: folderName,
        fileName: image.fileName,
        subject: subject
      );
      
      onImageDeleted(image.fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen eliminada exitosamente')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error al eliminar imagen: $e');
    }
  }
}