import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_store.dart';
import 'school_subject_catalog.dart';
import 'setup_editor.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.store});

  final AttendanceStore? store;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);

  InstitutionType _institutionType = InstitutionType.school;
  String _selectedGroup = 'Grade 8';
  String _selectedSubject = allSubjectsOption;
  String _selectedStream = '';
  String _selectedUniversity = 'University of Colombo';
  String _selectedFaculty = 'Faculty of Arts';
  String _selectedCourse = allSubjectsOption;
  late int _selectedMonth;
  late int _selectedYear;

  InstitutionType _logType = InstitutionType.school;
  String _logSchoolGroup = 'Grade 8';
  String _logSchoolSubject = allSubjectsOption;
  String _logSchoolStream = '';
  String _logUniversity = 'University of Colombo';
  String _logFaculty = 'Faculty of Arts';
  String _logYear = 'First Year';
  String _logCourse = allSubjectsOption;

  List<String> get _groups => _institutionType == InstitutionType.school
      ? (widget.store ?? AttendanceStore.instance).schoolGradeOptions
      : (widget.store ?? AttendanceStore.instance).universityYearOptions;

  bool get _hasAdvancedLevelSubjects =>
      (widget.store ?? AttendanceStore.instance).schoolGradeNumber(
        _selectedGroup,
      ) >=
      12;

  AttendanceStore get _store => widget.store ?? AttendanceStore.instance;

  bool get _isUniversity => _institutionType == InstitutionType.university;

  String get _effectiveSubject =>
      _isUniversity ? _selectedCourse : _selectedSubject;

  List<Student> get _studentsForSelection => _store.studentsFor(
    _institutionType,
    _selectedGroup,
    universityName: _isUniversity ? _selectedUniversity : null,
    facultyName: _isUniversity ? _selectedFaculty : null,
    subjectName: _effectiveSubject == allSubjectsOption
        ? null
        : _effectiveSubject,
    schoolStream: !_isUniversity && _selectedStream.isNotEmpty
        ? _selectedStream
        : null,
  );

  String get _selectionLabel {
    final parts = <String>[
      if (_isUniversity) _selectedUniversity,
      if (_isUniversity) _selectedFaculty,
      _selectedGroup,
      if (_effectiveSubject != allSubjectsOption) _effectiveSubject,
      if (!_isUniversity && _selectedStream.isNotEmpty) _selectedStream,
    ];
    return parts.where((part) => part.isNotEmpty).join(' · ');
  }

  Future<void> _openEditor(
    SetupEditorKind kind, {
    String universityName = '',
    String facultyName = '',
    String grade = '',
    String stream = '',
    String year = '',
  }) async {
    await openSetupEditor(
      context,
      _store,
      kind,
      universityName: universityName,
      facultyName: facultyName,
      grade: grade,
      stream: stream,
      year: year,
    );
    if (!mounted) return;
    setState(() {
      final store = _store;
      final university = store.currentUniversityName(_selectedUniversity);
      _selectedUniversity = university;
      _selectedGroup = store.currentUniversityYearName(
        store.currentSchoolGradeName(_selectedGroup),
      );
      _selectedFaculty = store.currentFacultyName(
        universityName: university,
        facultyName: _selectedFaculty,
      );
      final subject = store.currentSchoolSubjectName(
        grade: _selectedGroup,
        stream: _selectedStream,
        subjectName: _selectedSubject,
      );
      _selectedSubject = store.currentCampusCourseName(
        universityName: university,
        facultyName: _selectedFaculty,
        year: _selectedGroup,
        courseName: subject,
      );
      _selectedCourse = store.currentCampusCourseName(
        universityName: university,
        facultyName: _selectedFaculty,
        year: _selectedGroup,
        courseName: _selectedCourse,
      );
      final logUniversity = store.currentUniversityName(_logUniversity);
      _logUniversity = logUniversity;
      _logSchoolGroup = store.currentSchoolGradeName(_logSchoolGroup);
      _logYear = store.currentUniversityYearName(
        store.currentSchoolGradeName(_logYear),
      );
      _logFaculty = store.currentFacultyName(
        universityName: logUniversity,
        facultyName: _logFaculty,
      );
      final logSchoolSubject = store.currentSchoolSubjectName(
        grade: _logSchoolGroup,
        stream: _logSchoolStream,
        subjectName: _logSchoolSubject,
      );
      _logSchoolSubject = store.currentCampusCourseName(
        universityName: logUniversity,
        facultyName: _logFaculty,
        year: _logSchoolGroup,
        courseName: logSchoolSubject,
      );
      _logCourse = store.currentCampusCourseName(
        universityName: logUniversity,
        facultyName: _logFaculty,
        year: _logYear,
        courseName: _logCourse,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store ?? AttendanceStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final students = _studentsForSelection;
        final years = store.attendanceYears;
        final monthStart = DateTime(_selectedYear, _selectedMonth, 1);
        final monthEnd = DateTime(_selectedYear, _selectedMonth + 1, 0);
        var present = 0;
        var late = 0;
        var absent = 0;
        for (final student in students) {
          final summary = store.reportForStudent(
            student.id,
            startDate: monthStart,
            endDate: monthEnd,
          );
          present += summary.presentDays;
          late += summary.lateDays;
          absent += summary.absentDays;
        }
        final sessionDates = store.markedDatesFor(
          startDate: monthStart,
          endDate: monthEnd,
          studentIds: students.map((student) => student.id),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Reports',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Attendance reports',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a grade and subject to see the list and totals.',
                  style: GoogleFonts.inter(fontSize: 13, color: textGrey),
                ),
                const SizedBox(height: 18),
                _buildFilters(years, store),
                const SizedBox(height: 18),
                _buildTotalsCard(
                  present,
                  late,
                  absent,
                  sessionDates.length,
                  students.length,
                ),
                const SizedBox(height: 18),
                _buildAttendanceList(store, students, sessionDates),
                const SizedBox(height: 18),
                _buildLogSection(context, store),
                const SizedBox(height: 18),
                Text(
                  'Student attendance averages',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monthly and annual averages. Late arrivals are listed '
                  'separately.',
                  style: GoogleFonts.inter(fontSize: 13, color: textGrey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectionLabel.isEmpty ? _selectedGroup : _selectionLabel} students',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                    ),
                    Text(
                      '${students.length}',
                      style: GoogleFonts.inter(
                        color: textGrey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (students.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'No students in this group yet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: textGrey),
                    ),
                  ),
                for (final student in students)
                  Padding(
                    key: ValueKey('report-student-${student.id}'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StudentPeriodReport(
                      student: student,
                      monthLabel: _monthNames[_selectedMonth - 1],
                      monthly: store.reportForStudent(
                        student.id,
                        startDate: monthStart,
                        endDate: monthEnd,
                      ),
                      annual: store.reportForStudent(
                        student.id,
                        startDate: DateTime(_selectedYear, 1, 1),
                        endDate: DateTime(_selectedYear, 12, 31),
                      ),
                      year: _selectedYear,
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/dashboard',
                      (route) => false,
                    ),
                    icon: const Icon(Icons.dashboard_rounded),
                    label: const Text('Back to dashboard'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<AttendanceLogEntry> _logsForType(
    AttendanceStore store,
    InstitutionType type,
  ) {
    final isUniversity = type == InstitutionType.university;
    final subject = isUniversity ? _logCourse : _logSchoolSubject;
    return store.logsForPeriod(
      startDate: DateTime(_selectedYear, _selectedMonth, 1),
      endDate: DateTime(_selectedYear, _selectedMonth + 1, 0),
      institutionType: type,
      groupName: isUniversity ? _logYear : _logSchoolGroup,
      universityName: isUniversity ? _logUniversity : '',
      facultyName: isUniversity ? _logFaculty : '',
      schoolStream: isUniversity ? '' : _logSchoolStream,
      subjectName: subject == allSubjectsOption ? '' : subject,
    );
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get _periodLabel =>
      '${_monthNames[_selectedMonth - 1]} $_selectedYear';

  String get _scopeWithPeriod => _selectionLabel.isEmpty
      ? _periodLabel
      : '$_selectionLabel · $_periodLabel';

  Widget _buildTotalsCard(
    int present,
    int late,
    int absent,
    int sessions,
    int studentCount,
  ) {
    final marks = present + late + absent;
    final rate = marks == 0 ? 0 : (((present + late) / marks) * 100).round();
    final studentWord = studentCount == 1 ? 'student' : 'students';
    Widget chip(String label, String value, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textGrey,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      key: const Key('report-totals'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.functions_rounded, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total marked attendance',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _scopeWithPeriod,
            style: GoogleFonts.inter(fontSize: 12.5, color: textGrey),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$marks',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'total marks',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      Text(
                        '$studentCount $studentWord in this selection',
                        style: GoogleFonts.inter(fontSize: 12, color: textGrey),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$rate%',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              chip('Present', '$present', const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              chip('Late', '$late', const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              chip('Absent', '$absent', const Color(0xFFDC2626)),
              const SizedBox(width: 8),
              chip('Sessions', '$sessions', const Color(0xFF2563EB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(
    AttendanceStore store,
    List<Student> students,
    List<String> sessionDates,
  ) {
    return Column(
      key: const Key('report-attendance-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.list_alt_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text(
              'Attendance list',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _scopeWithPeriod,
          style: GoogleFonts.inter(fontSize: 12.5, color: textGrey),
        ),
        const SizedBox(height: 12),
        if (students.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Add students to this grade and subject to see the list.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textGrey),
            ),
          )
        else if (sessionDates.isEmpty)
          Container(
            key: const Key('report-attendance-empty'),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'No attendance has been marked for $_periodLabel yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textGrey),
            ),
          )
        else
          for (final dateKey in sessionDates.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReportDateCard(
                dateKey: dateKey,
                markedAt: store.markedAtFor(dateKey),
                students: students,
                store: store,
              ),
            ),
      ],
    );
  }

  Widget _buildLogFilters(AttendanceStore store) {
    final isUniversity = _logType == InstitutionType.university;

    Widget dropdown({
      required Key key,
      required String label,
      required String value,
      required List<String> options,
      required ValueChanged<String> onChanged,
    }) {
      return Expanded(
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          key: key,
          initialValue: options.contains(value) ? value : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      );
    }

    final showSchoolStream =
        !isUniversity && store.schoolGradeNumber(_logSchoolGroup) >= 12;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              dropdown(
                key: ValueKey('report-log-group-${_logType.name}'),
                label: isUniversity ? 'Year' : 'Grade',
                value: isUniversity ? _logYear : _logSchoolGroup,
                options: isUniversity
                    ? store.universityYearOptions
                    : store.schoolGradeOptions,
                onChanged: (value) {
                  setState(() {
                    if (isUniversity) {
                      _logYear = value;
                      _logCourse = allSubjectsOption;
                    } else {
                      _logSchoolGroup = value;
                      _logSchoolSubject = allSubjectsOption;
                      _logSchoolStream = '';
                    }
                  });
                },
              ),
              const SizedBox(width: 10),
              if (isUniversity)
                dropdown(
                  key: const Key('report-log-university'),
                  label: 'University / institute',
                  value: _logUniversity,
                  options: store.universities,
                  onChanged: (value) {
                    setState(() {
                      _logUniversity = value;
                      final newFaculties = store.facultiesFor(value);
                      _logFaculty = newFaculties.isEmpty
                          ? ''
                          : newFaculties.first;
                      _logCourse = allSubjectsOption;
                    });
                  },
                )
              else
                dropdown(
                  key: const Key('report-log-subject'),
                  label: 'Subject',
                  value: _logSchoolSubject,
                  options: [
                    allSubjectsOption,
                    ...store.schoolSubjectsFor(
                      _logSchoolGroup,
                      stream: _logSchoolStream,
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _logSchoolSubject = value),
                ),
            ],
          ),
          if (isUniversity) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                dropdown(
                  key: const Key('report-log-faculty'),
                  label: 'Faculty',
                  value: _logFaculty,
                  options: store.facultiesFor(_logUniversity),
                  onChanged: (value) {
                    setState(() {
                      _logFaculty = value;
                      _logCourse = allSubjectsOption;
                    });
                  },
                ),
                const SizedBox(width: 10),
                dropdown(
                  key: const Key('report-log-course'),
                  label: 'Course',
                  value: _logCourse,
                  options: [
                    allSubjectsOption,
                    ...store.campusSubjectsFor(
                      universityName: _logUniversity,
                      facultyName: _logFaculty,
                      year: _logYear,
                    ),
                  ],
                  onChanged: (value) => setState(() => _logCourse = value),
                ),
              ],
            ),
          ] else if (showSchoolStream) ...[
            const SizedBox(height: 12),
            dropdown(
              key: const Key('report-log-stream'),
              label: 'A/L stream',
              value: _logSchoolStream.isEmpty
                  ? allSubjectsOption
                  : _logSchoolStream,
              options: [allSubjectsOption, ...advancedLevelStreams],
              onChanged: (value) => setState(
                () =>
                    _logSchoolStream = value == allSubjectsOption ? '' : value,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogSection(BuildContext context, AttendanceStore store) {
    final localizations = MaterialLocalizations.of(context);
    final schoolLogs = _logsForType(store, InstitutionType.school);
    final universityLogs = _logsForType(store, InstitutionType.university);
    final logs = _logType == InstitutionType.school
        ? schoolLogs
        : universityLogs;
    final isUniversity = _logType == InstitutionType.university;
    final roleWord = isUniversity ? 'lecturer' : 'teacher';

    final byTeacher = <String, Map<String, List<AttendanceLogEntry>>>{};
    for (final entry in logs) {
      byTeacher
          .putIfAbsent(
            entry.instructorLabel,
            () => <String, List<AttendanceLogEntry>>{},
          )
          .putIfAbsent(entry.subjectLabel, () => <AttendanceLogEntry>[])
          .add(entry);
    }
    final teachers = byTeacher.keys.toList()..sort();
    final records = logs.fold<int>(0, (sum, entry) => sum + entry.markedCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 20, color: textDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Attendance log',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ),
            Text(
              '${logs.length} saved',
              key: const Key('report-log-count'),
              style: GoogleFonts.inter(
                color: textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Attendance saved this month, filtered separately by school teachers '
          'and university lecturers, and broken down by each of their subjects.',
          style: GoogleFonts.inter(fontSize: 12, color: textGrey),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<InstitutionType>(
            segments: [
              ButtonSegment(
                value: InstitutionType.school,
                label: Text('School teachers (${schoolLogs.length})'),
                icon: const Icon(Icons.school_rounded),
              ),
              ButtonSegment(
                value: InstitutionType.university,
                label: Text('University lecturers (${universityLogs.length})'),
                icon: const Icon(Icons.account_balance_rounded),
              ),
            ],
            selected: {_logType},
            onSelectionChanged: (selection) {
              setState(() => _logType = selection.first);
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildLogFilters(store),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'No $roleWord attendance saved for '
              '${_monthNames[_selectedMonth - 1]} $_selectedYear in the '
              'selected ${isUniversity ? 'university' : 'group'} yet.',
              key: const Key('report-log-empty'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: textGrey),
            ),
          )
        else ...[
          Text(
            '$records student records across ${teachers.length} '
            '$roleWord${teachers.length == 1 ? '' : 's'} in '
            '${logs.length} ${logs.length == 1 ? 'session' : 'sessions'}.',
            key: const Key('report-log-summary'),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < teachers.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TeacherLogCard(
                teacher: teachers[index],
                subjects: byTeacher[teachers[index]]!,
                initiallyExpanded: index == 0,
                formatDateTime: (value) =>
                    '${localizations.formatShortDate(value)} · ${_timeLabel(value)}',
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _addGroup(BuildContext context, AttendanceStore store) async {
    final isUniversity = _institutionType == InstitutionType.university;
    final group = await showDialog<String>(
      context: context,
      builder: (context) => _NameEntryDialog(
        title: isUniversity ? 'Add year' : 'Add grade',
        label: isUniversity ? 'Year name' : 'Grade name',
      ),
    );
    if (group == null) return;
    final added = isUniversity
        ? store.addUniversityYear(group)
        : store.addSchoolGrade(group);
    if (!added) return;
    setState(() {
      _selectedGroup = group.trim();
      _selectedSubject = allSubjectsOption;
      _selectedStream = '';
    });
  }

  Widget _buildFilters(List<int> years, AttendanceStore store) {
    final isUniversity = _institutionType == InstitutionType.university;
    final faculties = store.facultiesFor(_selectedUniversity);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<InstitutionType>(
              segments: const [
                ButtonSegment(
                  value: InstitutionType.school,
                  label: Text('School'),
                  icon: Icon(Icons.school_rounded),
                ),
                ButtonSegment(
                  value: InstitutionType.university,
                  label: Text('University'),
                  icon: Icon(Icons.account_balance_rounded),
                ),
              ],
              selected: {_institutionType},
              onSelectionChanged: (selection) {
                setState(() {
                  _institutionType = selection.first;
                  _selectedGroup = selection.first == InstitutionType.school
                      ? 'Grade 8'
                      : store.universityYearOptions.first;
                  _selectedSubject = allSubjectsOption;
                  _selectedCourse = allSubjectsOption;
                  _selectedStream = '';
                });
              },
            ),
          ),
          if (isUniversity) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: const Key('reports-university-filter'),
                    initialValue: _selectedUniversity,
                    decoration: const InputDecoration(
                      labelText: 'University / institute',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final university in store.universities)
                        DropdownMenuItem(
                          value: university,
                          child: Text(university),
                        ),
                    ],
                    onChanged: (university) {
                      if (university == null) return;
                      setState(() {
                        _selectedUniversity = university;
                        final newFaculties = store.facultiesFor(university);
                        _selectedFaculty = newFaculties.isEmpty
                            ? ''
                            : newFaculties.first;
                        _selectedCourse = allSubjectsOption;
                      });
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Edit institutions',
                  onPressed: () => _openEditor(SetupEditorKind.university),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey('reports-faculty-$_selectedUniversity'),
                    initialValue: faculties.contains(_selectedFaculty)
                        ? _selectedFaculty
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Faculty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final faculty in faculties)
                        DropdownMenuItem(value: faculty, child: Text(faculty)),
                    ],
                    onChanged: (faculty) {
                      if (faculty != null) {
                        setState(() {
                          _selectedFaculty = faculty;
                          _selectedCourse = allSubjectsOption;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Edit faculties',
                  onPressed: () => _openEditor(
                    SetupEditorKind.faculty,
                    universityName: _selectedUniversity,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: ValueKey('reports-group-$_institutionType'),
                  initialValue: _groups.contains(_selectedGroup)
                      ? _selectedGroup
                      : null,
                  decoration: InputDecoration(
                    labelText: isUniversity ? 'Year group' : 'Grade',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final group in _groups)
                      DropdownMenuItem(value: group, child: Text(group)),
                    DropdownMenuItem(
                      value: '__add_group__',
                      child: Text(
                        isUniversity ? 'Add a year...' : 'Add a grade...',
                      ),
                    ),
                  ],
                  onChanged: (group) {
                    if (group == '__add_group__') {
                      _addGroup(context, store);
                    } else if (group != null) {
                      setState(() {
                        _selectedGroup = group;
                        _selectedSubject = allSubjectsOption;
                        _selectedCourse = allSubjectsOption;
                        _selectedStream = '';
                      });
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: isUniversity ? 'Edit years' : 'Edit grades',
                onPressed: () => _openEditor(
                  isUniversity
                      ? SetupEditorKind.universityYear
                      : SetupEditorKind.schoolGrade,
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          if (!isUniversity && _hasAdvancedLevelSubjects) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: const Key('reports-stream-filter'),
              initialValue: _selectedStream.isEmpty
                  ? allSubjectsOption
                  : _selectedStream,
              decoration: const InputDecoration(
                labelText: 'A/L stream',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                  value: allSubjectsOption,
                  child: Text('All streams'),
                ),
                for (final stream in advancedLevelStreams)
                  DropdownMenuItem(value: stream, child: Text(stream)),
              ],
              onChanged: (stream) {
                if (stream == null) return;
                setState(() {
                  _selectedStream = stream == allSubjectsOption ? '' : stream;
                  _selectedSubject = allSubjectsOption;
                });
              },
            ),
          ],
          if (!isUniversity) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey(
                      'reports-subject-$_selectedGroup-$_selectedStream',
                    ),
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: allSubjectsOption,
                        child: Text(allSubjectsOption),
                      ),
                      for (final subject in store.schoolSubjectsFor(
                        _selectedGroup,
                        stream: _selectedStream,
                      ))
                        DropdownMenuItem(value: subject, child: Text(subject)),
                    ],
                    onChanged: (subject) {
                      if (subject != null) {
                        setState(() => _selectedSubject = subject);
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Edit subjects',
                  onPressed: () => _openEditor(
                    SetupEditorKind.schoolSubject,
                    grade: _selectedGroup,
                    stream: _selectedStream,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ],
          if (isUniversity) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey(
                      'reports-course-$_selectedUniversity-$_selectedFaculty-$_selectedGroup',
                    ),
                    initialValue: _selectedCourse,
                    decoration: const InputDecoration(
                      labelText: 'Course',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: allSubjectsOption,
                        child: Text(allSubjectsOption),
                      ),
                      for (final course in store.campusSubjectsFor(
                        universityName: _selectedUniversity,
                        facultyName: _selectedFaculty,
                        year: _selectedGroup,
                      ))
                        DropdownMenuItem(value: course, child: Text(course)),
                    ],
                    onChanged: (course) {
                      if (course != null) {
                        setState(() => _selectedCourse = course);
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Edit courses',
                  onPressed: () => _openEditor(
                    SetupEditorKind.campusCourse,
                    universityName: _selectedUniversity,
                    facultyName: _selectedFaculty,
                    year: _selectedGroup,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: const Key('reports-month-filter'),
                  initialValue: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (var month = 1; month <= 12; month++)
                      DropdownMenuItem(
                        value: month,
                        child: Text(_monthNames[month - 1]),
                      ),
                  ],
                  onChanged: (month) {
                    if (month != null) setState(() => _selectedMonth = month);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: const Key('reports-year-filter'),
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final year in years)
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: (year) {
                    if (year != null) setState(() => _selectedYear = year);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NameEntryDialog extends StatefulWidget {
  const _NameEntryDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_NameEntryDialog> createState() => _NameEntryDialogState();
}

class _NameEntryDialogState extends State<_NameEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _weekdayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _ReportDateCard extends StatelessWidget {
  const _ReportDateCard({
    required this.dateKey,
    required this.markedAt,
    required this.students,
    required this.store,
  });

  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);
  static const Color _present = Color(0xFF16A34A);
  static const Color _late = Color(0xFFF59E0B);
  static const Color _absent = Color(0xFFDC2626);

  final String dateKey;
  final DateTime? markedAt;
  final List<Student> students;
  final AttendanceStore store;

  static String _clock(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(dateKey);
    final label = date == null
        ? dateKey
        : '${_weekdayAbbr[date.weekday - 1]}, ${date.day} '
              '${_monthNames[date.month - 1]} ${date.year}';

    final groups = <AttendanceStatus, List<Student>>{
      AttendanceStatus.present: [],
      AttendanceStatus.late: [],
      AttendanceStatus.absent: [],
    };
    for (final student in students) {
      final status = store.statusFor(dateKey, student.id);
      if (status != null) {
        groups[status]!.add(student);
      }
    }
    final present = groups[AttendanceStatus.present]!;
    final late = groups[AttendanceStatus.late]!;
    final absent = groups[AttendanceStatus.absent]!;
    final marked = present.length + late.length + absent.length;

    return Container(
      key: ValueKey('report-attendance-date-$dateKey'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              if (markedAt != null)
                Text(
                  'saved ${_clock(markedAt!)}',
                  style: GoogleFonts.inter(fontSize: 11.5, color: _textGrey),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$marked marked · ${present.length} present · '
            '${late.length} late · ${absent.length} absent',
            style: GoogleFonts.inter(fontSize: 12, color: _textGrey),
          ),
          _statusLine('Present', present, _present),
          _statusLine('Late', late, _late),
          _statusLine('Absent', absent, _absent),
        ],
      ),
    );
  }

  Widget _statusLine(String label, List<Student> list, Color color) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$label (${list.length})',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            list.map((student) => student.name).join(', '),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _textDark,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentPeriodReport extends StatelessWidget {
  const _StudentPeriodReport({
    required this.student,
    required this.monthLabel,
    required this.monthly,
    required this.annual,
    required this.year,
  });

  final Student student;
  final String monthLabel;
  final AttendancePeriodSummary monthly;
  final AttendancePeriodSummary annual;
  final int year;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final monthlyReport = _PeriodSummary(
          title: 'Monthly average · $monthLabel',
          summary: monthly,
        );
        final annualReport = _PeriodSummary(
          title: 'Annual average · $year',
          summary: annual,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      student.initials,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          [
                            student.className,
                            if (student.subjectName.isNotEmpty)
                              student.subjectName,
                            if (student.schoolStream.isNotEmpty)
                              student.schoolStream,
                          ].join(' · '),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (constraints.maxWidth < 520) ...[
                monthlyReport,
                const Divider(height: 22),
                annualReport,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: monthlyReport),
                    const SizedBox(
                      height: 110,
                      child: VerticalDivider(width: 24),
                    ),
                    Expanded(child: annualReport),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({required this.title, required this.summary});

  final String title;
  final AttendancePeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${summary.averageAttendance.round()}%',
          style: GoogleFonts.inter(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          '${summary.markedDays} marked ${summary.markedDays == 1 ? 'day' : 'days'}',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _StatusCount(
              label: 'Present',
              count: summary.presentDays,
              color: const Color(0xFF16A34A),
            ),
            _StatusCount(
              label: 'Late',
              count: summary.lateDays,
              color: const Color(0xFFF59E0B),
            ),
            _StatusCount(
              label: 'Absent',
              count: summary.absentDays,
              color: const Color(0xFFDC2626),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusCount extends StatelessWidget {
  const _StatusCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label $count',
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _TeacherLogCard extends StatelessWidget {
  const _TeacherLogCard({
    required this.teacher,
    required this.subjects,
    required this.formatDateTime,
    this.initiallyExpanded = false,
  });

  final String teacher;
  final Map<String, List<AttendanceLogEntry>> subjects;
  final String Function(DateTime value) formatDateTime;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final subjectNames = subjects.keys.toList()..sort();
    final sessions = subjectNames.fold<int>(
      0,
      (sum, subject) => sum + subjects[subject]!.length,
    );
    final records = subjectNames.fold<int>(
      0,
      (sum, subject) =>
          sum +
          subjects[subject]!.fold<int>(
            0,
            (total, entry) => total + entry.markedCount,
          ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('report-log-teacher-$teacher'),
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Text(
            teacher,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '$sessions ${sessions == 1 ? 'session' : 'sessions'} · $records records',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          children: [
            for (final subject in subjectNames)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subject,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final entry in subjects[subject]!)
                      Container(
                        key: ValueKey(
                          'report-log-entry-${entry.dateKey}-$teacher-$subject',
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatDateTime(entry.markedAt),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.presentCount} present · '
                              '${entry.lateCount} late · '
                              '${entry.absentCount} absent',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
