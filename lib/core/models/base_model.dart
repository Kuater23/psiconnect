import 'package:cloud_firestore/cloud_firestore.dart';

/// Clase base para todos los modelos con campos comunes
abstract class BaseModel {
  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BaseModel({
    this.id,
    this.createdAt,
    this.updatedAt,
  });

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap();

  /// Campos comunes para todos los modelos
  Map<String, dynamic> get baseMap => {
        if (id != null) 'id': id,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      };

  /// Helper para extraer DateTime de Firestore
  static DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  /// Helper para extraer String seguro
  static String? safeString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Helper para extraer int seguro
  static int? safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper para extraer double seguro
  static double? safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper para extraer bool seguro
  static bool safeBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return defaultValue;
  }

  /// Helper para extraer List seguro
  static List<T> safeList<T>(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<T>();
    return [];
  }

  /// Helper para extraer Map seguro
  static Map<String, dynamic> safeMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }
}