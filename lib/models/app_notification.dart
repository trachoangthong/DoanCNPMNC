class AppNotification {
  final int? id;
  final String title;
  final String body;
  final String senderEmail;
  final String? targetEmail;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    this.id,
    required this.title,
    required this.body,
    required this.senderEmail,
    this.targetEmail,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'body': body,
      'senderEmail': senderEmail,
      'targetEmail': targetEmail,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, Object?> json) {
    final Object? readValue = json['isRead'];
    return AppNotification(
      id: json['id'] as int?,
      title: json['title'] as String,
      body: json['body'] as String,
      senderEmail: json['senderEmail'] as String,
      targetEmail: json['targetEmail'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: readValue == 1 || readValue == true,
    );
  }
}
