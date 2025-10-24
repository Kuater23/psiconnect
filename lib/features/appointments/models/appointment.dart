// lib/src/models/appointment.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/base_model.dart';

class Appointment extends BaseModel {
  final String patientId;
  final String doctorId;
  final String? patientName;
  final String? doctorName;
  final String? doctorSpeciality;
  final DateTime scheduledAt;
  final String? details;
  final String status; // scheduled, completed, cancelled, pending
  final bool isVirtual;
  final String? location;
  final String? meetingLink;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? notes;

  Appointment({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.patientId,
    required this.doctorId,
    this.patientName,
    this.doctorName,
    this.doctorSpeciality,
    required this.scheduledAt,
    this.details,
    this.status = 'scheduled',
    this.isVirtual = false,
    this.location,
    this.meetingLink,
    this.cancellationReason,
    this.cancelledAt,
    this.notes,
  });

  factory Appointment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Documento sin datos');
    }

    return Appointment(
      id: doc.id,
      createdAt: BaseModel.timestampToDateTime(data['createdAt']),
      updatedAt: BaseModel.timestampToDateTime(data['updatedAt']),
      patientId: BaseModel.safeString(data['patientId']) ?? '',
      doctorId: BaseModel.safeString(data['doctorId']) ?? '',
      patientName: BaseModel.safeString(data['patientName']),
      doctorName: BaseModel.safeString(data['doctorName']),
      doctorSpeciality: BaseModel.safeString(data['doctorSpeciality']),
      scheduledAt: BaseModel.timestampToDateTime(data['scheduledAt']) ?? DateTime.now(),
      details: BaseModel.safeString(data['details']),
      status: BaseModel.safeString(data['status']) ?? 'scheduled',
      isVirtual: BaseModel.safeBool(data['isVirtual']),
      location: BaseModel.safeString(data['location']),
      meetingLink: BaseModel.safeString(data['meetingLink']),
      cancellationReason: BaseModel.safeString(data['cancellationReason']),
      cancelledAt: BaseModel.timestampToDateTime(data['cancelledAt']),
      notes: BaseModel.safeString(data['notes']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...baseMap,
      'patientId': patientId,
      'doctorId': doctorId,
      if (patientName != null) 'patientName': patientName,
      if (doctorName != null) 'doctorName': doctorName,
      if (doctorSpeciality != null) 'doctorSpeciality': doctorSpeciality,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      if (details != null) 'details': details,
      'status': status,
      'isVirtual': isVirtual,
      if (location != null) 'location': location,
      if (meetingLink != null) 'meetingLink': meetingLink,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (notes != null) 'notes': notes,
    };
  }

  Appointment copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? doctorName,
    String? doctorSpeciality,
    DateTime? scheduledAt,
    String? details,
    String? status,
    bool? isVirtual,
    String? location,
    String? meetingLink,
    String? cancellationReason,
    DateTime? cancelledAt,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      doctorSpeciality: doctorSpeciality ?? this.doctorSpeciality,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      details: details ?? this.details,
      status: status ?? this.status,
      isVirtual: isVirtual ?? this.isVirtual,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      notes: notes ?? this.notes,
    );
  }

  bool get isPast => scheduledAt.isBefore(DateTime.now());
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now()) && status == 'scheduled';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
}
