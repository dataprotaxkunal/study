// lib/providers/app_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/chapter.dart';
import '../models/study_session.dart';
import '../models/revision.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  List<Subject>      subjects  = [];
  List<Chapter>      chapters  = [];
  List<StudySession> sessions  = [];
  List<Revision>     revisions = [];
  String examDate   = '';
  bool   darkMode   = false;
  bool   dndEnabled = false;
  String dndStart   = '09:00';
  String dndEnd     = '18:00';
  int _nextId     = 1;
  int _nextSessId = 1;
  int _nextRevId  = 1;

  int?      activeChapterId;
  DateTime? timerStart;
  Timer?    _ticker;
  final ValueNotifier<Duration> timerDuration = ValueNotifier(Duration.zero);

  static const List<Map<String, int>> palette = [
    {'bg': 0xFFe8f0fe, 'color': 0xFF1a73e8},
    {'bg': 0xFFfef3c7, 'color': 0xFF92400e},
    {'bg': 0xFFe6f4ea, 'color': 0xFF1e8e3e},
    {'bg': 0xFFfce8e6, 'color': 0xFFd93025},
    {'bg': 0xFFf3e8fd, 'color': 0xFF7b1fa2},
    {'bg': 0xFFe0f7fa, 'color': 0xFF00838f},
    {'bg': 0xFFfff3e0, 'color': 0xFFe65100},
  ];

  AppProvider() { _load(); }

  Map<String, int> palFor(String code) {
    final i = subjects.indexWhere((s) => s.code == code);
    return palette[(i < 0 ? 0 : i) % palette.length];
  }

  int get completedCount => chapters.where((c) => c.completed).length;
  int get chaptersWithNotesCount => chapters.where((c) => c.hasNotes).length;
  int get pendingRevisionCount => revisions.where((r) => !r.isCompleted && (r.isDueToday || r.isOverdue)).length;

  double totalHoursForChapter(int id) =>
      sessions.where((s) => s.chapterId == id).fold(0.0, (sum, s) => sum + s.hours);

  double totalHoursForSubject(String code) {
    final ids = chapters.where((c) => c.subject == code).map((c) => c.id).toSet();
    return sessions.where((s) => ids.contains(s.chapterId)).fold(0.0, (sum, s) => sum + s.hours);
  }

  double get totalHoursAllTime => sessions.fold(0.0, (sum, s) => sum + s.hours);

  double hoursThisWeek() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return sessions.where((s) {
      try { return DateFormat('yyyy-MM-dd').parse(s.date).isAfter(weekAgo); } catch(_) { return false; }
    }).fold(0.0, (sum, s) => sum + s.hours);
  }

  int sessionCountForChapter(int id) => sessions.where((s) => s.chapterId == id).length;

  List<Chapter> get unstudiedChapters =>
      chapters.where((c) => c.startDate.isNotEmpty && totalHoursForChapter(c.id) == 0).toList();

  List<Revision> get dueRevisions =>
      revisions.where((r) => r.isDueToday || r.isOverdue).toList();

  List<Chapter> searchChapters(String query) {
    if (query.isEmpty) return chapters;
    final q = query.toLowerCase();
    return chapters.where((c) =>
        c.topic.toLowerCase().contains(q) ||
        c.subject.toLowerCase().contains(q) ||
        c.notes.toLowerCase().contains(q)).toList();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    darkMode   = p.getBool('darkMode')   ?? false;
    dndEnabled = p.getBool('dndEnabled') ?? false;
    dndStart   = p.getString('dndStart') ?? '09:00';
    dndEnd     = p.getString('dndEnd')   ?? '18:00';
    examDate   = p.getString('examDate') ?? '';
    final sj = p.getString('subjects');
    final ch = p.getString('chapters');
    final se = p.getString('sessions');
    final rv = p.getString('revisions');
    subjects  = sj != null ? (jsonDecode(sj) as List).map((e) => Subject.fromJson(e)).toList()      : _defaultSubjects();
    chapters  = ch != null ? (jsonDecode(ch) as List).map((e) => Chapter.fromJson(e)).toList()      : _defaultChapters();
    sessions  = se != null ? (jsonDecode(se) as List).map((e) => StudySession.fromJson(e)).toList() : [];
    revisions = rv != null ? (jsonDecode(rv) as List).map((e) => Revision.fromJson(e)).toList()     : [];
    _nextId     = chapters.isEmpty  ? 1 : chapters.map((c)  => c.id).reduce((a,b) => a>b?a:b) + 1;
    _nextSessId = sessions.isEmpty  ? 1 : sessions.map((s)  => s.id).reduce((a,b) => a>b?a:b) + 1;
    _nextRevId  = revisions.isEmpty ? 1 : revisions.map((r) => r.id).reduce((a,b) => a>b?a:b) + 1;
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('subjects',  jsonEncode(subjects.map((s)  => s.toJson()).toList()));
    await p.setString('chapters',  jsonEncode(chapters.map((c)  => c.toJson()).toList()));
    await p.setString('sessions',  jsonEncode(sessions.map((s)  => s.toJson()).toList()));
    await p.setString('revisions', jsonEncode(revisions.map((r) => r.toJson()).toList()));
    await p.setString('examDate',  examDate);
    await p.setBool('darkMode',    darkMode);
    await p.setBool('dndEnabled',  dndEnabled);
    await p.setString('dndStart',  dndStart);
    await p.setString('dndEnd',    dndEnd);
  }

  void startTimer(int chapterId) {
    if (activeChapterId != null) stopTimer();
    activeChapterId = chapterId;
    timerStart = DateTime.now();
    timerDuration.value = Duration.zero;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      timerDuration.value = DateTime.now().difference(timerStart!);
    });
    notifyListeners();
  }

  void stopTimer() {
    _ticker?.cancel(); _ticker = null;
    if (timerStart != null && activeChapterId != null) {
      final mins = DateTime.now().difference(timerStart!).inMinutes;
      if (mins >= 1) _saveSession(activeChapterId!, mins);
    }
    activeChapterId = null; timerStart = null;
    timerDuration.value = Duration.zero;
    NotificationService.cancelTimerNotification();
    notifyListeners();
  }

  void _saveSession(int chapterId, int minutes) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final existing = sessions.where((s) => s.chapterId == chapterId && s.date == today).toList();
    if (existing.isNotEmpty) {
      existing.first.durationMinutes += minutes;
    } else {
      sessions.add(StudySession(id: _nextSessId++, chapterId: chapterId, date: today, durationMinutes: minutes));
    }
    save(); notifyListeners();
  }

  void addSubject(Subject s) { subjects.add(s); save(); notifyListeners(); }

  void deleteSubject(String code) {
    subjects.removeWhere((s) => s.code == code);
    chapters.removeWhere((c) => c.subject == code);
    save(); notifyListeners();
  }

  void addChapter(Chapter c) {
    c.id = _nextId++;
    chapters.add(c);
    _scheduleChapterNotification(c);
    save(); notifyListeners();
  }

  void updateChapter(int id, {String? startDate, String? endDate, String? studyTime}) {
    final c = chapters.firstWhere((c) => c.id == id, orElse: () => Chapter(id:-1,topic:'',subject:''));
    if (c.id == -1) return;
    if (startDate != null) c.startDate = startDate;
    if (endDate   != null) c.endDate   = endDate;
    if (studyTime != null) { c.studyTime = studyTime; NotificationService.cancelNotification(id); _scheduleChapterNotification(c); }
    save(); notifyListeners();
  }

  void toggleComplete(int id) {
    final c = chapters.firstWhere((c) => c.id == id, orElse: () => Chapter(id:-1,topic:'',subject:''));
    if (c.id == -1) return;
    c.completed = !c.completed;
    if (c.completed) _scheduleRevisions(c);
    else revisions.removeWhere((r) => r.chapterId == id && !r.isCompleted);
    save(); notifyListeners();
  }

  void updateNotes(int id, String notes) {
    final c = chapters.firstWhere((c) => c.id == id, orElse: () => Chapter(id:-1,topic:'',subject:''));
    if (c.id == -1) return;
    c.notes = notes;
    c.notesUpdatedAt = DateTime.now().toIso8601String();
    save(); notifyListeners();
  }

  void deleteChapter(int id) {
    if (activeChapterId == id) stopTimer();
    NotificationService.cancelNotification(id);
    chapters.removeWhere((c) => c.id == id);
    sessions.removeWhere((s) => s.chapterId == id);
    revisions.removeWhere((r) => r.chapterId == id);
    save(); notifyListeners();
  }

  void _scheduleRevisions(Chapter ch) {
    revisions.removeWhere((r) => r.chapterId == ch.id && !r.isCompleted);
    final today = DateTime.now();
    final gaps  = [3, 7, 21];
    for (int i = 0; i < gaps.length; i++) {
      final revDate = today.add(Duration(days: gaps[i]));
      revisions.add(Revision(
        id: _nextRevId++, chapterId: ch.id,
        revisionNumber: i+1,
        scheduledDate: DateFormat('yyyy-MM-dd').format(revDate),
      ));
      NotificationService.scheduleNotification(
        id: 50000 + (ch.id * 10) + i,
        title: 'Revision ${i+1} Due: ${ch.topic}',
        body: 'Time to revise "${ch.topic}" — Revision ${i+1} of 3',
        scheduledDate: DateTime(revDate.year, revDate.month, revDate.day, 9, 0),
      );
    }
  }

  void completeRevision(int id) {
    final r = revisions.firstWhere((r) => r.id == id, orElse: () => Revision(id:-1,chapterId:-1,revisionNumber:0,scheduledDate:''));
    if (r.id == -1) return;
    r.completedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    save(); notifyListeners();
  }

  void deleteRevision(int id) {
    revisions.removeWhere((r) => r.id == id);
    save(); notifyListeners();
  }

  void setExamDate(String d) { examDate = d; save(); notifyListeners(); }
  void setDarkMode(bool v)   { darkMode = v; save(); notifyListeners(); }

  void setDnd({bool? enabled, String? start, String? end}) {
    if (enabled != null) dndEnabled = enabled;
    if (start   != null) dndStart   = start;
    if (end     != null) dndEnd     = end;
    if (dndEnabled) NotificationService.scheduleDnd(dndStart, dndEnd);
    else NotificationService.cancelDnd();
    save(); notifyListeners();
  }

  void clearAll() {
    if (activeChapterId != null) stopTimer();
    subjects  = _defaultSubjects();
    chapters  = _defaultChapters();
    sessions  = []; revisions = [];
    examDate  = ''; darkMode  = false;
    dndEnabled = false; dndStart = '09:00'; dndEnd = '18:00';
    NotificationService.cancelAll();
    save(); notifyListeners();
  }

  void rescheduleAll() {
    NotificationService.cancelAll();
    for (final c in chapters) { _scheduleChapterNotification(c); }
    if (dndEnabled) NotificationService.scheduleDnd(dndStart, dndEnd);
  }

  void _scheduleChapterNotification(Chapter c) {
    if (c.studyTime.isEmpty || c.startDate.isEmpty) return;
    final parts = c.studyTime.split(':');
    final hour  = int.tryParse(parts[0]) ?? 0;
    final min   = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final start = Chapter.parseDate(c.startDate);
    final end   = Chapter.parseDate(c.endDate.isNotEmpty ? c.endDate : c.startDate);
    if (start == null || end == null) return;
    var date = start; var nId = c.id * 1000;
    while (!date.isAfter(end) && nId < c.id * 1000 + 365) {
      final dt = DateTime(date.year, date.month, date.day, hour, min);
      if (dt.isAfter(DateTime.now())) {
        NotificationService.scheduleNotification(
          id: nId, title: 'Study Time: ${c.topic}',
          body: '"${c.topic}" — start your session now!',
          scheduledDate: dt,
        );
      }
      date = date.add(const Duration(days: 1)); nId++;
    }
  }

  List<Subject> _defaultSubjects() => [
    Subject(code:'CFR', name:'Corporate Financial Reporting'),
    Subject(code:'CMA', name:'Cost & Management Audit'),
  ];

  List<Chapter> _defaultChapters() {
    const cfr = ['Accounting Policies, Changes in Accounting Estimates and Errors','Income Taxes','Property, Plant and Equipment','Leases','Effects of Changes in Foreign Exchange Rates','Borrowing Costs','Impairment of Assets','Intangible Assets','Share-based Payment','Operating Segments','Fair Value Measurement','Revenue from Contracts with Customers','Valuation of Shares','Accounting of Financial Instruments','NBFCs – Provisioning Norms, Accounting and Reporting','Accounting for Business Combination and Restructuring','Consolidated and Separate Financial Statements','Recent Developments in Financial Reporting','Government Accounting in India'];
    const cma = ['Basics of Cost Audit','Companies (Cost Records and Audit) Rules, 2014','Cost Auditor','Overview of Cost Accounting Standards and GACAP','Cost Auditing and Assurance Standards','Cost Audit Programme','Cost Audit Documentation, Audit Process and Execution','Preparation and Filing of Cost Audit Report','Basics of Management Audit','Management Reporting Issues and Analysis','Management Audit in Different Functions','Evaluation of Corporate Image','Information Systems Security Audit','Internal Control and Internal Audit','Operational Audit and Internal Audit under Companies Act, 2013','Audit of Different Service Organisations','Forensic Audit','Anti-Money Laundering'];
    int id = 1;
    return [...cfr.map((t) => Chapter(id:id++,topic:t,subject:'CFR')), ...cma.map((t) => Chapter(id:id++,topic:t,subject:'CMA'))];
  }
}
