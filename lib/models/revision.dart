// lib/models/revision.dart
class Revision {
  int id;
  int chapterId;
  int revisionNumber;   // 1, 2, or 3
  String scheduledDate; // YYYY-MM-DD
  String completedDate; // empty = not done

  Revision({
    required this.id,
    required this.chapterId,
    required this.revisionNumber,
    required this.scheduledDate,
    this.completedDate = '',
  });

  bool get isCompleted => completedDate.isNotEmpty;

  bool get isDueToday {
    final today = _todayStr();
    return scheduledDate == today && !isCompleted;
  }

  bool get isOverdue {
    final today = _todayStr();
    return scheduledDate.compareTo(today) < 0 && !isCompleted;
  }

  bool get isUpcoming {
    final today = _todayStr();
    return scheduledDate.compareTo(today) > 0 && !isCompleted;
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  String get revisionLabel => 'Revision $revisionNumber';

  Map<String, dynamic> toJson() => {
        'id': id,
        'chapterId': chapterId,
        'revisionNumber': revisionNumber,
        'scheduledDate': scheduledDate,
        'completedDate': completedDate,
      };

  factory Revision.fromJson(Map<String, dynamic> j) => Revision(
        id: j['id'],
        chapterId: j['chapterId'],
        revisionNumber: j['revisionNumber'],
        scheduledDate: j['scheduledDate'],
        completedDate: j['completedDate'] ?? '',
      );
}
