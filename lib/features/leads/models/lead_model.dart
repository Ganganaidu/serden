import 'package:equatable/equatable.dart';

enum LeadStatus { newLead, contacted, quoted, won, lost }

class Lead extends Equatable {
  final String id;
  final String name;

  /// Relative time shown top-right, e.g. "2h ago", "Jul 8".
  final String time;

  /// Highlights the timestamp in orange for fresh leads.
  final bool fresh;
  final String project;
  final String place;
  final LeadStatus status;

  const Lead({
    required this.id,
    required this.name,
    required this.time,
    required this.fresh,
    required this.project,
    required this.place,
    required this.status,
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as String,
        name: json['name'] as String,
        time: json['time'] as String? ?? '',
        fresh: json['fresh'] as bool? ?? false,
        project: json['project'] as String? ?? '',
        place: json['place'] as String? ?? '',
        status: LeadStatus.values.byName(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': time,
        'fresh': fresh,
        'project': project,
        'place': place,
        'status': status.name,
      };

  @override
  List<Object?> get props => [id, name, time, fresh, project, place, status];
}

/// Test data matching the design mockups. Replaced by the API later.
final List<Lead> mockLeads = [
  const Lead(id: '1', name: 'Ca Tilton', time: '2h ago', fresh: true, project: 'Remodel a kitchen', place: 'Vancouver, WA 98685', status: LeadStatus.newLead),
  const Lead(id: '2', name: 'David Tremain', time: 'Yesterday', fresh: true, project: 'Remodel a bathroom', place: 'Vancouver, WA 98660', status: LeadStatus.newLead),
  const Lead(id: '3', name: 'Tommie Joiner', time: 'Jul 8', fresh: false, project: 'Remodel a kitchen', place: 'Vancouver, WA 98683', status: LeadStatus.contacted),
  const Lead(id: '4', name: 'George Cazel', time: 'Jul 3', fresh: false, project: 'Remodel or renovate one or more rooms', place: 'Vancouver, WA 98684', status: LeadStatus.quoted),
  const Lead(id: '5', name: 'Doug Windress', time: 'Jun 28', fresh: false, project: 'Renovate or repair a home', place: 'Vancouver, WA 98682', status: LeadStatus.quoted),
  const Lead(id: '6', name: 'Carmella Weis', time: 'Jun 20', fresh: false, project: 'Remodel a kitchen', place: 'Camas, WA 98607', status: LeadStatus.won),
  const Lead(id: '7', name: 'Virginia Jimenez', time: 'Jun 15', fresh: false, project: 'Build an addition', place: 'Vancouver, WA 98662', status: LeadStatus.lost),
];
