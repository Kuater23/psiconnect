// lib/core/services/web_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/core/services/error_logger.dart';

/// Service for optimized Firestore operations in web environments
class WebFirestoreService {
  final FirebaseFirestore _firestore;
  
  // Cache for frequent queries
  final Map<String, dynamic> _queryCache = {};
  final Map<String, DateTime> _queryCacheTimestamps = {};
  
  // Default cache duration (5 minutes)
  final Duration _defaultCacheDuration = Duration(minutes: 5);

  // Singleton pattern
  static final WebFirestoreService _instance = WebFirestoreService._internal();
  
  // Factory constructor
  factory WebFirestoreService() => _instance;
  
  // Private constructor
  WebFirestoreService._internal() : _firestore = FirebaseFirestore.instance {
    _configureFirestore();
  }
  
  /// Configure Firestore with web-optimized settings
  void _configureFirestore() {
    if (kIsWeb) {
      _firestore.settings = const Settings(
        cacheSizeBytes: 50 * 1024 * 1024, // 50MB cache
        persistenceEnabled: true,
      );
      
      debugPrint('WebFirestoreService: Configured with web optimizations');
    }
  }
  
  /// Get document with optimized caching
  Future<DocumentSnapshot?> getDocument(
    String collectionPath,
    String docId, {
    bool useCache = true,
    Duration? cacheDuration,
  }) async {
    try {
      final String cacheKey = '$collectionPath/$docId';
      
      // Check cache if enabled
      if (useCache && _queryCache.containsKey(cacheKey)) {
        final cachedAt = _queryCacheTimestamps[cacheKey];
        final duration = cacheDuration ?? _defaultCacheDuration;
        
        // If cache is fresh, use it
        if (cachedAt != null && 
            DateTime.now().difference(cachedAt) < duration) {
          debugPrint('Using cache for $cacheKey');
          return _queryCache[cacheKey];
        }
      }
      
      // Get fresh data
      final docSnapshot = await _firestore
          .collection(collectionPath)
          .doc(docId)
          .get();
      
      // Store in cache
      if (useCache) {
        _queryCache[cacheKey] = docSnapshot;
        _queryCacheTimestamps[cacheKey] = DateTime.now();
      }
      
      return docSnapshot;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error getting Firestore document',
        e,
        stackTrace,
        additionalData: {
          'collectionPath': collectionPath,
          'docId': docId,
        },
      );
      return null;
    }
  }
  
  /// Get collection with web-optimized settings
  Future<QuerySnapshot?> getCollection(
    String collectionPath, {
    List<Filter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
    bool useCache = true,
    Duration? cacheDuration,
  }) async {
    try {
      // Create unique cache key based on parameters
      final String cacheKey = _createCacheKey(
        collectionPath,
        filters: filters,
        orderBy: orderBy,
        descending: descending,
        limit: limit,
      );
      
      // Check cache if enabled
      if (useCache && _queryCache.containsKey(cacheKey)) {
        final cachedAt = _queryCacheTimestamps[cacheKey];
        final duration = cacheDuration ?? _defaultCacheDuration;
        
        if (cachedAt != null && 
            DateTime.now().difference(cachedAt) < duration) {
          debugPrint('Using cache for query: $cacheKey');
          return _queryCache[cacheKey];
        }
      }
      
      // Build base query
      Query query = _firestore.collection(collectionPath);
      
      // Apply filters if provided
      if (filters != null && filters.isNotEmpty) {
        for (final filter in filters) {
          query = query.where(
            filter.field, 
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
          );
        }
      }
      
      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }
      
      // Execute query
      final querySnapshot = await query.get();
      
      // Store in cache
      if (useCache) {
        _queryCache[cacheKey] = querySnapshot;
        _queryCacheTimestamps[cacheKey] = DateTime.now();
      }
      
      return querySnapshot;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error getting Firestore collection',
        e,
        stackTrace,
        additionalData: {
          'collectionPath': collectionPath,
          'orderBy': orderBy,
          'descending': descending,
          'limit': limit,
        },
      );
      return null;
    }
  }
  
  /// Save document with optimized error handling
  Future<bool> setDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      // Invalidate cache for this document
      final cacheKey = '$collectionPath/$docId';
      _queryCache.remove(cacheKey);
      
      // Also invalidate any collection queries that might include this document
      _invalidateCollectionCaches(collectionPath);
      
      // Save document
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
      
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error saving Firestore document',
        e,
        stackTrace,
        additionalData: {
          'collectionPath': collectionPath,
          'docId': docId,
          'merge': merge,
        },
      );
      return false;
    }
  }
  
  /// Update document with optimizations
  Future<bool> updateDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Invalidate cache for this document
      final cacheKey = '$collectionPath/$docId';
      _queryCache.remove(cacheKey);
      
      // Also invalidate any collection queries that might include this document
      _invalidateCollectionCaches(collectionPath);
      
      // Update document
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .update(data);
      
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error updating Firestore document',
        e,
        stackTrace,
        additionalData: {
          'collectionPath': collectionPath,
          'docId': docId,
        },
      );
      return false;
    }
  }
  
  /// Delete document with optimizations
  Future<bool> deleteDocument(
    String collectionPath,
    String docId,
  ) async {
    try {
      // Invalidate cache for this document
      final cacheKey = '$collectionPath/$docId';
      _queryCache.remove(cacheKey);
      
      // Also invalidate any collection queries that might include this document
      _invalidateCollectionCaches(collectionPath);
      
      // Delete document
      await _firestore
          .collection(collectionPath)
          .doc(docId)
          .delete();
      
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error deleting Firestore document',
        e,
        stackTrace,
        additionalData: {
          'collectionPath': collectionPath,
          'docId': docId,
        },
      );
      return false;
    }
  }
  
  /// Create new document with auto-generated ID
  Future<String?> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      // Invalidate collection caches
      _invalidateCollectionCaches(collectionPath);
      
      // Create document
      final docRef = await _firestore
          .collection(collectionPath)
          .add(data);
      
      return docRef.id;
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error adding Firestore document',
        e,
        stackTrace,
        additionalData: {
          'collectionPath': collectionPath,
        },
      );
      return null;
    }
  }
  
  /// Listen to collection with web optimizations
  Stream<QuerySnapshot>? listenToCollection(
    String collectionPath, {
    List<Filter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    try {
      // Build base query
      Query query = _firestore.collection(collectionPath);
      
      // Apply filters if provided
      if (filters != null && filters.isNotEmpty) {
        for (final filter in filters) {
          query = query.where(
            filter.field, 
            isEqualTo: filter.isEqualTo,
            isNotEqualTo: filter.isNotEqualTo,
            isGreaterThan: filter.isGreaterThan,
            isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
            isLessThan: filter.isLessThan,
            isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
            arrayContains: filter.arrayContains,
            arrayContainsAny: filter.arrayContainsAny,
            whereIn: filter.whereIn,
            whereNotIn: filter.whereNotIn,
          );
        }
      }
      
      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }
      
      // Return stream
      return query.snapshots();
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'Error listening to Firestore collection',
        e,
        stackTrace,
        additionalData: {
          'collectionPath': collectionPath,
          'orderBy': orderBy,
          'descending': descending,
          'limit': limit,
        },
      );
      return null;
    }
  }
  
  /// Clear cache to optimize memory usage
  void clearCache() {
    _queryCache.clear();
    _queryCacheTimestamps.clear();
    debugPrint('Firestore cache cleared');
  }
  
  /// Clear cache for a specific collection
  void clearCollectionCache(String collectionPath) {
    _invalidateCollectionCaches(collectionPath);
    debugPrint('Cache for collection $collectionPath cleared');
  }
  
  /// Invalidate collection caches
  void _invalidateCollectionCaches(String collectionPath) {
    // Remove all cache keys that include this collection
    final keysToRemove = _queryCache.keys
        .where((key) => key.startsWith(collectionPath))
        .toList();
    
    for (final key in keysToRemove) {
      _queryCache.remove(key);
      _queryCacheTimestamps.remove(key);
    }
  }
  
  /// Create a unique cache key for queries
  String _createCacheKey(
    String collectionPath, {
    List<Filter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    String key = collectionPath;
    
    if (filters != null && filters.isNotEmpty) {
      key += '|filters:${filters.map((f) => f.toString()).join(',')}';
    }
    
    if (orderBy != null) {
      key += '|orderBy:$orderBy';
      key += '|descending:$descending';
    }
    
    if (limit != null) {
      key += '|limit:$limit';
    }
    
    return key;
  }
}

/// Class to define Firestore query filters
class Filter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isNotEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final dynamic arrayContains;
  final List<dynamic>? arrayContainsAny;
  final List<dynamic>? whereIn;
  final List<dynamic>? whereNotIn;
  
  Filter({
    required this.field,
    this.isEqualTo,
    this.isNotEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
  });
  
  @override
  String toString() {
    final conditions = <String>[];
    
    if (isEqualTo != null) conditions.add('isEqualTo: $isEqualTo');
    if (isNotEqualTo != null) conditions.add('isNotEqualTo: $isNotEqualTo');
    if (isGreaterThan != null) conditions.add('isGreaterThan: $isGreaterThan');
    if (isGreaterThanOrEqualTo != null) conditions.add('isGreaterThanOrEqualTo: $isGreaterThanOrEqualTo');
    if (isLessThan != null) conditions.add('isLessThan: $isLessThan');
    if (isLessThanOrEqualTo != null) conditions.add('isLessThanOrEqualTo: $isLessThanOrEqualTo');
    if (arrayContains != null) conditions.add('arrayContains: $arrayContains');
    if (arrayContainsAny != null) conditions.add('arrayContainsAny: $arrayContainsAny');
    if (whereIn != null) conditions.add('whereIn: $whereIn');
    if (whereNotIn != null) conditions.add('whereNotIn: $whereNotIn');
    
    return '$field: ${conditions.join(', ')}';
  }
}