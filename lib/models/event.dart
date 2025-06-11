class Event {
  final String name;
  final String description;
  final String type;
  final String location;
  final String language;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final int numberBooked;
  final int? companyId;

  Event({
    required this.name,
    required this.description,
    required this.type,
    required this.location,
    required this.language,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.numberBooked,
    this.companyId,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    Event test = Event(
      name: json['name'],
      description: json['description'],
      type: json['type'],
      location: json['location'],
      language: json['language'],
      startTime: DateTime.now(), //TODO: parse json['startTime']
      endTime: DateTime.now(), //TODO: parse json['endTime']
      capacity: json['capacity'],
      numberBooked: json['numberBooked'],
      companyId: json['companyId'] ?? -1,
    );
    return test;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'location': location,
      'language': language,
      'startTime': startTime,
      'endTime': endTime,
      'capacity': capacity,
      'numberBooked': numberBooked,
      'companyId': companyId,
    };
  }
}
