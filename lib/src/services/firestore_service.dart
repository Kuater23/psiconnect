import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch user data by uid
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(
    String uid,
    String name,
    String lastName,
    String address,
    String phone,
    String? email,
    String? documentType,
    String documentNumber,
    int matricula,
    List<String> selectedDays,
    String startTime,
    String endTime,
  ) async {
    try {
      await _db.collection('users').doc(uid).update({
        'name': name,
        'lastName': lastName,
        'address': address,
        'phone': phone,
        'email': email,
        'documentType': documentType,
        'documentNumber': documentNumber,
        'n_matricula': matricula,
        'availability': {
          'days': selectedDays,
          'start_time': startTime,
          'end_time': endTime,
        },
      });
    } catch (e) {
      print('Error updating user data: $e');
      throw e;
    }
  }

  // Method to get a specific document from a collection
  Future<DocumentSnapshot> getDocument(
      String collectionPath, String docId) async {
    try {
      return await _db.collection(collectionPath).doc(docId).get();
    } catch (e) {
      throw Exception('Error fetching document: $e');
    }
  }

  // Method to get all documents from a collection
  Future<List<QueryDocumentSnapshot>> getCollection(
      String collectionPath) async {
    try {
      QuerySnapshot querySnapshot = await _db.collection(collectionPath).get();
      return querySnapshot.docs;
    } catch (e) {
      throw Exception('Error fetching collection: $e');
    }
  }

  // Method to add a new document to a collection
  Future<void> addDocument(
      String collectionPath, Map<String, dynamic> data) async {
    try {
      await _db.collection(collectionPath).add(data);
    } catch (e) {
      throw Exception('Error adding document: $e');
    }
  }

  // Method to update an existing document
  Future<void> updateDocument(
      String collectionPath, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      throw Exception('Error updating document: $e');
    }
  }

  // Method to delete a document from a collection
  Future<void> deleteDocument(String collectionPath, String docId) async {
    try {
      await _db.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }

  // Method to get a list of documents by a field condition (where)
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

  // Method to add or update a document (upsert)
  Future<void> setDocument(
      String collectionPath, String docId, Map<String, dynamic> data) async {
    try {
      await _db
          .collection(collectionPath)
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error upserting document: $e');
    }
  }

  // Method to get paginated documents from a collection
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
