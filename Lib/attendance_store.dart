import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'school_subject_catalog.dart';
import 'university_catalog.dart';

enum AttendanceStatus { present, late, absent }

enum InstitutionType { school, university }

extension InstitutionTypeLabel on InstitutionType {
  String get label => switch (this) {
    InstitutionType.school => 'School',
    InstitutionType.university => 'University',
  };
}

const schoolGrades = [
  'Grade 1',
  'Grade 2',
  'Grade 3',
  'Grade 4',
  'Grade 5',
  'Grade 6',
  'Grade 7',
  'Grade 8',
  'Grade 9',
  'Grade 10',
  'Grade 11',
  'Grade 12',
  'Grade 13',
];

const universityYears = [
  'First Year',
  'Second Year',
  'Third Year',
  'Fourth Year',
];

extension AttendanceStatusLabel on AttendanceStatus {
  String get label => switch (this) {
    AttendanceStatus.present => 'Present',
    AttendanceStatus.late => 'Late',
    AttendanceStatus.absent => 'Absent',
  };
}

class Student {
  const Student({
    required this.id,
    required this.name,
    required this.className,
    this.institutionType = InstitutionType.school,
    this.groupName = '',
    this.universityName = '',
    this.facultyName = '',
    this.subjectName = '',
    this.schoolStream = '',
  });

  final String id;
  final String name;
  final String className;
  final InstitutionType institutionType;
  final String groupName;
  final String universityName;
  final String facultyName;
  final String subjectName;
  final String schoolStream;

  Student copyWith({
    String? name,
    String? className,
    String? groupName,
    String? universityName,
    String? facultyName,
    String? subjectName,
    String? schoolStream,
  }) => Student(
    id: id,
    name: name ?? this.name,
    className: className ?? this.className,
    institutionType: institutionType,
    groupName: groupName ?? this.groupName,
    universityName: universityName ?? this.universityName,
    facultyName: facultyName ?? this.facultyName,
    subjectName: subjectName ?? this.subjectName,
    schoolStream: schoolStream ?? this.schoolStream,
  );

  String get attendanceGroup {
    if (groupName.isNotEmpty) return groupName;
    final match = RegExp(r'^Grade (\d+)').firstMatch(className);
    return match == null ? className : 'Grade ${match.group(1)}';
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}';
  }
}

class AttendancePeriodSummary {
  const AttendancePeriodSummary({
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
  });

  final int presentDays;
  final int lateDays;
  final int absentDays;

  int get markedDays => presentDays + lateDays + absentDays;

  double get averageAttendance =>
      markedDays == 0 ? 0 : ((presentDays + lateDays) / markedDays) * 100;
}

class AttendanceLogEntry {
  const AttendanceLogEntry({
    required this.dateKey,
    required this.markedAt,
    required this.institutionType,
    required this.groupName,
    required this.subjectName,
    required this.schoolStream,
    required this.universityName,
    required this.facultyName,
    required this.instructorName,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  });

  final String dateKey;
  final DateTime markedAt;
  final InstitutionType institutionType;
  final String groupName;
  final String subjectName;
  final String schoolStream;
  final String universityName;
  final String facultyName;
  final String instructorName;
  final int presentCount;
  final int lateCount;
  final int absentCount;

  int get markedCount => presentCount + lateCount + absentCount;

  String get subjectLabel => subjectName.isEmpty ? 'All subjects' : subjectName;

  String get instructorLabel =>
      instructorName.isEmpty ? 'Unassigned' : instructorName;

  String get scopeLabel => institutionType == InstitutionType.university
      ? [
          universityName,
          facultyName,
          groupName,
        ].where((part) => part.isNotEmpty).join(' · ')
      : [groupName, if (schoolStream.isNotEmpty) schoolStream].join(' · ');

  String get scopeKey =>
      '$institutionType|$universityName|$facultyName|$groupName|$schoolStream';
}

class CustomFacultyEntry {
  const CustomFacultyEntry({
    required this.universityName,
    required this.faculty,
  });

  final String universityName;
  final String faculty;

  String get scope => universityName;
}

class CustomSchoolSubjectEntry {
  const CustomSchoolSubjectEntry({
    required this.grade,
    required this.stream,
    required this.subject,
  });

  final String grade;
  final String stream;
  final String subject;

  String get scope => stream.isEmpty ? grade : '$grade · $stream';
}

class CustomCampusCourseEntry {
  const CustomCampusCourseEntry({
    required this.universityName,
    required this.facultyName,
    required this.year,
    required this.course,
  });

  final String universityName;
  final String facultyName;
  final String year;
  final String course;

  String get scope => '$universityName · $facultyName · $year';
}

class AttendanceStore extends ChangeNotifier {
  static final AttendanceStore instance = AttendanceStore();

  AttendanceStore();

  static const String _storageKey = 'attendance_store_v1';

  bool _loaded = false;
  Future<void>? _persistChain;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      _restoreFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    try {
      final snapshot = jsonEncode(_toJson());
      _persistChain = (_persistChain ?? Future<void>.value()).then((_) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_storageKey, snapshot);
        } catch (_) {}
      });
    } catch (_) {}
  }

  Map<String, dynamic> _toJson() {
    String? statusCode(AttendanceStatus? status) => status?.name;

    return <String, dynamic>{
      'version': 1,
      'nextId': _nextId,
      'students': [
        for (final student in _students)
          <String, dynamic>{
            'id': student.id,
            'name': student.name,
            'className': student.className,
            'institutionType': student.institutionType.name,
            'groupName': student.groupName,
            'universityName': student.universityName,
            'facultyName': student.facultyName,
            'subjectName': student.subjectName,
            'schoolStream': student.schoolStream,
          },
      ],
      'records': {
        for (final date in _records.entries)
          date.key: {
            for (final record in date.value.entries)
              record.key: statusCode(record.value),
          },
      },
      'markedAt': {
        for (final entry in _markedAt.entries)
          entry.key: entry.value.toIso8601String(),
      },
      'instructors': Map<String, String>.of(_instructorsByOffering),
      'logs': [
        for (final entry in _logs)
          <String, dynamic>{
            'dateKey': entry.dateKey,
            'markedAt': entry.markedAt.toIso8601String(),
            'institutionType': entry.institutionType.name,
            'groupName': entry.groupName,
            'subjectName': entry.subjectName,
            'schoolStream': entry.schoolStream,
            'universityName': entry.universityName,
            'facultyName': entry.facultyName,
            'instructorName': entry.instructorName,
            'presentCount': entry.presentCount,
            'lateCount': entry.lateCount,
            'absentCount': entry.absentCount,
          },
      ],
      'additionalGrades': List<String>.of(_additionalSchoolGrades),
      'additionalYears': List<String>.of(_additionalUniversityYears),
      'additionalUniversities': List<String>.of(_additionalUniversities),
      'additionalFaculties': {
        for (final entry in _additionalFaculties.entries)
          entry.key: List<String>.of(entry.value),
      },
      'additionalSchoolSubjects': {
        for (final entry in _additionalSchoolSubjects.entries)
          entry.key: List<String>.of(entry.value),
      },
      'additionalCampusSubjects': {
        for (final entry in _additionalCampusSubjects.entries)
          entry.key: List<String>.of(entry.value),
      },
      'gradeRenames': Map<String, String>.of(_gradeRenames),
      'yearRenames': Map<String, String>.of(_yearRenames),
      'universityRenames': Map<String, String>.of(_universityRenames),
      'facultyRenames': {
        for (final entry in _facultyRenames.entries)
          entry.key: Map<String, String>.of(entry.value),
      },
      'subjectRenames': {
        for (final entry in _subjectRenames.entries)
          entry.key: Map<String, String>.of(entry.value),
      },
      'courseRenames': {
        for (final entry in _courseRenames.entries)
          entry.key: Map<String, String>.of(entry.value),
      },
    };
  }

  void _restoreFromJson(Map<String, dynamic> json) {
    AttendanceStatus? statusFrom(dynamic value) {
      if (value is! String) return null;
      return AttendanceStatus.values.asNameMap()[value];
    }

    _students
      ..clear()
      ..addAll([
        for (final item in (json['students'] as List? ?? const []))
          Student(
            id: '${(item as Map<String, dynamic>)['id']}',
            name: (item['name'] as String?) ?? '',
            className: (item['className'] as String?) ?? '',
            institutionType:
                InstitutionType.values.asNameMap()[item['institutionType']] ??
                InstitutionType.school,
            groupName: (item['groupName'] as String?) ?? '',
            universityName: (item['universityName'] as String?) ?? '',
            facultyName: (item['facultyName'] as String?) ?? '',
            subjectName: (item['subjectName'] as String?) ?? '',
            schoolStream: (item['schoolStream'] as String?) ?? '',
          ),
      ]);

    _nextId = (json['nextId'] as num?)?.toInt() ?? _students.length + 1;

    _records.clear();
    (json['records'] as Map<String, dynamic>? ?? const {}).forEach((
      dateKey,
      value,
    ) {
      final statuses = <String, AttendanceStatus>{};
      (value as Map<String, dynamic>? ?? const {}).forEach((id, state) {
        final status = statusFrom(state);
        if (status != null) statuses[id] = status;
      });
      if (statuses.isNotEmpty) _records[dateKey] = statuses;
    });

    _markedAt.clear();
    (json['markedAt'] as Map<String, dynamic>? ?? const {}).forEach((
      dateKey,
      value,
    ) {
      final parsed = DateTime.tryParse('$value');
      if (parsed != null) _markedAt[dateKey] = parsed;
    });

    _instructorsByOffering
      ..clear()
      ..addAll(
        Map<String, String>.from(json['instructors'] as Map? ?? const {}),
      );

    _logs
      ..clear()
      ..addAll([
        for (final item in (json['logs'] as List? ?? const []))
          AttendanceLogEntry(
            dateKey: (item as Map<String, dynamic>)['dateKey'] as String? ?? '',
            markedAt:
                DateTime.tryParse('${item['markedAt']}') ?? DateTime.now(),
            institutionType:
                InstitutionType.values.asNameMap()[item['institutionType']] ??
                InstitutionType.school,
            groupName: (item['groupName'] as String?) ?? '',
            subjectName: (item['subjectName'] as String?) ?? '',
            schoolStream: (item['schoolStream'] as String?) ?? '',
            universityName: (item['universityName'] as String?) ?? '',
            facultyName: (item['facultyName'] as String?) ?? '',
            instructorName: (item['instructorName'] as String?) ?? '',
            presentCount: (item['presentCount'] as num?)?.toInt() ?? 0,
            lateCount: (item['lateCount'] as num?)?.toInt() ?? 0,
            absentCount: (item['absentCount'] as num?)?.toInt() ?? 0,
          ),
      ]);

    _additionalSchoolGrades
      ..clear()
      ..addAll(
        (json['additionalGrades'] as List? ?? const []).map((e) => '$e'),
      );
    _additionalUniversityYears
      ..clear()
      ..addAll((json['additionalYears'] as List? ?? const []).map((e) => '$e'));
    _additionalUniversities
      ..clear()
      ..addAll(
        (json['additionalUniversities'] as List? ?? const []).map((e) => '$e'),
      );

    _additionalFaculties
      ..clear()
      ..addAll({
        for (final entry
            in (json['additionalFaculties'] as Map<String, dynamic>? ??
                    const {})
                .entries)
          entry.key: (entry.value as List? ?? const [])
              .map((e) => '$e')
              .toList(),
      });

    _additionalSchoolSubjects
      ..clear()
      ..addAll({
        for (final entry
            in (json['additionalSchoolSubjects'] as Map<String, dynamic>? ??
                    const {})
                .entries)
          entry.key: (entry.value as List? ?? const [])
              .map((e) => '$e')
              .toList(),
      });

    _additionalCampusSubjects
      ..clear()
      ..addAll({
        for (final entry
            in (json['additionalCampusSubjects'] as Map<String, dynamic>? ??
                    const {})
                .entries)
          entry.key: (entry.value as List? ?? const [])
              .map((e) => '$e')
              .toList(),
      });

    _gradeRenames
      ..clear()
      ..addAll(
        Map<String, String>.from(json['gradeRenames'] as Map? ?? const {}),
      );
    _yearRenames
      ..clear()
      ..addAll(
        Map<String, String>.from(json['yearRenames'] as Map? ?? const {}),
      );
    _universityRenames
      ..clear()
      ..addAll(
        Map<String, String>.from(json['universityRenames'] as Map? ?? const {}),
      );

    _facultyRenames
      ..clear()
      ..addAll({
        for (final entry
            in (json['facultyRenames'] as Map<String, dynamic>? ?? const {})
                .entries)
          entry.key: Map<String, String>.from(entry.value as Map? ?? const {}),
      });
    _subjectRenames
      ..clear()
      ..addAll({
        for (final entry
            in (json['subjectRenames'] as Map<String, dynamic>? ?? const {})
                .entries)
          entry.key: Map<String, String>.from(entry.value as Map? ?? const {}),
      });
    _courseRenames
      ..clear()
      ..addAll({
        for (final entry
            in (json['courseRenames'] as Map<String, dynamic>? ?? const {})
                .entries)
          entry.key: Map<String, String>.from(entry.value as Map? ?? const {}),
      });
  }

  final List<Student> _students = [
    const Student(id: '1', name: 'Ava Thompson', className: 'Grade 8-A'),
    const Student(id: '2', name: 'Lucas Nguyen', className: 'Grade 8-A'),
    const Student(id: '3', name: 'Mia Patel', className: 'Grade 8-B'),
    const Student(id: '4', name: 'Noah Kim', className: 'Grade 8-C'),
    const Student(id: '5', name: 'Sophia Garcia', className: 'Grade 8-B'),
    const Student(id: '6', name: 'Ethan Brown', className: 'Grade 8-C'),
    const Student(id: '7', name: 'Isabella Davis', className: 'Grade 8-A'),
    const Student(id: '8', name: 'Liam Wilson', className: 'Grade 8-B'),
  ];

  int _nextId = 9;
  final Map<String, Map<String, AttendanceStatus>> _records = {};
  final Map<String, DateTime> _markedAt = {};
  final Map<String, String> _instructorsByOffering = {};
  final List<AttendanceLogEntry> _logs = [];

  List<Student> get students => List.unmodifiable(_students);

  final Map<String, List<String>> _additionalFaculties = {};
  final Set<String> _additionalUniversities = {};
  final Map<String, List<String>> _additionalSchoolSubjects = {};
  final Map<String, List<String>> _additionalCampusSubjects = {};
  final List<String> _additionalSchoolGrades = [];
  final List<String> _additionalUniversityYears = [];

  final Map<String, String> _gradeRenames = {};
  final Map<String, String> _yearRenames = {};
  final Map<String, String> _universityRenames = {};
  final Map<String, Map<String, String>> _facultyRenames = {};
  final Map<String, Map<String, String>> _subjectRenames = {};
  final Map<String, Map<String, String>> _courseRenames = {};

  static int _naturalCompare(String a, String b) {
    final aNumber = int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '');
    final bNumber = int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '');
    if (aNumber != null && bNumber != null && aNumber != bNumber) {
      return aNumber.compareTo(bNumber);
    }
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  static bool _containsName(Iterable<String> values, String value) {
    final trimmed = value.trim().toLowerCase();
    return values.any((item) => item.toLowerCase() == trimmed);
  }

  static int _indexOfName(List<String> values, String value) {
    final trimmed = value.trim().toLowerCase();
    return values.indexWhere((item) => item.toLowerCase() == trimmed);
  }

  static bool _sameNames(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  static String _originalName(Map<String, String> renames, String currentName) {
    for (final entry in renames.entries) {
      if (_sameNames(entry.value, currentName)) return entry.key;
    }
    return '';
  }

  static String _renamedName(Map<String, String> renames, String originalName) {
    for (final entry in renames.entries) {
      if (_sameNames(entry.key, originalName)) return entry.value;
    }
    return originalName.trim();
  }

  String _canonicalGrade(String grade) {
    final original = _originalName(_gradeRenames, grade);
    return original.isEmpty ? grade.trim() : original;
  }

  String _canonicalYear(String year) {
    final original = _originalName(_yearRenames, year);
    return original.isEmpty ? year.trim() : original;
  }

  String canonicalUniversity(String universityName) {
    final original = _originalName(_universityRenames, universityName);
    return original.isEmpty ? universityName.trim() : original;
  }

  String _canonicalFaculty(String universityName, String facultyName) {
    final original = _originalName(
      _facultyRenames[canonicalUniversity(universityName)] ?? const {},
      facultyName,
    );
    return original.isEmpty ? facultyName.trim() : original;
  }

  int schoolGradeNumber(String grade) =>
      int.tryParse(
        RegExp(r'\d+').firstMatch(_canonicalGrade(grade))?.group(0) ?? '',
      ) ??
      0;

  String currentSchoolGradeName(String grade) =>
      _renamedName(_gradeRenames, grade);

  String currentUniversityYearName(String year) =>
      _renamedName(_yearRenames, year);

  String currentUniversityName(String universityName) =>
      _renamedName(_universityRenames, universityName);

  String currentFacultyName({
    required String universityName,
    required String facultyName,
  }) => _renamedName(
    _facultyRenames[canonicalUniversity(universityName)] ?? const {},
    facultyName,
  );

  String currentSchoolSubjectName({
    required String grade,
    required String subjectName,
    String stream = '',
  }) => _renamedName(
    _subjectRenames['${_canonicalGrade(grade)}|$stream'] ?? const {},
    subjectName,
  );

  String currentCampusCourseName({
    required String universityName,
    required String facultyName,
    required String year,
    required String courseName,
  }) => _renamedName(
    _courseRenames[_campusOfferingKey(
          universityName: canonicalUniversity(universityName),
          facultyName: _canonicalFaculty(universityName, facultyName),
          year: _canonicalYear(year),
        )] ??
        const {},
    courseName,
  );

  static bool _sameFields(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  List<String> get customSchoolGrades =>
      List.unmodifiable(_additionalSchoolGrades);

  List<String> get customUniversityYears =>
      List.unmodifiable(_additionalUniversityYears);

  List<String> get customUniversities =>
      List.unmodifiable(_additionalUniversities);

  List<String> customFacultiesFor(String universityName) => List.unmodifiable(
    _additionalFaculties[universityName.trim()] ?? const [],
  );

  List<String> customSchoolSubjectsFor(String grade, {String stream = ''}) =>
      List.unmodifiable(
        _additionalSchoolSubjects['${grade.trim()}|$stream'] ?? const [],
      );

  List<String> customCampusSubjectsFor({
    required String universityName,
    required String facultyName,
    required String year,
  }) => List.unmodifiable(
    _additionalCampusSubjects[_campusOfferingKey(
          universityName: universityName.trim(),
          facultyName: facultyName.trim(),
          year: year.trim(),
        )] ??
        const [],
  );

  List<CustomFacultyEntry> get customFacultyEntries {
    final entries = <CustomFacultyEntry>[];
    for (final university in universities) {
      for (final faculty in customFacultiesFor(university)) {
        entries.add(
          CustomFacultyEntry(universityName: university, faculty: faculty),
        );
      }
    }
    return List.unmodifiable(entries);
  }

  List<CustomSchoolSubjectEntry> get customSchoolSubjectEntries {
    final entries = <CustomSchoolSubjectEntry>[];
    for (final entry in _additionalSchoolSubjects.entries) {
      if (entry.value.isEmpty) continue;
      final separator = entry.key.lastIndexOf('|');
      final grade = separator == -1
          ? entry.key
          : entry.key.substring(0, separator);
      final stream = separator == -1 ? '' : entry.key.substring(separator + 1);
      for (final subject in entry.value) {
        entries.add(
          CustomSchoolSubjectEntry(
            grade: grade,
            stream: stream,
            subject: subject,
          ),
        );
      }
    }
    return List.unmodifiable(
      entries..sort(
        (a, b) =>
            '${a.scope}|${a.subject}'.compareTo('${b.scope}|${b.subject}'),
      ),
    );
  }

  List<CustomCampusCourseEntry> get customCampusCourseEntries {
    final entries = <CustomCampusCourseEntry>[];
    for (final entry in _additionalCampusSubjects.entries) {
      if (entry.value.isEmpty) continue;
      final decoded = jsonDecode(entry.key);
      if (decoded is! List || decoded.length != 3) continue;
      for (final course in entry.value) {
        entries.add(
          CustomCampusCourseEntry(
            universityName: '${decoded[0]}',
            facultyName: '${decoded[1]}',
            year: '${decoded[2]}',
            course: course,
          ),
        );
      }
    }
    return List.unmodifiable(
      entries..sort(
        (a, b) => '${a.scope}|${a.course}'.compareTo('${b.scope}|${b.course}'),
      ),
    );
  }

  List<String> get schoolGradeOptions => List.unmodifiable(
    ({...schoolGrades, ..._additionalSchoolGrades}.toList()
          ..sort(_naturalCompare))
        .map((grade) => _renamedName(_gradeRenames, grade)),
  );

  List<String> get universityYearOptions => List.unmodifiable(
    ({...universityYears, ..._additionalUniversityYears}.toList()
          ..sort(_naturalCompare))
        .map((year) => _renamedName(_yearRenames, year)),
  );

  bool addSchoolGrade(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty ||
        schoolGradeOptions.any(
          (existing) => existing.toLowerCase() == trimmedName.toLowerCase(),
        )) {
      return false;
    }
    _additionalSchoolGrades.add(trimmedName);
    notifyListeners();
    return true;
  }

  bool addUniversityYear(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty ||
        universityYearOptions.any(
          (existing) => existing.toLowerCase() == trimmedName.toLowerCase(),
        )) {
      return false;
    }
    _additionalUniversityYears.add(trimmedName);
    notifyListeners();
    return true;
  }

  List<String> get universities => List.unmodifiable(
    ({
      ...sriLankanInstitutionFaculties.keys,
      ..._additionalUniversities,
    }.toList()..sort()).map((name) => _renamedName(_universityRenames, name)),
  );

  List<Student> studentsFor(
    InstitutionType institutionType,
    String groupName, {
    String? universityName,
    String? facultyName,
    String? subjectName,
    String? schoolStream,
  }) {
    return List.unmodifiable(
      _students.where(
        (student) =>
            student.institutionType == institutionType &&
            student.attendanceGroup == groupName &&
            (universityName == null ||
                student.universityName == universityName) &&
            (facultyName == null || student.facultyName == facultyName) &&
            (subjectName == null || student.subjectName == subjectName) &&
            (schoolStream == null || student.schoolStream == schoolStream),
      ),
    );
  }

  List<String> facultiesFor(String universityName) {
    final university = universityName.trim();
    final canonical = canonicalUniversity(university);
    final renames = _facultyRenames[canonical] ?? const <String, String>{};
    return List.unmodifiable(
      {
        ...?sriLankanInstitutionFaculties[canonical]?.map(
          (faculty) => _renamedName(renames, faculty),
        ),
        ...?_additionalFaculties[university],
      }.toList()..sort(),
    );
  }

  bool addUniversity(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || universities.contains(trimmedName)) return false;
    _additionalUniversities.add(trimmedName);
    notifyListeners();
    return true;
  }

  bool addFaculty(String universityName, String facultyName) {
    final university = universityName.trim();
    final faculty = facultyName.trim();
    if (university.isEmpty ||
        faculty.isEmpty ||
        facultiesFor(
          university,
        ).any((existing) => existing.toLowerCase() == faculty.toLowerCase())) {
      return false;
    }
    _additionalFaculties.putIfAbsent(university, () => []).add(faculty);
    notifyListeners();
    return true;
  }

  List<String> schoolSubjectsFor(String grade, {String stream = ''}) {
    final trimmedGrade = grade.trim();
    final canonical = _canonicalGrade(trimmedGrade);
    final renames =
        _subjectRenames['$canonical|$stream'] ?? const <String, String>{};
    final baseSubjects = subjectsForSchoolGrade(
      canonical,
      stream: stream,
    ).map((subject) => _renamedName(renames, subject));
    final additional =
        _additionalSchoolSubjects['$trimmedGrade|$stream'] ?? const [];
    return List.unmodifiable({...baseSubjects, ...additional}.toList()..sort());
  }

  bool addSchoolSubject(
    String grade,
    String subjectName, {
    String stream = '',
  }) {
    final subject = subjectName.trim();
    if (grade.trim().isEmpty ||
        subject.isEmpty ||
        schoolSubjectsFor(
          grade,
          stream: stream,
        ).any((existing) => existing.toLowerCase() == subject.toLowerCase())) {
      return false;
    }
    _additionalSchoolSubjects
        .putIfAbsent('$grade|$stream', () => [])
        .add(subject);
    notifyListeners();
    return true;
  }

  List<String> campusSubjectsFor({
    required String universityName,
    required String facultyName,
    required String year,
  }) {
    final canonicalUniversityName = canonicalUniversity(universityName);
    final canonicalFacultyName = _canonicalFaculty(universityName, facultyName);
    final renames =
        _courseRenames[_campusOfferingKey(
          universityName: canonicalUniversityName,
          facultyName: canonicalFacultyName,
          year: _canonicalYear(year),
        )] ??
        const <String, String>{};
    return List.unmodifiable(
      {
        ...catalogCoursesFor(
          canonicalUniversityName,
          canonicalFacultyName,
        ).map((course) => _renamedName(renames, course)),
        ...?_additionalCampusSubjects[_campusOfferingKey(
          universityName: universityName.trim(),
          facultyName: facultyName.trim(),
          year: year.trim(),
        )],
      }.toList()..sort(),
    );
  }

  List<String> catalogCourses({
    required String universityName,
    required String facultyName,
  }) => catalogCoursesFor(
    canonicalUniversity(universityName),
    _canonicalFaculty(universityName, facultyName),
  );

  List<String> get catalogInstitutions => List.unmodifiable(
    sriLankanInstitutions.map((institution) => institution.name).toList()
      ..sort(),
  );

  List<String> get catalogStateUniversities => List.unmodifiable(
    sriLankanStateUniversities.map((institution) => institution.name).toList(),
  );

  List<String> get catalogUniversityColleges => List.unmodifiable(
    sriLankanUniversityColleges.map((institution) => institution.name).toList(),
  );

  UniversityKind? kindFor(String universityName) =>
      universityKindFor(canonicalUniversity(universityName));

  bool isBuiltInInstitution(String universityName) =>
      isCatalogInstitution(canonicalUniversity(universityName));

  bool addCampusSubject({
    required String universityName,
    required String facultyName,
    required String year,
    required String subjectName,
  }) {
    final subject = subjectName.trim();
    if (universityName.trim().isEmpty ||
        facultyName.trim().isEmpty ||
        year.trim().isEmpty ||
        subject.isEmpty ||
        campusSubjectsFor(
          universityName: universityName,
          facultyName: facultyName,
          year: year,
        ).any((existing) => existing.toLowerCase() == subject.toLowerCase())) {
      return false;
    }
    _additionalCampusSubjects
        .putIfAbsent(
          _campusOfferingKey(
            universityName: universityName,
            facultyName: facultyName,
            year: year,
          ),
          () => [],
        )
        .add(subject);
    notifyListeners();
    return true;
  }

  String _campusOfferingKey({
    required String universityName,
    required String facultyName,
    required String year,
  }) => jsonEncode([universityName, facultyName, year]);

  bool renameSchoolGrade(String currentName, String newName) {
    final target = newName.trim();
    if (target.isEmpty) return false;
    if (!_sameNames(target, currentName) &&
        _containsName(schoolGradeOptions, target)) {
      return false;
    }
    final customIndex = _indexOfName(_additionalSchoolGrades, currentName);
    if (customIndex != -1) {
      final from = _additionalSchoolGrades[customIndex];
      _additionalSchoolGrades[customIndex] = target;
      _applySchoolGradeRename(from, target);
      return true;
    }
    final original = _originalName(_gradeRenames, currentName).isEmpty
        ? currentName.trim()
        : _originalName(_gradeRenames, currentName);
    if (!_containsName(schoolGrades, original)) return false;
    _gradeRenames[original] = target;
    _applySchoolGradeRename(currentName, target);
    return true;
  }

  void _applySchoolGradeRename(String from, String target) {
    _remapSchoolSubjectKeys(from, target);
    _replaceStudents(
      (student) =>
          student.institutionType == InstitutionType.school &&
          student.attendanceGroup == from,
      (student) => student.copyWith(
        groupName: target,
        className: _replaceClassTokens(student.className, from, target),
      ),
    );
    _remapInstructors((fields) {
      if (fields['groupName'] == from) fields['groupName'] = target;
    });
    notifyListeners();
  }

  bool renameUniversityYear(String currentName, String newName) {
    final target = newName.trim();
    if (target.isEmpty) return false;
    if (!_sameNames(target, currentName) &&
        _containsName(universityYearOptions, target)) {
      return false;
    }
    final customIndex = _indexOfName(_additionalUniversityYears, currentName);
    if (customIndex != -1) {
      final from = _additionalUniversityYears[customIndex];
      _additionalUniversityYears[customIndex] = target;
      _applyUniversityYearRename(from, target);
      return true;
    }
    final original = _originalName(_yearRenames, currentName).isEmpty
        ? currentName.trim()
        : _originalName(_yearRenames, currentName);
    if (!_containsName(universityYears, original)) return false;
    _yearRenames[original] = target;
    _applyUniversityYearRename(currentName, target);
    return true;
  }

  void _applyUniversityYearRename(String from, String target) {
    _replaceStudents(
      (student) =>
          student.institutionType == InstitutionType.university &&
          student.attendanceGroup == from,
      (student) => student.copyWith(
        groupName: target,
        className: _replaceClassTokens(student.className, from, target),
      ),
    );
    _remapCampusOfferings((fields) {
      if (fields[2] == from) fields[2] = target;
    });
    _remapInstructors((fields) {
      if (fields['groupName'] == from) fields['groupName'] = target;
    });
    notifyListeners();
  }

  bool renameUniversity(String currentName, String newName) {
    final target = newName.trim();
    if (target.isEmpty) return false;
    if (!_sameNames(target, currentName) &&
        _containsName(universities, target)) {
      return false;
    }
    final customIndex = _indexOfName(
      _additionalUniversities.toList(),
      currentName,
    );
    if (customIndex != -1) {
      final from = _additionalUniversities.elementAt(customIndex);
      _additionalUniversities
        ..remove(from)
        ..add(target);
      _moveAdditionalFaculties(from, target);
      _applyUniversityRename(from, target);
      return true;
    }
    final original = _originalName(_universityRenames, currentName).isEmpty
        ? currentName.trim()
        : _originalName(_universityRenames, currentName);
    if (!_containsName(sriLankanInstitutionFaculties.keys, original)) {
      return false;
    }
    _universityRenames[original] = target;
    _moveAdditionalFaculties(currentName, target);
    _applyUniversityRename(currentName, target);
    return true;
  }

  void _moveAdditionalFaculties(String from, String to) {
    final faculties = _additionalFaculties.remove(from);
    if (faculties != null && faculties.isNotEmpty) {
      _additionalFaculties[to] = faculties;
    }
  }

  void _applyUniversityRename(String from, String target) {
    _replaceStudents(
      (student) =>
          student.institutionType == InstitutionType.university &&
          student.universityName == from,
      (student) => student.copyWith(
        universityName: target,
        className: _replaceClassTokens(student.className, from, target),
      ),
    );
    _remapCampusOfferings((fields) {
      if (fields[0] == from) fields[0] = target;
    });
    _remapInstructors((fields) {
      if (fields['universityName'] == from) fields['universityName'] = target;
    });
    notifyListeners();
  }

  bool renameFaculty({
    required String universityName,
    required String currentName,
    required String newName,
  }) {
    final university = universityName.trim();
    final target = newName.trim();
    if (university.isEmpty || target.isEmpty) return false;
    if (!_sameNames(target, currentName) &&
        _containsName(facultiesFor(university), target)) {
      return false;
    }
    final customFaculties = _additionalFaculties[university];
    final customIndex = customFaculties == null
        ? -1
        : _indexOfName(customFaculties, currentName);
    if (customFaculties != null && customIndex != -1) {
      final from = customFaculties[customIndex];
      customFaculties[customIndex] = target;
      _applyFacultyRename(
        universityName: university,
        currentName: from,
        target: target,
      );
      return true;
    }
    final canonical = canonicalUniversity(university);
    final existing = _originalName(
      _facultyRenames[canonical] ?? const {},
      currentName,
    );
    final original = existing.isEmpty ? currentName.trim() : existing;
    if (!_containsName(
      sriLankanInstitutionFaculties[canonical] ?? const [],
      original,
    )) {
      return false;
    }
    (_facultyRenames[canonical] ??= <String, String>{})[original] = target;
    _applyFacultyRename(
      universityName: university,
      currentName: currentName,
      target: target,
    );
    return true;
  }

  void _applyFacultyRename({
    required String universityName,
    required String currentName,
    required String target,
  }) {
    _replaceStudents(
      (student) =>
          student.institutionType == InstitutionType.university &&
          student.universityName == universityName &&
          student.facultyName == currentName,
      (student) => student.copyWith(
        facultyName: target,
        className: _replaceClassTokens(student.className, currentName, target),
      ),
    );
    _remapCampusOfferings((fields) {
      if (fields[0] == universityName && fields[1] == currentName) {
        fields[1] = target;
      }
    });
    _remapInstructors((fields) {
      if (fields['universityName'] == universityName &&
          fields['facultyName'] == currentName) {
        fields['facultyName'] = target;
      }
    });
    notifyListeners();
  }

  bool renameSchoolSubject({
    required String grade,
    required String currentName,
    required String newName,
    String stream = '',
  }) {
    final trimmedGrade = grade.trim();
    final target = newName.trim();
    if (trimmedGrade.isEmpty || target.isEmpty) return false;
    if (!_sameNames(target, currentName) &&
        _containsName(
          schoolSubjectsFor(trimmedGrade, stream: stream),
          target,
        )) {
      return false;
    }
    final customSubjects = _additionalSchoolSubjects['$trimmedGrade|$stream'];
    final customIndex = customSubjects == null
        ? -1
        : _indexOfName(customSubjects, currentName);
    if (customSubjects != null && customIndex != -1) {
      final from = customSubjects[customIndex];
      customSubjects[customIndex] = target;
      _applySchoolSubjectRename(
        grade: trimmedGrade,
        stream: stream,
        currentName: from,
        target: target,
      );
      return true;
    }
    final canonical = _canonicalGrade(trimmedGrade);
    final renames =
        _subjectRenames['$canonical|$stream'] ?? const <String, String>{};
    final existing = _originalName(renames, currentName);
    final original = existing.isEmpty ? currentName.trim() : existing;
    if (!_containsName(
      subjectsForSchoolGrade(canonical, stream: stream),
      original,
    )) {
      return false;
    }
    _subjectRenames['$canonical|$stream'] = {...renames, original: target};
    _applySchoolSubjectRename(
      grade: trimmedGrade,
      stream: stream,
      currentName: currentName,
      target: target,
    );
    return true;
  }

  void _applySchoolSubjectRename({
    required String grade,
    required String stream,
    required String currentName,
    required String target,
  }) {
    _replaceStudents(
      (student) =>
          student.institutionType == InstitutionType.school &&
          student.attendanceGroup == grade &&
          student.schoolStream == stream &&
          student.subjectName == currentName,
      (student) => student.copyWith(
        subjectName: target,
        className: _replaceClassTokens(student.className, currentName, target),
      ),
    );
    _remapInstructors((fields) {
      if (fields['groupName'] == grade &&
          fields['schoolStream'] == stream &&
          fields['subjectName'] == currentName) {
        fields['subjectName'] = target;
      }
    });
    notifyListeners();
  }

  bool renameCampusSubject({
    required String universityName,
    required String facultyName,
    required String year,
    required String currentName,
    required String newName,
  }) {
    final university = universityName.trim();
    final faculty = facultyName.trim();
    final campusYear = year.trim();
    final target = newName.trim();
    if (university.isEmpty ||
        faculty.isEmpty ||
        campusYear.isEmpty ||
        target.isEmpty) {
      return false;
    }
    if (!_sameNames(target, currentName) &&
        _containsName(
          campusSubjectsFor(
            universityName: university,
            facultyName: faculty,
            year: campusYear,
          ),
          target,
        )) {
      return false;
    }
    final customCourses =
        _additionalCampusSubjects[_campusOfferingKey(
          universityName: university,
          facultyName: faculty,
          year: campusYear,
        )];
    final customIndex = customCourses == null
        ? -1
        : _indexOfName(customCourses, currentName);
    if (customCourses != null && customIndex != -1) {
      final from = customCourses[customIndex];
      customCourses[customIndex] = target;
      _applyCampusCourseRename(
        universityName: university,
        facultyName: faculty,
        year: campusYear,
        currentName: from,
        target: target,
      );
      return true;
    }
    final canonicalUniversityName = canonicalUniversity(university);
    final canonicalFacultyName = _canonicalFaculty(university, faculty);
    final offeringKey = _campusOfferingKey(
      universityName: canonicalUniversityName,
      facultyName: canonicalFacultyName,
      year: _canonicalYear(campusYear),
    );
    final renames = _courseRenames[offeringKey] ?? const <String, String>{};
    final existing = _originalName(renames, currentName);
    final original = existing.isEmpty ? currentName.trim() : existing;
    if (!_containsName(
      catalogCoursesFor(canonicalUniversityName, canonicalFacultyName),
      original,
    )) {
      return false;
    }
    _courseRenames[offeringKey] = {...renames, original: target};
    _applyCampusCourseRename(
      universityName: university,
      facultyName: faculty,
      year: campusYear,
      currentName: currentName,
      target: target,
    );
    return true;
  }

  void _applyCampusCourseRename({
    required String universityName,
    required String facultyName,
    required String year,
    required String currentName,
    required String target,
  }) {
    _replaceStudents(
      (student) =>
          student.institutionType == InstitutionType.university &&
          student.universityName == universityName &&
          student.facultyName == facultyName &&
          student.attendanceGroup == year &&
          student.subjectName == currentName,
      (student) => student.copyWith(
        subjectName: target,
        className: _replaceClassTokens(student.className, currentName, target),
      ),
    );
    _remapInstructors((fields) {
      if (fields['groupName'] == year &&
          fields['universityName'] == universityName &&
          fields['facultyName'] == facultyName &&
          fields['subjectName'] == currentName) {
        fields['subjectName'] = target;
      }
    });
    notifyListeners();
  }

  static String _replaceClassTokens(String label, String from, String to) {
    if (from.isEmpty || label.isEmpty) return label;
    if (label == from) return to;
    if (label.startsWith('$from-')) {
      return '$to${label.substring(from.length)}';
    }
    if (label.contains(' · ')) {
      return label
          .split(' · ')
          .map((part) => part == from ? to : part)
          .join(' · ');
    }
    return label;
  }

  void _replaceStudents(
    bool Function(Student student) matches,
    Student Function(Student student) update,
  ) {
    for (var index = 0; index < _students.length; index++) {
      final student = _students[index];
      if (matches(student)) _students[index] = update(student);
    }
  }

  void _remapSchoolSubjectKeys(String from, String to) {
    final remapped = <String, List<String>>{};
    for (final entry in _additionalSchoolSubjects.entries.toList()) {
      final separator = entry.key.lastIndexOf('|');
      final grade = separator == -1
          ? entry.key
          : entry.key.substring(0, separator);
      if (grade != from) continue;
      final stream = separator == -1 ? '' : entry.key.substring(separator + 1);
      remapped['$to|$stream'] = entry.value;
    }
    _additionalSchoolSubjects.addAll(remapped);
  }

  void _remapCampusOfferings(void Function(List<String> fields) update) {
    final remapped = <String, List<String>>{};
    for (final entry in _additionalCampusSubjects.entries.toList()) {
      final decoded = jsonDecode(entry.key);
      if (decoded is! List || decoded.length != 3) continue;
      final fields = decoded.map((value) => '$value').toList();
      final original = List<String>.from(fields);
      update(fields);
      if (_sameFields(fields, original)) continue;
      remapped[_campusOfferingKey(
            universityName: fields[0],
            facultyName: fields[1],
            year: fields[2],
          )] =
          entry.value;
    }
    _additionalCampusSubjects.addAll(remapped);
  }

  void _remapInstructors(void Function(Map<String, String> fields) update) {
    final remapped = <String, String>{};
    for (final entry in _instructorsByOffering.entries.toList()) {
      final decoded = jsonDecode(entry.key);
      if (decoded is! List || decoded.length != 6) continue;
      final type = InstitutionType.values.firstWhere(
        (value) => value.name == '${decoded[0]}',
        orElse: () => InstitutionType.school,
      );
      final fields = <String, String>{
        'groupName': '${decoded[1]}',
        'subjectName': '${decoded[2]}',
        'schoolStream': '${decoded[3]}',
        'universityName': '${decoded[4]}',
        'facultyName': '${decoded[5]}',
      };
      final original = Map<String, String>.from(fields);
      update(fields);
      if (_sameFields(fields.values.toList(), original.values.toList())) {
        continue;
      }
      remapped[_offeringKey(
            institutionType: type,
            groupName: fields['groupName']!,
            subjectName: fields['subjectName']!,
            schoolStream: fields['schoolStream']!,
            universityName: fields['universityName']!,
            facultyName: fields['facultyName']!,
          )] =
          entry.value;
    }
    _instructorsByOffering.addAll(remapped);
  }

  String instructorFor({
    required InstitutionType institutionType,
    required String groupName,
    String subjectName = '',
    String schoolStream = '',
    String universityName = '',
    String facultyName = '',
  }) {
    return _instructorsByOffering[_offeringKey(
          institutionType: institutionType,
          groupName: groupName,
          subjectName: subjectName,
          schoolStream: schoolStream,
          universityName: universityName,
          facultyName: facultyName,
        )] ??
        '';
  }

  void setInstructor({
    required InstitutionType institutionType,
    required String groupName,
    required String name,
    String subjectName = '',
    String schoolStream = '',
    String universityName = '',
    String facultyName = '',
  }) {
    final key = _offeringKey(
      institutionType: institutionType,
      groupName: groupName,
      subjectName: subjectName,
      schoolStream: schoolStream,
      universityName: universityName,
      facultyName: facultyName,
    );
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _instructorsByOffering.remove(key);
    } else {
      _instructorsByOffering[key] = trimmedName;
    }
    notifyListeners();
  }

  String _offeringKey({
    required InstitutionType institutionType,
    required String groupName,
    required String subjectName,
    required String schoolStream,
    required String universityName,
    required String facultyName,
  }) {
    return jsonEncode([
      institutionType.name,
      groupName,
      subjectName,
      institutionType == InstitutionType.school ? schoolStream : '',
      institutionType == InstitutionType.university ? universityName : '',
      institutionType == InstitutionType.university ? facultyName : '',
    ]);
  }

  static String keyFor(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String get todayKey => keyFor(DateTime.now());

  List<int> get attendanceYears {
    final years = <int>{DateTime.now().year};
    for (final dateKey in _records.keys) {
      final date = DateTime.tryParse(dateKey);
      if (date != null) years.add(date.year);
    }
    return List.unmodifiable(years.toList()..sort((a, b) => b.compareTo(a)));
  }

  AttendancePeriodSummary reportForStudent(
    String studentId, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    var presentDays = 0;
    var lateDays = 0;
    var absentDays = 0;

    for (final entry in _records.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) {
        continue;
      }

      switch (entry.value[studentId]) {
        case AttendanceStatus.present:
          presentDays++;
        case AttendanceStatus.late:
          lateDays++;
        case AttendanceStatus.absent:
          absentDays++;
        case null:
          break;
      }
    }

    return AttendancePeriodSummary(
      presentDays: presentDays,
      lateDays: lateDays,
      absentDays: absentDays,
    );
  }

  List<String> markedDatesFor({
    required DateTime startDate,
    required DateTime endDate,
    required Iterable<String> studentIds,
  }) {
    final ids = studentIds.toSet();
    if (ids.isEmpty) return const <String>[];
    final dates = <String>[];
    for (final entry in _records.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null || date.isBefore(startDate) || date.isAfter(endDate)) {
        continue;
      }
      if (entry.value.keys.any(ids.contains)) {
        dates.add(entry.key);
      }
    }
    dates.sort();
    return List.unmodifiable(dates);
  }

  bool addStudent({
    required String name,
    String className = '',
    InstitutionType institutionType = InstitutionType.school,
    String? groupName,
    String? universityName,
    String? facultyName,
    String? subjectName,
    String? schoolStream,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    final selectedGroup = groupName?.trim() ?? '';
    final trimmedClass = className.trim();
    final assignedGroup = selectedGroup.isNotEmpty
        ? selectedGroup
        : Student(
            id: '',
            name: trimmedName,
            className: trimmedClass.isEmpty ? 'Unassigned' : trimmedClass,
            institutionType: institutionType,
          ).attendanceGroup;
    final selectedSubject = subjectName?.trim() ?? '';
    final selectedStream = institutionType == InstitutionType.school
        ? schoolStream?.trim() ?? ''
        : '';
    final selectedUniversity = institutionType == InstitutionType.university
        ? ((universityName?.trim().isNotEmpty ?? false)
              ? universityName!.trim()
              : 'Unassigned institution')
        : '';
    final selectedFaculty = institutionType == InstitutionType.university
        ? ((facultyName?.trim().isNotEmpty ?? false)
              ? facultyName!.trim()
              : 'Unassigned faculty')
        : '';

    final alreadyExists = _students.any(
      (student) =>
          student.institutionType == institutionType &&
          (institutionType == InstitutionType.university
              ? student.universityName == selectedUniversity &&
                    student.facultyName == selectedFaculty &&
                    student.attendanceGroup == assignedGroup &&
                    student.subjectName == selectedSubject
              : student.attendanceGroup == assignedGroup &&
                    student.subjectName == selectedSubject &&
                    student.schoolStream == selectedStream) &&
          student.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (alreadyExists) return false;

    final displayClass = trimmedClass.isEmpty
        ? (institutionType == InstitutionType.university
              ? '$selectedFaculty · ${selectedSubject.isEmpty ? assignedGroup : '$selectedSubject · $assignedGroup'}'
              : assignedGroup)
        : trimmedClass;

    _students.add(
      Student(
        id: '${_nextId++}',
        name: trimmedName,
        className: displayClass,
        institutionType: institutionType,
        groupName: assignedGroup,
        universityName: selectedUniversity,
        facultyName: selectedFaculty,
        subjectName: selectedSubject,
        schoolStream: selectedStream,
      ),
    );
    notifyListeners();
    return true;
  }

  AttendanceStatus? statusFor(String dateKey, String studentId) {
    return _records[dateKey]?[studentId];
  }

  DateTime? markedAtFor(String dateKey) => _markedAt[dateKey];

  List<AttendanceLogEntry> get logs => List.unmodifiable(_logs);

  List<AttendanceLogEntry> logsForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    InstitutionType? institutionType,
    String groupName = '',
    String universityName = '',
    String facultyName = '',
    String schoolStream = '',
    String subjectName = '',
  }) {
    final entries =
        _logs.where((entry) {
          final date = DateTime.tryParse(entry.dateKey);
          if (date == null ||
              date.isBefore(startDate) ||
              date.isAfter(endDate)) {
            return false;
          }
          if (institutionType != null &&
              entry.institutionType != institutionType) {
            return false;
          }
          if (groupName.isNotEmpty && entry.groupName != groupName) {
            return false;
          }
          if (universityName.isNotEmpty &&
              entry.universityName != universityName) {
            return false;
          }
          if (facultyName.isNotEmpty && entry.facultyName != facultyName) {
            return false;
          }
          if (schoolStream.isNotEmpty && entry.schoolStream != schoolStream) {
            return false;
          }
          if (subjectName.isNotEmpty && entry.subjectName != subjectName) {
            return false;
          }
          return true;
        }).toList()..sort((a, b) {
          final byDate = b.markedAt.compareTo(a.markedAt);
          if (byDate != 0) return byDate;
          return a.subjectLabel.compareTo(b.subjectLabel);
        });
    return List.unmodifiable(entries);
  }

  void recordAttendanceLog({
    required String dateKey,
    required InstitutionType institutionType,
    required String groupName,
    String subjectName = '',
    String schoolStream = '',
    String universityName = '',
    String facultyName = '',
    String instructorName = '',
    required Iterable<String> studentIds,
  }) {
    final ids = studentIds.toSet();
    if (ids.isEmpty) return;
    final entry = AttendanceLogEntry(
      dateKey: dateKey,
      markedAt: _markedAt[dateKey] ?? DateTime.now(),
      institutionType: institutionType,
      groupName: groupName,
      subjectName: subjectName,
      schoolStream: schoolStream,
      universityName: universityName,
      facultyName: facultyName,
      instructorName: instructorName,
      presentCount: countFor(
        dateKey,
        AttendanceStatus.present,
        studentIds: ids,
      ),
      lateCount: countFor(dateKey, AttendanceStatus.late, studentIds: ids),
      absentCount: countFor(dateKey, AttendanceStatus.absent, studentIds: ids),
    );
    final offering = entry.scopeKey;
    final subject = entry.subjectLabel;
    _logs.removeWhere(
      (existing) =>
          existing.dateKey == entry.dateKey &&
          existing.scopeKey == offering &&
          existing.subjectLabel == subject,
    );
    _logs.add(entry);
    notifyListeners();
  }

  void clearLogs() {
    if (_logs.isEmpty) return;
    _logs.clear();
    notifyListeners();
  }

  String? markedAtLabelFor(String dateKey) {
    final markedAt = _markedAt[dateKey];
    if (markedAt == null) return null;
    final hour = markedAt.hour.toString().padLeft(2, '0');
    final minute = markedAt.minute.toString().padLeft(2, '0');
    final second = markedAt.second.toString().padLeft(2, '0');
    return '${markedAt.year}-${markedAt.month.toString().padLeft(2, '0')}-'
        '${markedAt.day.toString().padLeft(2, '0')} $hour:$minute:$second';
  }

  void _recordMarkedAt(String dateKey) {
    _markedAt[dateKey] = DateTime.now();
  }

  void setStatus(String dateKey, String studentId, AttendanceStatus status) {
    _records.putIfAbsent(dateKey, () => {})[studentId] = status;
    _recordMarkedAt(dateKey);
    notifyListeners();
  }

  void clearStatus(String dateKey, String studentId) {
    final removed = _records[dateKey]?.remove(studentId) != null;
    if (removed) {
      _recordMarkedAt(dateKey);
      notifyListeners();
    }
  }

  void markAllPresent(String dateKey, {Iterable<String>? studentIds}) {
    final statuses = _records.putIfAbsent(dateKey, () => {});
    for (final studentId
        in studentIds ?? students.map((student) => student.id)) {
      statuses[studentId] = AttendanceStatus.present;
    }
    _recordMarkedAt(dateKey);
    notifyListeners();
  }

  void clearDate(String dateKey, {Iterable<String>? studentIds}) {
    if (studentIds == null) {
      var removedAny = _records.remove(dateKey) != null;
      if (_markedAt.remove(dateKey) != null) removedAny = true;
      if (removedAny) notifyListeners();
      return;
    }

    final statuses = _records[dateKey];
    if (statuses == null) return;
    var changed = false;
    for (final studentId in studentIds) {
      changed = statuses.remove(studentId) != null || changed;
    }
    if (changed) {
      _recordMarkedAt(dateKey);
      notifyListeners();
    }
  }

  int countFor(
    String dateKey,
    AttendanceStatus status, {
    Iterable<String>? studentIds,
  }) {
    final statuses = _records[dateKey];
    if (statuses == null) return 0;
    final ids = studentIds?.toSet();
    return statuses.entries
        .where(
          (entry) =>
              entry.value == status && (ids == null || ids.contains(entry.key)),
        )
        .length;
  }

  int markedCount(String dateKey, {Iterable<String>? studentIds}) {
    final statuses = _records[dateKey];
    if (statuses == null) return 0;
    if (studentIds == null) return statuses.length;
    final ids = studentIds.toSet();
    return statuses.keys.where(ids.contains).length;
  }

  int attendedCount(String dateKey, {Iterable<String>? studentIds}) {
    return countFor(dateKey, AttendanceStatus.present, studentIds: studentIds) +
        countFor(dateKey, AttendanceStatus.late, studentIds: studentIds);
  }

  double attendanceRate(String dateKey, {Iterable<String>? studentIds}) {
    final marked = markedCount(dateKey, studentIds: studentIds);
    if (marked == 0) return 0;
    return (attendedCount(dateKey, studentIds: studentIds) / marked) * 100;
  }
}
