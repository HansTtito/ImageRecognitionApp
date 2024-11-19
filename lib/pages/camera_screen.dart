import 'package:ImageRecognition/services/s3_upload_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:ImageRecognition/functions/folder_handler.dart';
import 'package:ImageRecognition/functions/image_handler.dart';
import 'package:ImageRecognition/pages/camera_folder_screen.dart';
import 'package:ImageRecognition/functions/unique_name_generator.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  
  final String? email;
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras, required this.email});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late FolderHandlerService _folderHandlerService;
  late ImageHandlerService _imageHandler;
  late S3ImagePickerUploadService _imageUploadService;
  final ImagePicker _picker = ImagePicker();
  List<FolderData> folders = [];
  bool isCapturing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
    );
    
    _initializeControllerFuture = _controller.initialize();
    
    // Inicializar todos los servicios
    _folderHandlerService = FolderHandlerService();
    _imageUploadService = S3ImagePickerUploadService(); // Inicializar el servicio
    _imageHandler = ImageHandlerService(
      context: context,
      setUploadingState: (isUploading) => setState(() => isCapturing = isUploading),
      email: widget.email!,
      folderName: '',
    );
    
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final loadedFolders = await _folderHandlerService.loadExistingFolders(
        widget.email!,
        'Galeria',  // subject folder
        'Modelo'    // subject images
      );
      setState(() {
        folders = loadedFolders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las carpetas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 

  Future<void> _captureImage(int folderIndex) async {
    if (isCapturing) return;

    setState(() => isCapturing = true);
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Agregar compresión de imagen
        maxWidth: 1920,   // Limitar el tamaño máximo
        maxHeight: 1080,
      );
      
      if (photo != null) {
        if (!mounted) return;
        
        // Verificar el tamaño del archivo antes de subir
        final file = File(photo.path);
        final fileSize = await file.length();
        
        if (fileSize > 10 * 1024 * 1024) { // 10MB limit
          throw Exception('La imagen es demasiado grande. Por favor, intenta con una imagen más pequeña.');
        }

        await _imageUploadService.uploadSingleImage(
          email: widget.email!,
          context: context,
          subject: 'Modelo',
          folderName: folders[folderIndex].name,
          imageFile: photo,
          onImageUploaded: (imageInfo) {
            if (mounted) {
              setState(() {
                folders[folderIndex].images.add(imageInfo);
              });
            }
          },
        );
      } else {
        // El usuario canceló la captura
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Captura de imagen cancelada'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error detallado en _captureImage: $e'); // Log para debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar la imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isCapturing = false);
      }
    }
  }


  void _deleteImage(CustomImageInfo image, int folderIndex) async {
    try {
      await _folderHandlerService.deleteFolder(
        context: context,
        email: widget.email!,
        folderName: folders[folderIndex].name,
        subject: 'Modelo',
        onFolderDeleted: () {
          setState(() {
            folders[folderIndex].images.removeWhere((img) => img.fileName == image.fileName);
          });
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al eliminar la imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadImage(CustomImageInfo image) async {
    await _imageHandler.downloadImage(image);
  }

  void _updateImagesInFolder(int folderIndex, List<CustomImageInfo> updatedImages) {
    setState(() {
      folders[folderIndex].images = updatedImages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : folders.isEmpty
                      ? const Center(
                          child: Text('No hay carpetas disponibles'),
                        )
                      : ListView.builder(
                          itemCount: folders.length,
                          itemBuilder: (context, folderIndex) {
                            final folder = folders[folderIndex];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                title: Text(
                                  folder.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${folder.images.length} ${folder.images.length == 1 ? 'imagen' : 'imágenes'}',
                                ),
                                leading: const Icon(Icons.folder),
                                trailing: IconButton(
                                  icon: const Icon(Icons.camera_alt),
                                  onPressed: () => _captureImage(folderIndex),
                                  tooltip: 'Capturar imagen',
                                ),
                                onTap: () async {
                                  final updatedImages = await Navigator.push<List<CustomImageInfo>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CameraFolderScreen(
                                        email: widget.email!,
                                        folderName: folder.name,
                                        images: folder.images,
                                      ),
                                    ),
                                  );
                                  
                                  if (updatedImages != null) {
                                    _updateImagesInFolder(folderIndex, updatedImages);
                                  }
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        if (isCapturing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}