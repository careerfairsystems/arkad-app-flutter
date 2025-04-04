class Job {
  final int id;
  final String? link;
  final String? description;
  final List<String> location;
  final List<String> jobType;
  final String? title;

  Job({
    required this.id,
    this.link,
    this.description,
    required this.location,
    required this.jobType,
    this.title,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      link: json['link'],
      description: json['description'],
      location: List<String>.from(json['location'] ?? []),
      jobType: List<String>.from(json['job_type'] ?? []),
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'link': link,
      'description': description,
      'location': location,
      'job_type': jobType,
      'title': title,
    };
  }
}
