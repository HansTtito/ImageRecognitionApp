import 'package:flutter/material.dart';
import 'package:ImageRecognition/services/s3_upload_services.dart';
import 'package:ImageRecognition/functions/unique_name_generator.dart';
import 'package:ImageRecognition/services/load_folders_imags_service.dart';
import 'package:ImageRecognition/services/s3_delete_services.dart';

class FolderHandlerService {
  final S3ImagePickerUploadService _uploadService = S3ImagePickerUploadService();
  final S3DeleteService _s3ServiceRemove = S3DeleteService();
  final StorageService _storageService = StorageService();

  Future<List<FolderData>> loadExistingFolders(String email, String subjectFolder, String subjectImages) async {
    try {
      // Obtener lista de carpetas
      final folderNames = await _storageService.listFolders(email, subjectFolder);

      // Cargar imágenes para cada carpeta
      final loadedFolders = await Future.wait(
        folderNames.map((folderName) async {
          final images = await _storageService.loadFolderImages(email, folderName, subjectImages);
          return FolderData(name: folderName, images: images);
        }),
      );

      return loadedFolders;
    } catch (e) {
      print('Error loading folders: $e');
      throw Exception('Error al cargar las carpetas');
    }
  }

  Future<void> pickImagesFromGallery({
    required BuildContext context,
    required String email,
    required int folderIndex,
    required String folderName,
    required String subject,
    required Function(List<CustomImageInfo>) onImagesUploaded,
    required Function(bool) setUploadingState,
  }) async {
    await _uploadService.pickAndUploadImages(
      context: context,
      email: email,
      subject: subject,
      folderName: folderName,
      onImagesUploaded: onImagesUploaded,
      setUploadingState: setUploadingState,
    );
  }

  bool folderExists(List<FolderData> folders, String name) {
    return folders.any(
      (folder) => folder.name.toLowerCase() == name.toLowerCase(),
    );
  }

  Future<void> createFolder({
    required BuildContext context,
    required String folderName,
    required String email,
    required List<FolderData> folders,
    required Function(FolderData) onFolderCreated,
  }) async {
    if (folderExists(folders, folderName)) {
      throw Exception('Ya existe una carpeta con este nombre');
    }

    // Agregar carpeta localmente
    final newFolder = FolderData(name: folderName, images: []);
    onFolderCreated(newFolder);
  }

  Future<void> deleteFolder({
    required BuildContext context,
    required String email,
    required String folderName,
    required String subject,
    required Function() onFolderDeleted,
  }) async {
    try {
      await _s3ServiceRemove.deleteFolder(email: email, folderName: folderName, subject: subject);
      onFolderDeleted();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carpeta eliminada exitosamente')),
      );
    } catch (e) {
      print('Error deleting folder: $e');
      throw Exception('Error al eliminar la carpeta');
    }
  }

  void updateImagesInFolder({
    required List<FolderData> folders,
    required int folderIndex,
    required List<CustomImageInfo> updatedImages,
    required Function(List<FolderData>) onUpdate,
  }) {
    folders[folderIndex].images = updatedImages;
    onUpdate(folders);
  }
}
