// lib/models/study_session.dart
class StudySession {
  int id;
  int chapterId;
  String date;         // YYYY-MM-DD
  int durationMinutes; // total minutes studied

  StudySession({
    required this.id,
    required this.chapterId,
    required this.date,
    required this.durationMinutes,
  });

  double get hours => durationMinutes / 60.0;

  String get formattedDuration {
    if (durationMinutes < 60) return '${durationMinutes}m';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterId': chapterId,
        'date': date,
        'durationMinutes': durationMinutes,
      };

  factory StudySession.fromJson(Map<String, dynamic> j) => StudySession(
        id: j['id'],
        chapterId: j['chapterId'],
        date: j['date'],
        durationMinutes: j['durationMinutes'],
      );
}
