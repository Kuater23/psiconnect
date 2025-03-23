// lib/features/professional/screens/patient_medical_records.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '/navigation/shared_drawer.dart';
import '/core/widgets/responsive_widget.dart';
import '/core/constants/app_constants.dart';
import '/core/services/error_logger.dart';

/// Patient medical records screen
/// Allows professionals to view and manage patient medical records
class PatientMedicalRecords extends StatefulWidget {
  final String professionalId;
  final String patientId;
  final String? patientName;
  final VoidCallback toggleTheme;
  
  const PatientMedicalRecords({
    Key? key,
    required this.professionalId,
    required this.patientId,
    this.patientName,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<PatientMedicalRecords> createState() => _PatientMedicalRecordsState();
}

class _PatientMedicalRecordsState extends State<PatientMedicalRecords> with SingleTickerProviderStateMixin {
  // State variables
  int _currentTab = 0;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de ${widget.patientName ?? 'Paciente'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Historial Clínico', icon: Icon(Icons.history_edu)),
            Tab(text: 'Documentos', icon: Icon(Icons.folder)),
            Tab(text: 'Subir Archivos', icon: Icon(Icons.upload_file)),
          ],
        ),
      ),      
      drawer: SharedDrawer(),
      body: Column(
        children: [
          // Patient information card
          _buildPatientInfoCard(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMedicalHistoryTab(),
                _buildDocumentsTab(),
                _buildUploadTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentTab == 2
          ? FloatingActionButton(
              onPressed: () => _pickAndUploadFile(),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add),
              tooltip: 'Subir Archivo',
            )
          : null,
    );
  }
  
  /// Build patient information card
  Widget _buildPatientInfoCard() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'No se encontró información del paciente',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['firstName'] ?? ''; // Cambiar de 'name' a 'firstName'
        final lastName = data['lastName'] ?? '';
        final email = data['email'] ?? '';
        final phone = data['phoneN'] ?? ''; // Cambiar de 'phone' a 'phoneN'
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name $lastName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Paciente',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(email),
                            const SizedBox(width: 24),
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(phone),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Build medical history tab content
  Widget _buildMedicalHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medical_history')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error al cargar historial: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        
        final entries = snapshot.data?.docs ?? [];
        
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_edu, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No hay entradas en el historial clínico',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir entrada al historial'),
                  onPressed: () => _addHistoryEntry(),
                ),
              ],
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historial Clínico',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva Entrada'),
                    onPressed: () => _addHistoryEntry(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index].data() as Map<String, dynamic>;
                    final entryId = entries[index].id;
                    return _buildHistoryEntryCard(entry, entryId);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Build medical history entry card
  Widget _buildHistoryEntryCard(Map<String, dynamic> entry, String entryId) {
    final title = entry['title'] ?? 'Entrada sin título';
    final content = entry['content'] ?? '';
    final createdAt = entry['createdAt'] as Timestamp?;
    final createdBy = entry['createdBy'] ?? '';
    final tags = (entry['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    
    final formattedDate = createdAt != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
        : 'Fecha desconocida';
    
    // Color for the card accent
    Color cardAccent = Colors.blue;
    if (tags.contains('Urgente')) cardAccent = Colors.red;
    else if (tags.contains('Seguimiento')) cardAccent = Colors.orange;
    else if (tags.contains('Tratamiento')) cardAccent = Colors.green;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardAccent.withOpacity(0.5), width: 1),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showHistoryEntryDetails(entry, entryId),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showHistoryEntryOptions(entry, entryId),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formattedDate,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.map((tag) => _buildTagChip(tag)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// Build tag chip for medical history entries
  Widget _buildTagChip(String tag) {
    Color tagColor;
    switch (tag.toLowerCase()) {
      case 'urgente':
        tagColor = Colors.red;
        break;
      case 'seguimiento':
        tagColor = Colors.orange;
        break;
      case 'tratamiento':
        tagColor = Colors.green;
        break;
      case 'diagnóstico':
        tagColor = Colors.purple;
        break;
      default:
        tagColor = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tagColor.withOpacity(0.5)),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: tagColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// Show history entry details dialog
  void _showHistoryEntryDetails(Map<String, dynamic> entry, String entryId) {
    final title = entry['title'] ?? 'Entrada sin título';
    final content = entry['content'] ?? '';
    final createdAt = entry['createdAt'] as Timestamp?;
    final createdBy = entry['createdBy'] ?? '';
    final tags = (entry['tags'] as List<dynamic>?)?.cast<String>() ?? [];
    
    final formattedDate = createdAt != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
        : 'Fecha desconocida';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fecha: $formattedDate'),
              const SizedBox(height: 16),
              
              if (tags.isNotEmpty) ...[
                const Text(
                  'Etiquetas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) => _buildTagChip(tag)).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              const Text(
                'Contenido:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(content),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (createdBy == widget.professionalId)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _editHistoryEntry(entry, entryId);
              },
              child: const Text('Editar'),
            ),
        ],
      ),
    );
  }
  
  /// Show entry options menu
  void _showHistoryEntryOptions(Map<String, dynamic> entry, String entryId) {
    final createdBy = entry['createdBy'] ?? '';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(entry['title'] ?? 'Opciones de entrada'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('Ver Detalles'),
              onTap: () {
                Navigator.pop(context);
                _showHistoryEntryDetails(entry, entryId);
              },
            ),
            if (createdBy == widget.professionalId) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.green),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _editHistoryEntry(entry, entryId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteHistoryEntry(entryId);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Add new history entry
  void _addHistoryEntry() {
    _showHistoryEntryDialog(isEditing: false);
  }
  
  /// Edit existing history entry
  void _editHistoryEntry(Map<String, dynamic> entry, String entryId) {
    _showHistoryEntryDialog(
      isEditing: true,
      entryId: entryId,
      initialData: entry,
    );
  }
  
  /// Delete history entry
  void _deleteHistoryEntry(String entryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Entrada'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta entrada del historial? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await FirebaseFirestore.instance
                    .collection('medical_history')
                    .doc(entryId)
                    .delete();
                    
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entrada eliminada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
  
  /// Show history entry dialog for adding or editing
  void _showHistoryEntryDialog({
    required bool isEditing,
    String? entryId,
    Map<String, dynamic>? initialData,
  }) {
    final titleController = TextEditingController(
      text: initialData?['title'] ?? '',
    );
    final contentController = TextEditingController(
      text: initialData?['content'] ?? '',
    );
    final tagController = TextEditingController();
    
    final selectedTags = <String>[]; 
    if (initialData != null && initialData['tags'] != null) {
      selectedTags.addAll(
        (initialData['tags'] as List<dynamic>).cast<String>(),
      );
    }
    
    // Common tag options
    final commonTags = [
      'Diagnóstico', 'Tratamiento', 'Seguimiento', 'Urgente',
      'Medicación', 'Evaluación', 'Consulta',
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void addTag(String tag) {
            if (tag.isNotEmpty && !selectedTags.contains(tag)) {
              setState(() {
                selectedTags.add(tag);
                tagController.clear();
              });
            }
          }
          
          void removeTag(String tag) {
            setState(() {
              selectedTags.remove(tag);
            });
          }
          
          return AlertDialog(
            title: Text(isEditing ? 'Editar Entrada' : 'Nueva Entrada'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Contenido',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Etiquetas:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: commonTags.map((tag) => FilterChip(
                      label: Text(tag),
                      selected: selectedTags.contains(tag),
                      onSelected: (selected) {
                        if (selected) addTag(tag); else removeTag(tag);
                      },
                    )).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tagController,
                          decoration: const InputDecoration(
                            labelText: 'Etiqueta personalizada',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (value) => addTag(value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => addTag(tagController.text),
                      ),
                    ],
                  ),
                  
                  if (selectedTags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Etiquetas seleccionadas:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedTags.map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => removeTag(tag),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();
                  
                  if (title.isEmpty || content.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, completa todos los campos'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  try {
                    final data = {
                      'title': title,
                      'content': content,
                      'patientId': widget.patientId,
                      'tags': selectedTags,
                      'createdBy': widget.professionalId,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    
                    if (isEditing && entryId != null) {
                      await FirebaseFirestore.instance
                          .collection('medical_history')
                          .doc(entryId)
                          .update(data);
                          
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entrada actualizada correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // Add createdAt only for new entries
                      data['createdAt'] = FieldValue.serverTimestamp();
                      
                      await FirebaseFirestore.instance
                          .collection('medical_history')
                          .add(data);
                          
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entrada añadida correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(isEditing ? 'Actualizar' : 'Guardar'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  /// Build documents tab content
  Widget _buildDocumentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patient_documents')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar documentos: ${snapshot.error}'),
          );
        }
        
        final documents = snapshot.data?.docs ?? [];
        
        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No hay documentos disponibles',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Cargar Archivo'),
                  onPressed: () {
                    _tabController.animateTo(2); // Switch to upload tab
                  },
                ),
              ],
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Documentos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Cargar Archivo'),
                    onPressed: () {
                      _tabController.animateTo(2); // Switch to upload tab
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    
                    return _buildDocumentListItem(data, docId);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Build document list item
  Widget _buildDocumentListItem(Map<String, dynamic> data, String docId) {
    final fileName = data['fileName'] ?? 'Documento sin nombre';
    final fileType = data['fileType'] ?? '';
    final uploadedAt = data['uploadedAt'] as Timestamp?;
    final description = data['description'] ?? '';
    
    final formattedDate = uploadedAt != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(uploadedAt.toDate())
        : 'Fecha desconocida';
    
    // Determine icon based on file type
    IconData fileIcon;
    Color iconColor;
    
    if (fileType.contains('pdf')) {
      fileIcon = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (fileType.contains('image') || fileType.contains('jpg') || 
               fileType.contains('jpeg') || fileType.contains('png')) {
      fileIcon = Icons.image;
      iconColor = Colors.green;
    } else if (fileType.contains('doc')) {
      fileIcon = Icons.description;
      iconColor = Colors.blue;
    } else {
      fileIcon = Icons.insert_drive_file;
      iconColor = Colors.orange;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(fileIcon, color: iconColor),
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate),
            if (description.isNotEmpty)
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () => _viewDocument(data),
              tooltip: 'Ver',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showDocumentOptions(data, docId),
              tooltip: 'Opciones',
            ),
          ],
        ),
        onTap: () => _viewDocument(data),
      ),
    );
  }
  
  /// Show document options in bottom sheet
  void _showDocumentOptions(Map<String, dynamic> data, String docId) {
    final uploadedBy = data['uploadedBy'] ?? '';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(data['fileName'] ?? 'Opciones del documento'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('Ver Documento'),
              onTap: () {
                Navigator.pop(context);
                _viewDocument(data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('Descargar'),
              onTap: () {
                Navigator.pop(context);
                _downloadDocument(data);
              },
            ),
            if (uploadedBy == widget.professionalId) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Editar Descripción'),
                onTap: () {
                  Navigator.pop(context);
                  _editDocumentDescription(data, docId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteDocument(data, docId);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// View document in external viewer
  void _viewDocument(Map<String, dynamic> data) {
    final fileUrl = data['fileUrl'] as String?;
    final fileName = data['fileName'] as String?;
    
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL del archivo no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // For web app, open the URL in a new tab
    launchURL(fileUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Abriendo $fileName')),
    );
  }
  
  /// Download document
  void _downloadDocument(Map<String, dynamic> data) {
    final fileUrl = data['fileUrl'] as String?;
    final fileName = data['fileName'] as String?;
    
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL del archivo no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // For web app, trigger download
    launchURL(fileUrl);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Descargando $fileName')),
    );
  }
  
  /// Launch URL in browser
  void launchURL(String url) {
    // For a real implementation, you would use url_launcher package
    debugPrint('Launching URL: $url');
  }
  
  /// Edit document description
  void _editDocumentDescription(Map<String, dynamic> data, String docId) {
    final descriptionController = TextEditingController(
      text: data['description'] ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Descripción'),
        content: TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('patient_documents')
                    .doc(docId)
                    .update({
                      'description': descriptionController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Descripción actualizada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  /// Delete document
  void _deleteDocument(Map<String, dynamic> data, String docId) {
    final fileUrl = data['fileUrl'] as String?;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Documento'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este documento? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Delete file from storage if URL exists
                if (fileUrl != null && fileUrl.isNotEmpty) {
                  try {
                    final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
                    await storageRef.delete();
                  } catch (e) {
                    // Continue even if storage delete fails
                    ErrorLogger.logError(
                      'Error deleting file from storage', 
                      e, 
                      StackTrace.current,
                    );
                  }
                }
                
                // Delete document from Firestore
                await FirebaseFirestore.instance
                    .collection('patient_documents')
                    .doc(docId)
                    .delete();
                    
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Documento eliminado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
  
  /// Build upload tab content
  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cargar Archivos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Instructions card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Instrucciones para cargar archivos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('1. Presiona el botón "+" para seleccionar un archivo.'),
                  const SizedBox(height: 8),
                  const Text('2. Añade una descripción para el archivo (opcional).'),
                  const SizedBox(height: 8),
                  const Text('3. El archivo se subirá y estará disponible en la pestaña Documentos.'),
                  const SizedBox(height: 16),
                  const Text(
                    'Formatos compatibles:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: const Text('PDF'),
                        backgroundColor: Colors.red.shade100,
                        labelStyle: TextStyle(color: Colors.red.shade700),
                      ),
                      Chip(
                        label: const Text('DOC/DOCX'),
                        backgroundColor: Colors.blue.shade100,
                        labelStyle: TextStyle(color: Colors.blue.shade700),
                      ),
                      Chip(
                        label: const Text('JPG/PNG'),
                        backgroundColor: Colors.green.shade100,
                        labelStyle: TextStyle(color: Colors.green.shade700),
                      ),
                      Chip(
                        label: const Text('TXT'),
                        backgroundColor: Colors.purple.shade100,
                        labelStyle: TextStyle(color: Colors.purple.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Importante: El tamaño máximo de archivo es de 10MB.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Upload progress
          if (_isUploading) ...[
            const Text(
              'Subiendo archivo...',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 16),
            Text(
              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
          ],
          
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Upload area
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
            ),
            child: InkWell(
              onTap: () => _pickAndUploadFile(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Haz clic para seleccionar un archivo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'o arrastra y suelta aquí',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Alternative button
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Seleccionar Archivo'),
              onPressed: () => _pickAndUploadFile(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Pick and upload file
  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        
        // Check file size (max 10MB)
        final fileSize = file.size;
        if (fileSize > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El archivo excede el límite de 10MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Show description dialog
        final description = await _showDescriptionDialog();
        if (description == null) return; // User cancelled
        
        // Update upload state
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
          _errorMessage = null;
        });
        
        if (file.path != null) {
          await _uploadFile(
            File(file.path!),
            fileName,
            description,
          );
        } else {
          throw Exception('No se pudo acceder al archivo seleccionado');
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error al subir archivo: $e';
      });
      ErrorLogger.logError(
        'Error al subir archivo', 
        e, 
        StackTrace.current,
      );
    }
  }
  
  /// Show description dialog
  Future<String?> _showDescriptionDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descripción del Archivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Añade una descripción opcional para este archivo:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Descripción (opcional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Subir'),
          ),
        ],
      ),
    );
  }
  
  /// Upload file to Firebase Storage
  Future<void> _uploadFile(
    File file,
    String fileName,
    String description,
  ) async {
    try {
      // Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('patient_documents')
          .child(widget.patientId)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
      
      // Upload with progress tracking
      final uploadTask = storageRef.putFile(file);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });
      
      // Wait for upload to complete
      await uploadTask.whenComplete(() {});
      
      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection('patient_documents').add({
        'patientId': widget.patientId,
        'professionalId': widget.professionalId,
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'fileType': path.extension(fileName).toLowerCase(),
        'description': description,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': widget.professionalId,
      });
      
      // Update UI
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archivo subido correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Switch to documents tab
      _tabController.animateTo(1); // Documents tab
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error al subir archivo: $e';
      });
      ErrorLogger.logError(
        'Error al subir archivo', 
        e, 
        StackTrace.current,
      );
    }
  }
}