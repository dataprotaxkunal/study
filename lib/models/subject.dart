// lib/models/subject.dart
class Subject {
  String code;
  String name;

  Subject({required this.code, required this.name});

  Map<String, dynamic> toJson() => {'code': code, 'name': name};

  factory Subject.fromJson(Map<String, dynamic> j) =>
      Subject(code: j['code'], name: j['name']);
}
