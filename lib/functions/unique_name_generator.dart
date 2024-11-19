import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

String generateUniqueFileName(String originalFileName) {
  final uuid = Uuid();
  final extension = path.extension(originalFileName); // Obtiene la extensión (.jpg, .png, etc)
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final uniqueId = uuid.v4().substring(0, 8); // Usando solo los primeros 8 caracteres del UUID
  
  // Formato: timestamp_uuid_originalname.extension
  return '${timestamp}_${uniqueId}_${path.basenameWithoutExtension(originalFileName)}$extension';
}

// CustomImageInfo.dart (actualizar o crear si no existe)
class CustomImageInfo {
  final String fileName;    // Nombre del archivo en S3
  final String path;        // Ruta local o URL
  final String originalName;

  CustomImageInfo({
    required this.fileName,
    required this.path,
    required this.originalName,
  });

  // Constructor para crear desde datos de S3
  factory CustomImageInfo.fromS3Item(item) {
    final pathParts = item.key.split('/');
    final fileName = pathParts.last;
    return CustomImageInfo(
      fileName: fileName,
      path: item.path,
      originalName: fileName,
    );
  }

  // Constructor para crear desde XFile
  factory CustomImageInfo.fromXFile(XFile file) {
    final uniqueName = generateUniqueFileName(file.name);
    return CustomImageInfo(
      fileName: uniqueName,
      path: file.path,
      originalName: file.name,
    );
  }
}


class FolderData {
  final String name;
  List<CustomImageInfo> images;

  FolderData({
    required this.name,
    required this.images,
  });
}