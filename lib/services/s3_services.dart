import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:ImageRecognition/functions/unique_name_generator.dart';

class S3Service {
  // Singleton pattern
  static final S3Service _instance = S3Service._internal();
  factory S3Service() => _instance;
  S3Service._internal();

  final ImagePicker _picker = ImagePicker();


   // Nuevo método para seleccionar y subir imágenes
  Future<List<CustomImageInfo>> pickAndUploadImages({
    required BuildContext context,
    required String email,
    required String folderName,
    required Function(List<CustomImageInfo>) onImagesUploaded,
    required Function(bool) setUploadingState,
  }) async {
    List<CustomImageInfo> uploadedImages = [];

    try {
      setUploadingState(true);
      
      final List<XFile>? pickedImages = await _picker.pickMultiImage();
      
      if (pickedImages == null || pickedImages.isEmpty) {
        return [];
      }

      List<String> uploadedImageNames = [];

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subiendo imágenes...')),
        );
      }

      // Subir imágenes
      for (var image in pickedImages) {
        try {
          final customImageInfo = CustomImageInfo.fromXFile(image);
          final file = File(image.path);

          if (!await file.exists()) {
            throw Exception('El archivo no existe en la ruta especificada');
          }

          // Usar el método existente para subir la imagen
          final result = await uploadImage(
            email: email,
            file: file,
            fileName: customImageInfo.fileName,
            folderName: folderName,
          );

          uploadedImageNames.add(customImageInfo.fileName);
          uploadedImages.add(customImageInfo);

        } catch (e) {
          print('Error al subir imagen ${image.name}: $e');
        }
      }

      // Llamar al callback con las imágenes subidas
      onImagesUploaded(uploadedImages);

      // Mostrar SnackBar con los nombres de las imágenes subidas
      if (context.mounted) {
        final snackBarMessage = uploadedImageNames.isNotEmpty
            ? 'Imágenes subidas exitosamente: ${uploadedImageNames.join(", ")}'
            : 'No se subieron imágenes exitosamente';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snackBarMessage)),
        );
      }

    } catch (e) {
      print('Error en pickAndUploadImages: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar las imágenes')),
        );
      }
    } finally {
      setUploadingState(false);
    }

    return uploadedImages;
  }

  // Upload image to S3 and return the uploaded file key
  Future<String> uploadImage({
    required File file,
    required String email,
    required String folderName,
    required String fileName,
  }) async {
    try {

      final path = 'users/$email/$folderName/$fileName';
      final s3Path = StoragePath.fromString(path);

      final options = StorageUploadFileOptions(
        metadata: {
          'contentType': 'image/jpeg',
          'userEmail': email,
          'folderName': folderName,
        },
      );

      await Amplify.Storage.uploadFile(
        path: s3Path,
        localFile: AWSFile.fromPath(file.path),
        options: options,
      ).result;

      return path;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }



  // Delete a specific image
  Future<void> deleteImage({
    required String email,
    required String folderName,
    required String fileName,
  }) async {
    try {
      final key = StoragePath.fromString('users/$email/$folderName/$fileName');
      await Amplify.Storage.remove(
        path: key,
      ).result;
    } catch (e) {
      print('Error al eliminar imagen de S3: $e');
      rethrow;
    }
  }

  // Delete an entire folder
  Future<void> deleteFolder({
    required String email,
    required String folderName,
  }) async {
    try {
      // List all files in the folder
      final path = StoragePath.fromString('users/$email/$folderName/');
      final result = await Amplify.Storage.list(
        path: path,
        options: const StorageListOptions(
          pageSize: 1000,
        ),
      ).result;

      // Delete each file in the folder
      for (final item in result.items) {
        await Amplify.Storage.remove(
          path: StoragePath.fromString(item.path),
          options: const StorageRemoveOptions(),
        ).result;
      }

    } catch (e) {
      throw Exception('Error deleting folder: $e');
    }
  }

  // List images in a folder 
  Future<List<String>> listImagesInFolder({
    required String email,
    required String folderName,
  }) async {
    try {
      final path = 'users/$email/$folderName/';
      final result = await Amplify.Storage.list(
        path: StoragePath.fromString(path),
        options: const StorageListOptions(
          pageSize: 1000,
        ),
      ).result;
      
      // Convert StorageItem to String paths
      return result.items.map((item) => item.path).toList();
    } catch (e) {
      throw Exception('Error listing images: $e');
    }
  }

  // Method to sync local images with S3
  Future<void> syncImagesWithS3({
    required String email,
    required String folderName,
    required List<XFile> localImages,
    required Function(List<XFile>) updateLocalImages,
  }) async {
    try {
      // Get list of images in S3
      final s3ImagePaths = await listImagesInFolder(
        email: email,
        folderName: folderName,
      );

      // Create a map of filenames for quick comparison
      final s3ImageNames = s3ImagePaths.map((path) => path.split('/').last).toSet();
      
      // Filter local images that no longer exist in S3
      final updatedLocalImages = localImages.where((localImage) {
        final fileName = localImage.name;
        return s3ImageNames.contains(fileName);
      }).toList();

      // Update the local list
      updateLocalImages(updatedLocalImages);
    } catch (e) {
      throw Exception('Error syncing images: $e');
    }
  }

  // Method to get the download URL of an image
  Future<String> getImageDownloadUrl({
    required String email,
    required String folderName,
    required String fileName,
  }) async {
    try {
      final path = 'users/$email/$folderName/$fileName';
      final s3Path = StoragePath.fromString(path);
      final result = await Amplify.Storage.getUrl(
        path: s3Path,
      ).result;
      return result.url.toString();
    } catch (e) {
      throw Exception('Error getting download URL: $e');
    }
  }
}