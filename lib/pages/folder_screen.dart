import 'package:flutter/material.dart';
import 'package:ImageRecognition/services/s3_upload_services.dart';
import 'package:ImageRecognition/services/s3_delete_services.dart';
import 'package:ImageRecognition/functions/unique_name_generator.dart';
import 'package:ImageRecognition/functions/image_handler.dart'; // Importa el servicio
import 'dart:io';

class FolderScreen extends StatefulWidget {
  final String folderName;
  final String email;
  final List<CustomImageInfo> images;

  const FolderScreen({
    super.key,
    required this.folderName,
    required this.images,
    required this.email,
  });

  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  
  late ImageHandlerService _imageHandlerService; // Instancia del servicio
  final S3ImagePickerUploadService _s3ServiceUpload = S3ImagePickerUploadService();
  final S3DeleteService _s3DeleteService = S3DeleteService();
  List<CustomImageInfo> _images = [];
  bool isUploading = false;

  @override
  void initState() {
    super.initState();

    // Inicializar la lista de imágenes
    _images = widget.images.map((image) => 
      CustomImageInfo(
        fileName: image.fileName,
        path: image.path,
        originalName: image.originalName,
      )
    ).toList();

    // Inicializar el servicio
    _imageHandlerService = ImageHandlerService(
      context: context,
      setUploadingState: (uploading) {
        setState(() {
          isUploading = uploading;
        });
      },
      email: widget.email,
      folderName: widget.folderName,
    );
  }

  void _onBackPressed() {
    Navigator.of(context).pop(_images);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackPressed,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () => _imageHandlerService.pickImages(
              onImagesUploaded: (images) {
                setState(() {
                  _images.addAll(images);
                });
              },
              s3ServiceUpload: _s3ServiceUpload,
              subject: 'Galeria',
            ),
            tooltip: 'Añadir imágenes',
          ),
        ],
      ),
      body: _images.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No hay imágenes en esta carpeta',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _imageHandlerService.pickImages(
                      onImagesUploaded: (images) {
                        setState(() {
                          _images.addAll(images);
                        });
                      },
                      s3ServiceUpload: _s3ServiceUpload,
                      subject: 'Galeria',
                    ),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Cargar imágenes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final image = _images[index];
                return GestureDetector(
                  onTap: () => _imageHandlerService.previewImage(image),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(image.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => _imageHandlerService.deleteImage(
                            image: image,
                            s3DeleteService: _s3DeleteService,
                            onImageDeleted: (fileName) {
                              setState(() {
                                _images.removeWhere((img) => img.fileName == fileName);
                              });
                            },
                            subject: 'Galeria',
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onBackPressed,
        child: const Icon(Icons.arrow_back),
      ),
    );
  }
}
