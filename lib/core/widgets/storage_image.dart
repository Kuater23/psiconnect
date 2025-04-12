// lib/core/widgets/storage_image.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class StorageImage extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  
  const StorageImage({
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    Key? key,
  }) : super(key: key);
  
  @override
  State<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends State<StorageImage> {
  String? _imageUrl;
  bool _isLoading = true;
  Object? _error;
  StackTrace? _stackTrace;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  Future<void> _loadImage() async {
    try {
      print('⭐ Intentando cargar imagen: ${widget.imagePath}');
      
      // Usar bucket específico en lugar del default
      final storage = FirebaseStorage.instanceFor(
        bucket: 'gs://psiconnect-eb98a.firebasestorage.app'
      );
      
      final ref = storage.ref().child(widget.imagePath);
      print('⭐ Referencia creada, obteniendo URL...');
      
      final url = await ref.getDownloadURL();
      print('⭐ URL obtenida: $url');
      
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ ERROR cargando imagen ${widget.imagePath}: $e');
      print('❌ Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e;
          _stackTrace = stackTrace;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_imageUrl == null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error ?? 'Failed to load image', _stackTrace);
      }
      
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Icon(Icons.error_outline, color: Colors.red),
      );
    }
    
    return Image.network(
      _imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: widget.errorBuilder ?? (context, error, stackTrace) {
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.red),
        );
      },
    );
  }
}