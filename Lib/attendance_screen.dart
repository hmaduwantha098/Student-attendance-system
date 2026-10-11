import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_store.dart';
import 'school_subject_catalog.dart';
import 'searchable_picker.dart';
import 'setup_editor.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    this.initialInstitutionType = InstitutionType.school,
    this.initialGroup = 'Grade 8',
    this.initialUniversityName = 'University of Colombo',
    this.initialFacultyName = 'Faculty of Arts',
    this.initialSubjectName = allSubjectsOption,
    this.initialSchoolStream = '',
  });

  final InstitutionType initialInstitutionType;
  final String initialGroup;
  final String initialUniversityName;
  final String initialFacultyName;
  final String initialSubjectName;
  final String initialSchoolStream;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);
  static const Color presentGreen = Color(0xFF16A34A);
  static const Color lateAmber = Color(0xFFF59E0B);
  static const Color absentRed = Color(0xFFDC2626);

  final AttendanceStore _store = AttendanceStore.instance;
  late DateTime _selectedDate;
  late InstitutionType _institutionType;
  late String _selectedGroup;
  late String _selectedUniversity;
  late String _selectedFaculty;
  late String _selectedSubject;
  late String _selectedStream;
  String _studentQuery = '';

  List<String> get _groups => _institutionType == InstitutionType.school
      ? _store.schoolGradeOptions
      : _store.universityYearOptions;

  List<Student> get _students => _store.studentsFor(
    _institutionType,
    _selectedGroup,
    universityName: _institutionType == InstitutionType.university
        ? _selectedUniversity
        : null,
    facultyName: _institutionType == InstitutionType.university
        ? _selectedFaculty
        : null,
    subjectName: _selectedSubject != allSubjectsOption
        ? _selectedSubject
        : null,
    schoolStream:
        _institutionType == InstitutionType.school && _selectedStream.isNotEmpty
        ? _selectedStream
        : null,
  );

  List<Student> get _visibleStudents {
    final query = _studentQuery.trim().toLowerCase();
    if (query.isEmpty) return _students;
    return _students
        .where(
          (student) =>
              student.name.toLowerCase().contains(query) ||
              student.className.toLowerCase().contains(query),
        )
        .toList();
  }

  bool get _hasInstructorContext =>
      _institutionType == InstitutionType.university ||
      _selectedSubject != allSubjectsOption;

  String get _instructorName => _store.instructorFor(
    institutionType: _institutionType,
    groupName: _selectedGroup,
    subjectName: _selectedSubject == allSubjectsOption ? '' : _selectedSubject,
    schoolStream: _selectedStream,
    universityName: _selectedUniversity,
    facultyName: _selectedFaculty,
  );

  String get _instructorRole =>
      _institutionType == InstitutionType.school ? 'Teacher' : 'Lecturer';

  String get _rosterLabel => [
    _selectedGroup,
    if (_institutionType == InstitutionType.university) _selectedFaculty,
    if (_institutionType == InstitutionType.school &&
        _selectedSubject != allSubjectsOption)
      _selectedSubject,
    if (_selectedStream.isNotEmpty) _selectedStream,
  ].join(' · ');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _institutionType = widget.initialInstitutionType;
    _selectedGroup = widget.initialGroup;
    _selectedUniversity = widget.initialUniversityName;
    _selectedFaculty = widget.initialFacultyName;
    _selectedSubject = widget.initialSubjectName;
    _selectedStream = widget.initialSchoolStream;
  }

  void _changeDay(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + offset,
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _save(String dateKey, List<Student> students) {
    final ids = students.map((student) => student.id).toList();
    final marked = _store.markedCount(dateKey, studentIds: ids);
    if (marked < students.length) {
      _showMessage(
        'Mark the remaining ${students.length - marked} students first.',
      );
      return;
    }
    _store.recordAttendanceLog(
      dateKey: dateKey,
      institutionType: _institutionType,
      groupName: _selectedGroup,
      subjectName: _selectedSubject == allSubjectsOption
          ? ''
          : _selectedSubject,
      schoolStream: _selectedStream,
      universityName: _selectedUniversity,
      facultyName: _selectedFaculty,
      instructorName: _instructorName,
      studentIds: ids,
    );
    final markedAt = _store.markedAtFor(dateKey);
    _showMessage(
      'Attendance saved: ${_store.attendedCount(dateKey, studentIds: ids)} attended, '
      '${_store.countFor(dateKey, AttendanceStatus.absent, studentIds: ids)} absent'
      '${markedAt == null ? '' : ' · marked at ${_timeLabel(markedAt)}'}.',
    );
  }

  Future<void> _reset(String dateKey, List<Student> students) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear attendance?'),
        content: Text('This removes statuses saved for $_rosterLabel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _store.clearDate(
        dateKey,
        studentIds: students.map((student) => student.id),
      );
    }
  }

  Future<void> _editInstructor() async {
    final role = _institutionType == InstitutionType.school
        ? 'Teacher'
        : 'Lecturer';
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          _InstructorNameDialog(role: role, initialName: _instructorName),
    );
    if (name == null) return;
    _store.setInstructor(
      institutionType: _institutionType,
      groupName: _selectedGroup,
      subjectName: _selectedSubject == allSubjectsOption
          ? ''
          : _selectedSubject,
      schoolStream: _selectedStream,
      universityName: _selectedUniversity,
      facultyName: _selectedFaculty,
      name: name,
    );
  }

  Future<void> _addGroup(BuildContext context) async {
    final isUniversity = _institutionType == InstitutionType.university;
    final group = await showDialog<String>(
      context: context,
      builder: (context) => _NameEntryDialog(
        title: isUniversity ? 'Add year' : 'Add grade',
        label: isUniversity ? 'Year name' : 'Grade name',
        hint: isUniversity ? 'e.g. Fifth Year' : 'e.g. Grade 14',
        actionLabel: 'Add',
      ),
    );
    if (group == null) return;
    final added = isUniversity
        ? _store.addUniversityYear(group)
        : _store.addSchoolGrade(group);
    if (!added) return;
    setState(() {
      _selectedGroup = group.trim();
      _selectedSubject = allSubjectsOption;
      _selectedStream = '';
    });
  }

  Future<void> _addUniversity() async {
    final university = await showDialog<String>(
      context: context,
      builder: (context) => const _NameEntryDialog(
        title: 'Add university or institute',
        label: 'Institution name',
        actionLabel: 'Add',
      ),
    );
    if (university == null || !_store.addUniversity(university)) return;
    setState(() {
      _selectedUniversity = university.trim();
      final faculties = _store.facultiesFor(_selectedUniversity);
      _selectedFaculty = faculties.isEmpty ? '' : faculties.first;
    });
  }

  Future<void> _addFaculty() async {
    final faculty = await showDialog<String>(
      context: context,
      builder: (context) => _NameEntryDialog(
        title: 'Add faculty to $_selectedUniversity',
        label: 'Faculty name',
        actionLabel: 'Add',
      ),
    );
    if (faculty == null || !_store.addFaculty(_selectedUniversity, faculty)) {
      return;
    }
    setState(() => _selectedFaculty = faculty.trim());
  }

  Future<void> _addCampusSubject() async {
    final subject = await showDialog<String>(
      context: context,
      builder: (context) => const _NameEntryDialog(
        title: 'Add course / subject',
        label: 'Course or subject name',
        actionLabel: 'Add',
      ),
    );
    if (subject == null ||
        !_store.addCampusSubject(
          universityName: _selectedUniversity,
          facultyName: _selectedFaculty,
          year: _selectedGroup,
          subjectName: subject,
        )) {
      return;
    }
    setState(() => _selectedSubject = subject.trim());
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
    _syncSelections();
  }

  void _syncSelections() {
    if (!mounted) return;
    setState(() {
      final university = _store.currentUniversityName(_selectedUniversity);
      _selectedUniversity = university;
      _selectedGroup = _store.currentUniversityYearName(
        _store.currentSchoolGradeName(_selectedGroup),
      );
      _selectedFaculty = _store.currentFacultyName(
        universityName: university,
        facultyName: _selectedFaculty,
      );
      final subject = _store.currentSchoolSubjectName(
        grade: _selectedGroup,
        stream: _selectedStream,
        subjectName: _selectedSubject,
      );
      _selectedSubject = _store.currentCampusCourseName(
        universityName: university,
        facultyName: _selectedFaculty,
        year: _selectedGroup,
        courseName: subject,
      );
    });
  }

  Future<void> _editGroup() => _openEditor(
    _institutionType == InstitutionType.university
        ? SetupEditorKind.universityYear
        : SetupEditorKind.schoolGrade,
  );

  Future<void> _editUniversity() => _openEditor(SetupEditorKind.university);

  Future<void> _editFaculty() =>
      _openEditor(SetupEditorKind.faculty, universityName: _selectedUniversity);

  Future<void> _editCampusSubject() => _openEditor(
    SetupEditorKind.campusCourse,
    universityName: _selectedUniversity,
    facultyName: _selectedFaculty,
    year: _selectedGroup,
  );

  Future<void> _editSchoolSubject() => _openEditor(
    SetupEditorKind.schoolSubject,
    grade: _selectedGroup,
    stream: _selectedStream,
  );

  Future<void> _addSchoolSubject() async {
    final subject = await showDialog<String>(
      context: context,
      builder: (context) => const _NameEntryDialog(
        title: 'Add subject',
        label: 'Subject name',
        actionLabel: 'Add',
      ),
    );
    if (subject == null ||
        !_store.addSchoolSubject(
          _selectedGroup,
          subject,
          stream: _selectedStream,
        )) {
      return;
    }
    setState(() => _selectedSubject = subject.trim());
  }

  String _lecturerForCourse(String course) => _store.instructorFor(
    institutionType: InstitutionType.university,
    groupName: _selectedGroup,
    subjectName: course,
    universityName: _selectedUniversity,
    facultyName: _selectedFaculty,
  );

  String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildInstructorPanel() {
    final isSchool = _institutionType == InstitutionType.school;
    final role = _instructorRole;
    final subjectLabel = isSchool ? 'Subject' : 'Subject taught';
    final offering = isSchool
        ? (_selectedSubject == allSubjectsOption
              ? 'All subjects'
              : _selectedSubject)
        : _selectedSubject;
    final group = isSchool && _selectedStream.isNotEmpty
        ? '$_selectedGroup · $_selectedStream'
        : _selectedGroup;
    final courses = isSchool
        ? const <String>[]
        : _store.campusSubjectsFor(
            universityName: _selectedUniversity,
            facultyName: _selectedFaculty,
            year: _selectedGroup,
          );
    final lecturer = _instructorName.isEmpty ? 'Not assigned' : _instructorName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Icon(
              isSchool
                  ? Icons.person_outline_rounded
                  : Icons.co_present_rounded,
              color: primaryBlue,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSchool)
                  Text(
                    '$_selectedUniversity · $_selectedFaculty · $_selectedGroup',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  )
                else
                  Text(
                    '$offering · $group',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                const SizedBox(height: 2),
                if (!isSchool)
                  Text(
                    '$subjectLabel: ${offering == allSubjectsOption ? 'All subjects' : offering}',
                    style: GoogleFonts.inter(fontSize: 12, color: textGrey),
                  ),
                Text(
                  '$role: $lecturer',
                  style: GoogleFonts.inter(fontSize: 12, color: textGrey),
                ),
                if (!isSchool && courses.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final course in courses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $course — '
                        '${_lecturerForCourse(course).isEmpty ? 'Lecturer not assigned' : _lecturerForCourse(course)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: course == _selectedSubject
                              ? textDark
                              : textGrey,
                          fontWeight: course == _selectedSubject
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Assign $role',
            onPressed: _editInstructor,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final dateKey = AttendanceStore.keyFor(_selectedDate);
        final students = _students;
        final ids = students.map((student) => student.id).toList();
        final marked = _store.markedCount(dateKey, studentIds: ids);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Mark Attendance',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: 'Saved categories',
                onPressed: () => Navigator.pushNamed(context, '/categories'),
                icon: const Icon(Icons.category_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildGroupSelector(),
                const SizedBox(height: 16),
                if (_hasInstructorContext) ...[
                  _buildInstructorPanel(),
                  const SizedBox(height: 16),
                ],
                _buildDateCard(context),
                const SizedBox(height: 16),
                _buildSummary(dateKey, ids),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$_rosterLabel students',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: students.isEmpty
                          ? null
                          : () =>
                                _store.markAllPresent(dateKey, studentIds: ids),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Mark all present'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStudentSearch(students),
                const SizedBox(height: 8),
                if (students.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'No students in $_rosterLabel yet. Add students from Student Management.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: textGrey),
                      ),
                    ),
                  ),
                for (final student in _visibleStudents)
                  Padding(
                    key: ValueKey('attendance-student-${student.id}'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildStudentCard(dateKey, student),
                  ),
                if (marked == students.length && marked > 0)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: presentGreen.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: presentGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: presentGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All students are marked for this date.',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: presentGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: marked == 0
                        ? null
                        : () => _reset(dateKey, students),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: students.isEmpty
                        ? null
                        : () => _save(dateKey, students),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save attendance'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isUniversity = _institutionType == InstitutionType.university;
        final institutionSelector = SegmentedButton<InstitutionType>(
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
                  : _store.universityYearOptions.first;
              _selectedSubject = allSubjectsOption;
              _selectedStream = '';
              _studentQuery = '';
              if (selection.first == InstitutionType.university) {
                final faculties = _store.facultiesFor(_selectedUniversity);
                if (!faculties.contains(_selectedFaculty)) {
                  _selectedFaculty = faculties.isEmpty ? '' : faculties.first;
                }
              }
            });
          },
        );
        Widget universitySelector() => SearchablePickerField(
          key: const Key('attendance-university-filter'),
          label: 'University / institute',
          searchHint: 'Type to search universities',
          emptyMessage: 'No institution matches. Add it with the + button.',
          value: _store.universities.contains(_selectedUniversity)
              ? _selectedUniversity
              : '',
          options: _store.universities,
          onSelected: (university) {
            setState(() {
              _selectedUniversity = university;
              final facultyList = _store.facultiesFor(university);
              _selectedFaculty = facultyList.isEmpty ? '' : facultyList.first;
              _selectedSubject = allSubjectsOption;
              _studentQuery = '';
            });
          },
        );
        final universityControl = Row(
          children: [
            Expanded(child: universitySelector()),
            IconButton(
              tooltip: 'Add university or institute',
              onPressed: _addUniversity,
              icon: const Icon(Icons.add_business_rounded),
            ),
            IconButton(
              tooltip: 'Edit institutions',
              onPressed: _editUniversity,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        );
        final faculties = _store.facultiesFor(_selectedUniversity);
        Widget facultySelector() => DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('attendance-faculty-$_selectedUniversity'),
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
            const DropdownMenuItem(
              value: '__add_faculty__',
              child: Text('Add a faculty...'),
            ),
          ],
          onChanged: (faculty) {
            if (faculty == '__add_faculty__') {
              _addFaculty();
            } else if (faculty != null) {
              setState(() {
                _selectedFaculty = faculty;
                _selectedSubject = allSubjectsOption;
                _studentQuery = '';
              });
            }
          },
        );
        final campusSubjects = _store.campusSubjectsFor(
          universityName: _selectedUniversity,
          facultyName: _selectedFaculty,
          year: _selectedGroup,
        );
        Widget campusSubjectSelector() => SearchablePickerField(
          key: ValueKey(
            'attendance-campus-course-$_selectedUniversity-$_selectedFaculty-$_selectedGroup',
          ),
          label: 'Course / subject',
          searchHint: 'Type to search courses',
          addLabel: 'Add a course / subject...',
          value: _selectedSubject,
          options: [allSubjectsOption, ...campusSubjects],
          onSelected: (subject) {
            if (subject == searchPickerAddSentinel) {
              _addCampusSubject();
            } else {
              setState(() {
                _selectedSubject = subject;
                _studentQuery = '';
              });
            }
          },
        );
        Widget groupSelector() => DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('attendance-group-${_institutionType.name}'),
          initialValue: _groups.contains(_selectedGroup)
              ? _selectedGroup
              : null,
          decoration: InputDecoration(
            labelText: isUniversity ? 'Year' : 'Grade',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            for (final group in _groups)
              DropdownMenuItem(value: group, child: Text(group)),
            DropdownMenuItem(
              value: '__add_group__',
              child: Text(isUniversity ? 'Add a year...' : 'Add a grade...'),
            ),
          ],
          onChanged: (group) {
            if (group == '__add_group__') {
              _addGroup(context);
            } else if (group != null) {
              setState(() {
                _selectedGroup = group;
                _selectedSubject = allSubjectsOption;
                _selectedStream = '';
                _studentQuery = '';
              });
            }
          },
        );
        final gradeNumber = _store.schoolGradeNumber(_selectedGroup);
        final schoolSubjectOptions = _store.schoolSubjectsFor(
          _selectedGroup,
          stream: _selectedStream,
        );
        Widget subjectSelector() => SearchablePickerField(
          key: ValueKey('attendance-subject-$_selectedGroup-$_selectedStream'),
          label: 'Subject',
          searchHint: 'Type to search subjects',
          addLabel: 'Add a subject...',
          value: _selectedSubject,
          options: [allSubjectsOption, ...schoolSubjectOptions],
          onSelected: (subject) {
            if (subject == searchPickerAddSentinel) {
              _addSchoolSubject();
            } else {
              setState(() {
                _selectedSubject = subject;
                _studentQuery = '';
              });
            }
          },
        );
        final streamSelector = DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('attendance-stream-$_selectedGroup'),
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
              _studentQuery = '';
            });
          },
        );
        Widget withEditAction(
          Widget selector,
          String tooltip,
          VoidCallback onPressed,
        ) => Row(
          children: [
            Expanded(child: selector),
            const SizedBox(width: 4),
            IconButton(
              tooltip: tooltip,
              onPressed: onPressed,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        );

        Widget buildControls() => isUniversity
            ? Column(
                children: [
                  universityControl,
                  const SizedBox(height: 8),
                  withEditAction(
                    facultySelector(),
                    'Edit faculties',
                    _editFaculty,
                  ),
                  const SizedBox(height: 8),
                  withEditAction(groupSelector(), 'Edit years', _editGroup),
                  const SizedBox(height: 8),
                  withEditAction(
                    campusSubjectSelector(),
                    'Edit courses',
                    _editCampusSubject,
                  ),
                ],
              )
            : Column(
                children: [
                  withEditAction(groupSelector(), 'Edit grades', _editGroup),
                  const SizedBox(height: 8),
                  withEditAction(
                    subjectSelector(),
                    'Edit subjects',
                    _editSchoolSubject,
                  ),
                  if (gradeNumber >= 12) ...[
                    const SizedBox(height: 8),
                    streamSelector,
                  ],
                ],
              );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: constraints.maxWidth >= 640
              ? Row(
                  children: [
                    Expanded(flex: 3, child: institutionSelector),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: buildControls()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance system',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: institutionSelector,
                    ),
                    const SizedBox(height: 12),
                    buildControls(),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDateCard(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final localizations = MaterialLocalizations.of(context);
    final markedAt = _store.markedAtFor(AttendanceStore.keyFor(_selectedDate));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('attendance-previous-day'),
                onPressed: () => _changeDay(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  localizations.formatFullDate(_selectedDate),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                key: const Key('attendance-next-day'),
                onPressed: isToday ? null : () => _changeDay(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Text(
            markedAt == null
                ? 'Not marked yet'
                : 'Marked on ${localizations.formatShortDate(markedAt)} at '
                      '${_timeLabel(markedAt)}',
            key: const Key('attendance-marked-at'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: markedAt == null ? textGrey : const Color(0xFF16A34A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(String dateKey, List<String> studentIds) {
    final marked = _store.markedCount(dateKey, studentIds: studentIds);
    final present = _store.countFor(
      dateKey,
      AttendanceStatus.present,
      studentIds: studentIds,
    );
    final late = _store.countFor(
      dateKey,
      AttendanceStatus.late,
      studentIds: studentIds,
    );
    final absent = _store.countFor(
      dateKey,
      AttendanceStatus.absent,
      studentIds: studentIds,
    );
    final rate = _store.attendanceRate(dateKey, studentIds: studentIds).round();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryTile(label: 'Marked', value: '$marked', color: primaryBlue),
        _SummaryTile(label: 'Present', value: '$present', color: presentGreen),
        _SummaryTile(label: 'Late', value: '$late', color: lateAmber),
        _SummaryTile(label: 'Absent', value: '$absent', color: absentRed),
        _SummaryTile(label: 'Rate', value: '$rate%', color: primaryBlue),
      ],
    );
  }

  Widget _buildStudentSearch(List<Student> students) {
    final visible = _visibleStudents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('attendance-student-search'),
          onChanged: (value) => setState(() => _studentQuery = value),
          decoration: InputDecoration(
            hintText: 'Search student by name',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _studentQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear student search',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() => _studentQuery = ''),
                  ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _studentQuery.trim().isEmpty
              ? 'Showing all ${students.length} students'
              : 'Showing ${visible.length} of ${students.length} students',
          key: const Key('attendance-student-count'),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(String dateKey, Student student) {
    final status = _store.statusFor(dateKey, student.id);
    final color = switch (status) {
      AttendanceStatus.present => presentGreen,
      AttendanceStatus.late => lateAmber,
      AttendanceStatus.absent => absentRed,
      null => textGrey,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(student.initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      student.className,
                      style: GoogleFonts.inter(fontSize: 12, color: textGrey),
                    ),
                  ],
                ),
              ),
              Text(
                status?.label ?? 'Not marked',
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AttendanceStatus>(
              showSelectedIcon: false,
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(
                  value: AttendanceStatus.present,
                  label: Text('Present'),
                ),
                ButtonSegment(
                  value: AttendanceStatus.late,
                  label: Text('Late'),
                ),
                ButtonSegment(
                  value: AttendanceStatus.absent,
                  label: Text('Absent'),
                ),
              ],
              selected: {?status},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  _store.clearStatus(dateKey, student.id);
                } else {
                  _store.setStatus(dateKey, student.id, selection.first);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorNameDialog extends StatefulWidget {
  const _InstructorNameDialog({required this.role, required this.initialName});

  final String role;
  final String initialName;

  @override
  State<_InstructorNameDialog> createState() => _InstructorNameDialogState();
}

class _InstructorNameDialogState extends State<_InstructorNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign ${widget.role.toLowerCase()}'),
      content: TextField(
        key: const Key('instructor-name-field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: '${widget.role} name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _NameEntryDialog extends StatefulWidget {
  const _NameEntryDialog({
    required this.title,
    required this.label,
    required this.actionLabel,
    this.hint,
  });

  final String title;
  final String label;
  final String actionLabel;
  final String? hint;

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
        key: const Key('attendance-name-entry-field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  static const Color _mutedText = Color(0xFF64748B);

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: _mutedText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
