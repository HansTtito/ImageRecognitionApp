import 'package:amplify_flutter/amplify_flutter.dart';

class S3DeleteService {
  // Eliminar imagen de S3
  Future<void> deleteImage({
    required String email,
    required String folderName,
    required String fileName,
    required String subject,
  }) async {
    try {
      final key = StoragePath.fromString('users/$email/$subject/$folderName/$fileName');

      await Amplify.Storage.remove(
        path: key,
      ).result;
    } catch (e) {
      print('Error al eliminar imagen de S3: $e');
      rethrow;
    }
  }

  // Eliminar una carpeta completa de S3
  Future<void> deleteFolder({
    required String email,
    required String folderName,
    required String subject,
  }) async {
    try {
      
      final path = StoragePath.fromString('users/$email/$subject/$folderName/');

      final result = await Amplify.Storage.list(
        path: path,
        options: const StorageListOptions(pageSize: 1000),
      ).result;

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
}
