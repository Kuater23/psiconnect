import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/error_logger.dart';

/// Repositorio base con operaciones CRUD comunes para Firestore
abstract class BaseFirestoreRepository<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Nombre de la colección en Firestore
  String get collectionName;
  
  /// Convertir documento Firestore a modelo
  T fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc);
  
  /// Convertir modelo a Map para Firestore
  Map<String, dynamic> toFirestore(T item);

  /// Referencia a la colección
  CollectionReference<Map<String, dynamic>> get collection =>
      _firestore.collection(collectionName);

  // ==================== CRUD Operations ====================

  /// Crear un nuevo documento
  Future<String> create(T item, {String? id}) async {
    try {
      final data = toFirestore(item);
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      if (id != null) {
        await collection.doc(id).set(data);
        return id;
      } else {
        final ref = await collection.add(data);
        return ref.id;
      }
    } catch (e, st) {
      ErrorLogger.logError('Error creando documento en $collectionName', e, st);
      rethrow;
    }
  }

  /// Leer un documento por ID
  Future<T?> read(String id) async {
    try {
      final doc = await collection.doc(id).get();
      return doc.exists ? fromFirestore(doc) : null;
    } catch (e, st) {
      ErrorLogger.logError('Error leyendo documento de $collectionName', e, st);
      rethrow;
    }
  }

  /// Actualizar un documento
  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await collection.doc(id).update(data);
    } catch (e, st) {
      ErrorLogger.logError('Error actualizando documento en $collectionName', e, st);
      rethrow;
    }
  }

  /// Eliminar un documento
  Future<void> delete(String id) async {
    try {
      await collection.doc(id).delete();
    } catch (e, st) {
      ErrorLogger.logError('Error eliminando documento de $collectionName', e, st);
      rethrow;
    }
  }

  // ==================== Query Operations ====================

  /// Obtener todos los documentos
  Future<List<T>> getAll() async {
    try {
      final snapshot = await collection.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e, st) {
      ErrorLogger.logError('Error obteniendo todos los documentos de $collectionName', e, st);
      rethrow;
    }
  }

  /// Stream de todos los documentos
  Stream<List<T>> streamAll() {
    return collection.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList(),
    );
  }

  /// Query con filtro único
  Future<List<T>> where(String field, dynamic isEqualTo) async {
    try {
      final snapshot = await collection
          .where(field, isEqualTo: isEqualTo)
          .get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e, st) {
      ErrorLogger.logError('Error en query where de $collectionName', e, st);
      rethrow;
    }
  }

  /// Stream con filtro único
  Stream<List<T>> streamWhere(String field, dynamic isEqualTo) {
    return collection
        .where(field, isEqualTo: isEqualTo)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }

  /// Query con ordenamiento
  Future<List<T>> orderBy(String field, {bool descending = false}) async {
    try {
      final snapshot = await collection
          .orderBy(field, descending: descending)
          .get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e, st) {
      ErrorLogger.logError('Error en orderBy de $collectionName', e, st);
      rethrow;
    }
  }

  /// Stream con ordenamiento
  Stream<List<T>> streamOrderBy(String field, {bool descending = false}) {
    return collection
        .orderBy(field, descending: descending)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList());
  }

  /// Query compleja con múltiples filtros y ordenamiento
  Future<List<T>> complexQuery({
    Map<String, dynamic>? whereEquals,
    Map<String, dynamic>? whereArrayContains,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection;

      if (whereEquals != null) {
        whereEquals.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }

      if (whereArrayContains != null) {
        whereArrayContains.forEach((field, value) {
          query = query.where(field, arrayContains: value);
        });
      }

      if (orderByField != null) {
        query = query.orderBy(orderByField, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e, st) {
      ErrorLogger.logError('Error en query compleja de $collectionName', e, st);
      rethrow;
    }
  }

  /// Stream de query compleja
  Stream<List<T>> streamComplexQuery({
    Map<String, dynamic>? whereEquals,
    Map<String, dynamic>? whereArrayContains,
    String? orderByField,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = collection;

    if (whereEquals != null) {
      whereEquals.forEach((field, value) {
        query = query.where(field, isEqualTo: value);
      });
    }

    if (whereArrayContains != null) {
      whereArrayContains.forEach((field, value) {
        query = query.where(field, arrayContains: value);
      });
    }

    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => fromFirestore(doc)).toList(),
    );
  }

  /// Verificar si existe un documento
  Future<bool> exists(String id) async {
    try {
      final doc = await collection.doc(id).get();
      return doc.exists;
    } catch (e, st) {
      ErrorLogger.logError('Error verificando existencia en $collectionName', e, st);
      rethrow;
    }
  }

  /// Contar documentos con filtro opcional
  Future<int> count({Map<String, dynamic>? whereEquals}) async {
    try {
      Query<Map<String, dynamic>> query = collection;

      if (whereEquals != null) {
        whereEquals.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e, st) {
      ErrorLogger.logError('Error contando documentos en $collectionName', e, st);
      rethrow;
    }
  }

  /// Batch create - crear múltiples documentos
  Future<void> batchCreate(List<T> items) async {
    try {
      final batch = _firestore.batch();
      
      for (final item in items) {
        final data = toFirestore(item);
        data['createdAt'] = FieldValue.serverTimestamp();
        data['updatedAt'] = FieldValue.serverTimestamp();
        
        final ref = collection.doc();
        batch.set(ref, data);
      }
      
      await batch.commit();
    } catch (e, st) {
      ErrorLogger.logError('Error en batch create de $collectionName', e, st);
      rethrow;
    }
  }

  /// Batch update - actualizar múltiples documentos
  Future<void> batchUpdate(Map<String, Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();
      
      updates.forEach((id, data) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        batch.update(collection.doc(id), data);
      });
      
      await batch.commit();
    } catch (e, st) {
      ErrorLogger.logError('Error en batch update de $collectionName', e, st);
      rethrow;
    }
  }

  /// Batch delete - eliminar múltiples documentos
  Future<void> batchDelete(List<String> ids) async {
    try {
      final batch = _firestore.batch();
      
      for (final id in ids) {
        batch.delete(collection.doc(id));
      }
      
      await batch.commit();
    } catch (e, st) {
      ErrorLogger.logError('Error en batch delete de $collectionName', e, st);
      rethrow;
    }
  }
}