class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.location,
    required this.eventDate,
    this.registrationDeadline,
    this.maxParticipants,
    this.status,
  });

  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? location;
  final DateTime eventDate;
  final DateTime? registrationDeadline;
  final int? maxParticipants;
  final String? status;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      location: json['location']?.toString(),
      eventDate: DateTime.parse(json['eventDate'].toString()),
      registrationDeadline: json['registrationDeadline'] != null
          ? DateTime.tryParse(json['registrationDeadline'].toString())
          : null,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
      status: json['status']?.toString(),
    );
  }
}
