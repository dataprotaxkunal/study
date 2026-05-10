// lib/models/chapter.dart
class Chapter {
  int id;
  String topic;
  String subject;
  String startDate;
  String endDate;
  String studyTime;
  bool completed;
  String notes;          // chapter notes
  String notesUpdatedAt; // ISO timestamp of last note edit

  Chapter({
    required this.id,
    required this.topic,
    required this.subject,
    this.startDate = '',
    this.endDate = '',
    this.studyTime = '',
    this.completed = false,
    this.notes = '',
    this.notesUpdatedAt = '',
  });

  bool get hasNotes => notes.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'subject': subject,
        'startDate': startDate,
        'endDate': endDate,
        'studyTime': studyTime,
        'completed': completed,
        'notes': notes,
        'notesUpdatedAt': notesUpdatedAt,
      };

  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        id: j['id'],
        topic: j['topic'],
        subject: j['subject'],
        startDate: j['startDate'] ?? '',
        endDate: j['endDate'] ?? '',
        studyTime: j['studyTime'] ?? '',
        completed: j['completed'] ?? false,
        notes: j['notes'] ?? '',
        notesUpdatedAt: j['notesUpdatedAt'] ?? '',
      );

  bool isActiveOn(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = parseDate(startDate);
    final e = parseDate(endDate);
    if (s == null && e == null) return false;
    if (s != null && e != null) return !d.isBefore(s) && !d.isAfter(e);
    if (s != null) return d.isAtSameMomentAs(s);
    if (e != null) return d.isAtSameMomentAs(e);
    return false;
  }

  static DateTime? parseDate(String s) {
    if (s.isEmpty) return null;
    try {
      final parts = s.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return null;
    }
  }
}
