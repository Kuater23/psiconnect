import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PatientDocumentsService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<String> uploadBytes({
    required String patientId,
    required String doctorId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'application/octet-stream',
    String? description,
  }) async {
    final storagePath = 'patient_documents/$patientId/$fileName';
    final ref = _storage.ref(storagePath);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));

    final doc = await _db.collection('patient_documents').add({
      'patientId': patientId,
      'doctorId': doctorId,
      'fileName': fileName,
      'storagePath': storagePath,
      'contentType': contentType,
      'description': description,
      'size': bytes.length,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamByPatient(String patientId) {
    return _db
        .collection('patient_documents')
        .where('patientId', isEqualTo: patientId)
        .orderBy('uploadedAt', descending: true)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (s, _) => s.data() ?? {},
          toFirestore: (d, _) => d,
        )
        .snapshots();
  }

  Future<void> delete({
    required String documentId,
    required String storagePath,
  }) async {
    await _storage.ref(storagePath).delete();
    await _db.collection('patient_documents').doc(documentId).delete();
  }

  Future<String> downloadUrl(String storagePath) =>
      _storage.ref(storagePath).getDownloadURL();
}