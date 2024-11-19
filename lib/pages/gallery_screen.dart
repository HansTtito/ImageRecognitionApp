// gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ImageRecognition/pages/folder_screen.dart';
import 'package:ImageRecognition/functions/unique_name_generator.dart';
import 'package:ImageRecognition/functions/folder_handler.dart';

class GalleryScreen extends StatefulWidget {
  final String? email;
  
  const GalleryScreen({super.key, required this.email});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {

  late FolderHandlerService _folderHandlerService;
  List<FolderData> folders = [];
  bool isUploading = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _folderHandlerService = FolderHandlerService();
    _loadInitialFolders();
  }

  Future<void> _loadInitialFolders() async {
    try {
      final loadedFolders = await _folderHandlerService.loadExistingFolders(
        widget.email!,
        'Galeria',  // subject folder
        'Galeria'    // subject images
      );
      setState(() {
        folders = loadedFolders;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar las carpetas')),
        );
      }
    }
  }

  void _pickImagesFromGallery(int index) {
    _folderHandlerService.pickImagesFromGallery(
      context: context,
      email: widget.email!,
      folderIndex: index,
      folderName: folders[index].name,
      subject: 'Galeria',
      onImagesUploaded: (newImages) {
        setState(() {
          folders[index].images.addAll(newImages);
        });
      },
      setUploadingState: (uploading) {
        setState(() => isUploading = uploading);
      },
    );
  }

  Future<void> _createFolder() async {
    final TextEditingController folderNameController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Carpeta'),
        content: TextField(
          controller: folderNameController,
          decoration: const InputDecoration(
            hintText: 'Nombre de la carpeta',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final name = folderNameController.text.trim();
              if (name.isEmpty) return;
              
              try {
                await _folderHandlerService.createFolder(
                  context: context,
                  folderName: name,
                  email: widget.email!,
                  folders: folders,
                  onFolderCreated: (newFolder) {
                    setState(() => folders.add(newFolder));
                  },
                );
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFolder(int index) async {
    try {
      // Ejecutar ambas eliminaciones en paralelo
      await Future.wait([
        _folderHandlerService.deleteFolder(
          context: context,
          email: widget.email!,
          folderName: folders[index].name,
          subject: 'Galeria',
          onFolderDeleted: () {
            setState(() => folders.removeAt(index));
          },
        ),
        _folderHandlerService.deleteFolder(
          context: context,
          email: widget.email!,
          folderName: folders[index].name,
          subject: 'Modelo',
          onFolderDeleted: () {
            setState(() => folders.removeAt(index));
          },
        ),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la carpeta')),
        );
      }
    }
  }


  void _updateImagesInFolder(int index, List<CustomImageInfo> updatedImages) {
    _folderHandlerService.updateImagesInFolder(
      folders: folders,
      folderIndex: index,
      updatedImages: updatedImages,
      onUpdate: (updatedFolders) {
        setState(() => folders = updatedFolders);
      },
    );
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
                  ? const Center(child: Text('No hay carpetas creadas'))
                  : ListView.builder(
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add_photo_alternate),
                                  onPressed: () => _pickImagesFromGallery(index),
                                  tooltip: 'Añadir imágenes',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteFolder(index),
                                  tooltip: 'Eliminar carpeta',
                                ),
                              ],
                            ),
                            onTap: () async {
                              final updatedImages = await Navigator.push<List<CustomImageInfo>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FolderScreen(
                                    email: widget.email!,
                                    folderName: folder.name,
                                    images: folder.images,
                                  ),
                                ),
                              );
                              
                              if (updatedImages != null) {
                                _updateImagesInFolder(index, updatedImages);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        if (isUploading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        Positioned(
          right: 16.0,
          bottom: 16.0,
          child: FloatingActionButton(
            onPressed: _createFolder,
            child: const Icon(Icons.create_new_folder),
            tooltip: 'Crear nueva carpeta',
          ),
        ),
      ],
    );
  }
}