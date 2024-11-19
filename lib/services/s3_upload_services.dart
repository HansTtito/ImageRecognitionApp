import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:ImageRecognition/functions/unique_name_generator.dart';

class S3ImagePickerUploadService {

  final ImagePicker _picker = ImagePicker();

  // Método para subir una sola imagen
  Future<void> uploadSingleImage({

    required BuildContext context,
    required String email,
    required String folderName,
    required XFile imageFile,
    required String subject,
    required Function(CustomImageInfo) onImageUploaded,
    
  }) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subiendo imagen...')),
        );
      }

      final customImageInfo = CustomImageInfo.fromXFile(imageFile);
      final file = File(imageFile.path);
      
      if (!await file.exists()) {
        throw Exception('El archivo no existe en la ruta especificada');
      }

      // Usar el servicio para subir la imagen
      final result = await uploadImage(
        email: email,
        file: file,
        fileName: customImageInfo.fileName,
        folderName: folderName,
        subject: subject
      );

      onImageUploaded(customImageInfo);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagen subida exitosamente: ${customImageInfo.fileName}')),
        );
      }
    } catch (e) {
      print('Error en uploadSingleImage: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir la imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow; // Relanzamos la excepción para que pueda ser manejada por el llamador
    }
  }

  // Método existente para seleccionar y subir múltiples imágenes
  Future<List<CustomImageInfo>> pickAndUploadImages({
    required BuildContext context,
    required String email,
    required String folderName,
    required String subject,
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
      for (var image in pickedImages) {
        try {
          final customImageInfo = CustomImageInfo.fromXFile(image);
          final file = File(image.path);
          if (!await file.exists()) {
            throw Exception('El archivo no existe en la ruta especificada');
          }
          // Usar el servicio para subir la imagen
          final result = await uploadImage(
            email: email,
            file: file,
            fileName: customImageInfo.fileName,
            folderName: folderName,
            subject: subject
          );
          uploadedImageNames.add(customImageInfo.fileName);
          uploadedImages.add(customImageInfo);
        } catch (e) {
          print('Error al subir imagen ${image.name}: $e');
        }
      }
      onImagesUploaded(uploadedImages);
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

  // Método existente para subir una imagen a S3
  Future<String> uploadImage({
    required File file,
    required String email,
    required String folderName,
    required String fileName,
    required String subject,
  }) async {
    try {
      final path = 'users/$email/$subject/$folderName/$fileName';
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
}