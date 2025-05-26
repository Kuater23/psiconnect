import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtiene los datos del usuario dado un [uid], buscando en las colecciones
  /// 'patients' y 'doctors'. Retorna un [Map<String, dynamic>] si se encuentra
  /// el documento o `null` en caso contrario.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      // Se intenta obtener el documento del usuario en la colección 'patients'.
      DocumentSnapshot patientDoc = await _db.collection('patients').doc(uid).get();
      if (patientDoc.exists) {
        return patientDoc.data() as Map<String, dynamic>?;
      }

      // Si no se encontró en 'patients', se busca en 'doctors'.
      DocumentSnapshot doctorDoc = await _db.collection('doctors').doc(uid).get();
      if (doctorDoc.exists) {
        return doctorDoc.data() as Map<String, dynamic>?;
      }

      // Si el documento no existe en ninguna de las colecciones, se retorna null.
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  /// Actualiza los datos del usuario en la colección especificada por [role].
  /// Se utiliza [SetOptions(merge: true)] para no sobrescribir datos previos.
  Future<void> updateUserData(
    String uid,
    String name,
    String lastName,
    String address,
    String phone,
    String? email,
    String dni,
    String n_matricula,
    String? specialty,
    List<String> selectedDays,
    String startTime,
    String endTime,
    int breakDuration,
    String role,
  ) async {
    try {
      await _db.collection(role).doc(uid).set({
        'name': name,
        'lastName': lastName,
        'address': address,
        'phone': phone,
        'email': email,
        'dni': dni,
        'n_matricula': n_matricula,
        'specialty': specialty,
        'availability': {
          'days': selectedDays,
          'start_time': startTime,
          'end_time': endTime,
          'break_duration': breakDuration,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user data: $e');
      throw e;
    }
  }

  /// Método genérico para obtener un documento específico de una colección.
  Future<DocumentSnapshot> getDocument(String collectionPath, String docId) async {
    try {
      return await _db.collection(collectionPath).doc(docId).get();
    } catch (e) {
      throw Exception('Error fetching document: $e');
    }
  }

  /// Método genérico para obtener todos los documentos de una colección.
  Future<List<QueryDocumentSnapshot>> getCollection(String collectionPath) async {
    try {
      QuerySnapshot querySnapshot = await _db.collection(collectionPath).get();
      return querySnapshot.docs;
    } catch (e) {
      throw Exception('Error fetching collection: $e');
    }
  }

  /// Método genérico para agregar un nuevo documento a una colección.
  Future<void> addDocument(String collectionPath, Map<String, dynamic> data) async {
    try {
      await _db.collection(collectionPath).add(data);
    } catch (e) {
      throw Exception('Error adding document: $e');
    }
  }

  /// Método genérico para actualizar un documento existente en una colección.
  Future<void> updateDocument(String collectionPath, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      throw Exception('Error updating document: $e');
    }
  }

  /// Método genérico para eliminar un documento de una colección.
  Future<void> deleteDocument(String collectionPath, String docId) async {
    try {
      await _db.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }

  /// Obtiene documentos de una colección que cumplen con una condición sobre un campo.
  Future<List<QueryDocumentSnapshot>> getDocumentsByField(
      String collectionPath, String fieldName, dynamic fieldValue) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection(collectionPath)
          .where(fieldName, isEqualTo: fieldValue)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw Exception('Error fetching documents by field: $e');
    }
  }

  /// Agrega o actualiza (upsert) un documento en la colección especificada.
  Future<void> setDocument(String collectionPath, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collectionPath).doc(docId).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error upserting document: $e');
    }
  }

  /// Obtiene documentos de forma paginada de una colección.
  /// [startAfterDoc] permite especificar el documento a partir del cual iniciar.
  Future<QuerySnapshot> getPaginatedCollection(String collectionPath,
      {DocumentSnapshot? startAfterDoc, int limit = 10}) async {
    try {
      Query query = _db.collection(collectionPath).limit(limit);
      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }
      return await query.get();
    } catch (e) {
      throw Exception('Error fetching paginated collection: $e');
    }
  }
}
