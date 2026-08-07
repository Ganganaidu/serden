part of 'lead_bloc.dart';

abstract class LeadEvent extends Equatable {
  const LeadEvent();
  @override
  List<Object?> get props => [];
}

class LeadsFetchRequested extends LeadEvent {
  final int userId;
  const LeadsFetchRequested(this.userId);
  @override
  List<Object> get props => [userId];
}

class LeadCreateRequested extends LeadEvent {
  final int userId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? streetAddress;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? requestText;
  final String? categoryName;
  final String? leadSource;
  final double? leadCost;
  final LeadStatus? status;

  const LeadCreateRequested({
    required this.userId,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.streetAddress,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
    this.requestText,
    this.categoryName,
    this.leadSource,
    this.leadCost,
    this.status,
  });

  @override
  List<Object?> get props => [
        userId,
        firstName,
        lastName,
        phone,
        email,
        streetAddress,
        city,
        state,
        zipCode,
        requestText,
      ];
}

class LeadUpdateRequested extends LeadEvent {
  final Lead lead;
  final int userId;
  const LeadUpdateRequested({required this.lead, required this.userId});
  @override
  List<Object> get props => [lead, userId];
}

class LeadStatusUpdateRequested extends LeadEvent {
  final int requestId;
  final int userId;
  final LeadStatus status;
  final String? notes;

  const LeadStatusUpdateRequested({
    required this.requestId,
    required this.userId,
    required this.status,
    this.notes,
  });

  @override
  List<Object?> get props => [requestId, userId, status, notes];
}

class LeadDeleteRequested extends LeadEvent {
  final int requestId;
  final int userId;
  const LeadDeleteRequested({required this.requestId, required this.userId});
  @override
  List<Object> get props => [requestId, userId];
}

class LeadsLoadMoreRequested extends LeadEvent {
  final int userId;
  const LeadsLoadMoreRequested(this.userId);
  @override
  List<Object> get props => [userId];
}
