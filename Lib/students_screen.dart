import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_store.dart';
import 'school_subject_catalog.dart';
import 'setup_editor.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color textGrey = Color(0xFF64748B);

  InstitutionType _institutionType = InstitutionType.school;
  String _selectedGroup = 'Grade 8';
  String _selectedSubject = allSubjectsOption;
  String _selectedStream = '';
  String _selectedUniversity = 'University of Colombo';
  String _selectedFaculty = 'Faculty of Arts';

  List<String> get _groups => _institutionType == InstitutionType.school
      ? AttendanceStore.instance.schoolGradeOptions
      : AttendanceStore.instance.universityYearOptions;

  bool get _hasAdvancedLevelSubjects =>
      AttendanceStore.instance.schoolGradeNumber(_selectedGroup) >= 12;

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
      AttendanceStore.instance,
      kind,
      universityName: universityName,
      facultyName: facultyName,
      grade: grade,
      stream: stream,
      year: year,
    );
    if (!mounted) return;
    setState(() {
      final store = AttendanceStore.instance;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AttendanceStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Students',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context, store),
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          'Add student',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final dateKey = store.todayKey;
          final students = store.studentsFor(
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
                _institutionType == InstitutionType.school &&
                    _selectedStream.isNotEmpty
                ? _selectedStream
                : null,
          );
          final studentIds = students.map((student) => student.id).toList();
          final marked = store.markedCount(dateKey, studentIds: studentIds);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _buildGroupSelector(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Class overview',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$marked of ${students.length} '
                                    'students marked today',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/attendance',
                                arguments: {
                                  'institutionType': _institutionType,
                                  'groupName': _selectedGroup,
                                  'universityName': _selectedUniversity,
                                  'facultyName': _selectedFaculty,
                                  'subjectName': _selectedSubject,
                                  'schoolStream': _selectedStream,
                                },
                              ),
                              icon: const Icon(
                                Icons.fact_check_outlined,
                                size: 18,
                              ),
                              label: const Text('Mark'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: students.isEmpty
                            ? Center(
                                child: Text(
                                  'No students in $_selectedGroup yet. Use "Add student" to create one.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(color: textGrey),
                                ),
                              )
                            : ListView.separated(
                                itemCount: students.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final student = students[index];
                                  return _StudentRow(
                                    name: student.name,
                                    className: [
                                      student.className,
                                      if (student.subjectName.isNotEmpty)
                                        student.subjectName,
                                      if (student.schoolStream.isNotEmpty)
                                        student.schoolStream,
                                    ].join(' · '),
                                    status:
                                        store
                                            .statusFor(dateKey, student.id)
                                            ?.label ??
                                        'Not marked',
                                    statusColor: _colorFor(
                                      store.statusFor(dateKey, student.id),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddStudentDialog(
    BuildContext context,
    AttendanceStore store,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    return showDialog<void>(
      context: context,
      builder: (_) => _AddStudentDialog(
        store: store,
        messenger: messenger,
        institutionType: _institutionType,
        groupName: _selectedGroup,
        universityName: _selectedUniversity,
        facultyName: _selectedFaculty,
        subjectName: _selectedSubject != allSubjectsOption
            ? _selectedSubject
            : (_institutionType == InstitutionType.school
                  ? store
                        .schoolSubjectsFor(
                          _selectedGroup,
                          stream: _selectedStream,
                        )
                        .first
                  : null),
        schoolStream: _institutionType == InstitutionType.school
            ? _selectedStream
            : '',
      ),
    );
  }

  Widget _buildGroupSelector() {
    final store = AttendanceStore.instance;
    final isUniversity = _institutionType == InstitutionType.university;
    final universities = store.universities;
    final faculties = store.facultiesFor(_selectedUniversity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  _selectedStream = '';
                  if (selection.first == InstitutionType.university &&
                      !store
                          .facultiesFor(_selectedUniversity)
                          .contains(_selectedFaculty)) {
                    _selectedFaculty = store
                        .facultiesFor(_selectedUniversity)
                        .first;
                  }
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
                    key: const Key('students-university-filter'),
                    initialValue: universities.contains(_selectedUniversity)
                        ? _selectedUniversity
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'University / institute',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final university in universities)
                        DropdownMenuItem(
                          value: university,
                          child: Text(university),
                        ),
                      const DropdownMenuItem(
                        value: '__add_university__',
                        child: Text('Add a university / institute...'),
                      ),
                    ],
                    onChanged: (university) {
                      if (university == '__add_university__') {
                        _addUniversity(context, store);
                      } else if (university == null) {
                        return;
                      } else {
                        setState(() {
                          _selectedUniversity = university;
                          final universityFaculties = store.facultiesFor(
                            university,
                          );
                          _selectedFaculty = universityFaculties.isEmpty
                              ? ''
                              : universityFaculties.first;
                          _selectedSubject = allSubjectsOption;
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Add university or institute',
                  onPressed: () => _addUniversity(context, store),
                  icon: const Icon(Icons.add_business_rounded),
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
                    key: ValueKey('students-faculty-$_selectedUniversity'),
                    initialValue: _selectedFaculty.isEmpty
                        ? null
                        : _selectedFaculty,
                    decoration: const InputDecoration(
                      labelText: 'Faculty',
                      hintText: 'Select or add a faculty',
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
                        _addFaculty(context, store);
                      } else if (faculty != null) {
                        setState(() {
                          _selectedFaculty = faculty;
                          _selectedSubject = allSubjectsOption;
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
                  key: ValueKey('students-group-${_institutionType.name}'),
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
                        if (!isUniversity) _selectedStream = '';
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
          if (isUniversity) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey(
                      'students-campus-course-$_selectedUniversity-$_selectedFaculty-$_selectedGroup',
                    ),
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Course / subject',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '__add_campus_course__',
                        child: Text('Add a course / subject...'),
                      ),
                      const DropdownMenuItem(
                        value: allSubjectsOption,
                        child: Text(allSubjectsOption),
                      ),
                      for (final subject in store.campusSubjectsFor(
                        universityName: _selectedUniversity,
                        facultyName: _selectedFaculty,
                        year: _selectedGroup,
                      ))
                        DropdownMenuItem(value: subject, child: Text(subject)),
                    ],
                    onChanged: (subject) {
                      if (subject == '__add_campus_course__') {
                        _addCampusSubject(context, store);
                      } else if (subject != null) {
                        setState(() => _selectedSubject = subject);
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
          if (!isUniversity && _hasAdvancedLevelSubjects) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              key: const Key('students-stream-filter'),
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
                      'students-subject-$_selectedGroup-$_selectedStream',
                    ),
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '__add_subject__',
                        child: Text('Add a subject...'),
                      ),
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
                      if (subject == '__add_subject__') {
                        _addSchoolSubject(context, store);
                      } else if (subject != null) {
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
        ],
      ),
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

  Future<void> _addCampusSubject(
    BuildContext context,
    AttendanceStore store,
  ) async {
    final subject = await showDialog<String>(
      context: context,
      builder: (context) => const _NameEntryDialog(
        title: 'Add campus course or subject',
        label: 'Course or subject name',
      ),
    );
    if (subject == null ||
        !store.addCampusSubject(
          universityName: _selectedUniversity,
          facultyName: _selectedFaculty,
          year: _selectedGroup,
          subjectName: subject,
        )) {
      return;
    }
    setState(() => _selectedSubject = subject.trim());
  }

  Future<void> _addSchoolSubject(
    BuildContext context,
    AttendanceStore store,
  ) async {
    final subject = await showDialog<String>(
      context: context,
      builder: (context) => _NameEntryDialog(
        title: 'Add subject for $_selectedGroup',
        label: 'Subject name',
      ),
    );
    if (subject == null ||
        !store.addSchoolSubject(
          _selectedGroup,
          subject,
          stream: _selectedStream,
        )) {
      return;
    }
    setState(() => _selectedSubject = subject.trim());
  }

  Future<void> _addUniversity(
    BuildContext context,
    AttendanceStore store,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NameEntryDialog(
        title: 'Add university or institute',
        label: 'Institution name',
      ),
    );
    if (name == null || !store.addUniversity(name)) return;
    setState(() {
      _selectedUniversity = name.trim();
      _selectedFaculty = '';
    });
  }

  Future<void> _addFaculty(BuildContext context, AttendanceStore store) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameEntryDialog(
        title: 'Add faculty to $_selectedUniversity',
        label: 'Faculty name',
      ),
    );
    if (name == null || !store.addFaculty(_selectedUniversity, name)) return;
    setState(() => _selectedFaculty = name.trim());
  }

  Color _colorFor(AttendanceStatus? status) => switch (status) {
    AttendanceStatus.present => const Color(0xFF16A34A),
    AttendanceStatus.late => const Color(0xFFF59E0B),
    AttendanceStatus.absent => const Color(0xFFDC2626),
    null => textGrey,
  };
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.name,
    required this.className,
    required this.status,
    required this.statusColor,
  });

  final String name;
  final String className;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              name.substring(0, 1),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  className,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog({
    required this.store,
    required this.messenger,
    required this.institutionType,
    required this.groupName,
    required this.universityName,
    required this.facultyName,
    required this.subjectName,
    required this.schoolStream,
  });

  final AttendanceStore store;
  final ScaffoldMessengerState messenger;
  final InstitutionType institutionType;
  final String groupName;
  final String universityName;
  final String facultyName;
  final String? subjectName;
  final String schoolStream;

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  String? _duplicateError;

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameController.text.trim();
    final enteredClass = _classController.text.trim();
    var groupName = widget.groupName;
    if (widget.institutionType == InstitutionType.school) {
      final match = RegExp(r'^Grade (\d+)').firstMatch(enteredClass);
      final enteredGrade = match == null ? null : 'Grade ${match.group(1)}';
      if (schoolGrades.contains(enteredGrade)) groupName = enteredGrade!;
    } else if (universityYears.contains(enteredClass)) {
      groupName = enteredClass;
    }
    final added = widget.store.addStudent(
      name: name,
      className: _classController.text,
      institutionType: widget.institutionType,
      groupName: groupName,
      universityName: widget.universityName,
      facultyName: widget.facultyName,
      subjectName: widget.subjectName,
      schoolStream: widget.schoolStream,
    );
    if (!added) {
      setState(() => _duplicateError = 'This student already exists');
      return;
    }
    Navigator.of(context).pop();
    widget.messenger.showSnackBar(
      SnackBar(content: Text('$name added to the class.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add student'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('add-student-name-field'),
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Student name',
                hintText: 'e.g. John Doe',
                errorText: _duplicateError,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a student name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('add-student-class-field'),
              controller: _classController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Class (optional)',
                hintText: 'e.g. Grade 8-A',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('add-student-submit'),
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
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
        key: const Key('students-name-entry-field'),
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
