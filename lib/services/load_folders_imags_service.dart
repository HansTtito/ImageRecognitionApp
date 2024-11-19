import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:ImageRecognition/functions/unique_name_generator.dart';
import 'package:path_provider/path_provider.dart';  // Para obtener el directorio local
import 'dart:io';


class StorageService {
  
  Future<List<CustomImageInfo>> loadFolderImages(String email, String folderName, String subject) async {
    try {
      final folderPath = 'users/$email/$subject/$folderName/';
      final storagePath = StoragePath.fromString(folderPath);
      final List<CustomImageInfo> images = [];

      // List items in the folder
      final result = await Amplify.Storage.list(
        path: storagePath,
        options: const StorageListOptions(pageSize: 1000),
      ).result;

      // Create the local directory if it doesn't exist
      final directory = await getApplicationDocumentsDirectory();
      final folderDirectory = Directory('${directory.path}/$subject/$folderName');
      if (!await folderDirectory.exists()) {
        await folderDirectory.create(recursive: true);
      }

      // Download images
      for (var item in result.items) {
        try {
          String originalName = item.path.split('/').last;
          final localFile = File('${folderDirectory.path}/$originalName');
          
          // Check if file already exists locally
          if (!await localFile.exists()) {
            final pathItem = StoragePath.fromString(item.path);
            
            // Download the file
            await Amplify.Storage.downloadFile(
              path: pathItem,
              localFile: AWSFile.fromPath(localFile.path),
              onProgress: (progress) {
                // Optional: Add progress handling here
                print('Download progress: ${progress.fractionCompleted}');
              },
            ).result;
          }

          // Only add to the list if the file exists locally
          if (await localFile.exists()) {
            images.add(CustomImageInfo(
              fileName: originalName,
              path: localFile.path, // Use local path instead of S3 path
              originalName: originalName,
            ));
          }
        } catch (itemError) {
          print('Error downloading individual file: ${item.path}');
          print(itemError);
          // Continue with the next file instead of failing completely
          continue;
        }
      }

      return images;
    } catch (e) {
      print('Error loading folder images: $e');
      return [];
    }
  }

  Future<List<String>> listFolders(String email, String subject) async {
    try {
      final userPath = 'users/$email/$subject';
      final storagePath = StoragePath.fromString(userPath);
      
      final result = await Amplify.Storage.list(
        path: storagePath,
        options: const StorageListOptions(pageSize: 1000),
      ).result;

      // Extract unique folder names
      Set<String> folderNames = {};
      for (var item in result.items) {
        final parts = item.path.split('/');
        if (parts.length > 3) {
          folderNames.add(parts[3]);
        }
      }
      
      return folderNames.toList();
    } catch (e) {
      print('Error listing folders: $e');
      return [];
    }
  }

  // Helper method to clean up old cached files
  Future<void> cleanupOldFiles(int maxAgeInDays) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final contents = directory.listSync(recursive: true);
      final now = DateTime.now();

      for (var fileEntity in contents) {
        if (fileEntity is File) {
          final lastModified = await fileEntity.lastModified();
          final age = now.difference(lastModified).inDays;

          if (age > maxAgeInDays) {
            await fileEntity.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old files: $e');
    }
  }
}