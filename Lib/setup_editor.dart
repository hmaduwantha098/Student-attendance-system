import 'package:flutter/material.dart';

import 'attendance_store.dart';

enum SetupEditorKind {
  schoolGrade,
  universityYear,
  university,
  faculty,
  schoolSubject,
  campusCourse,
}

Future<void> openSetupEditor(
  BuildContext context,
  AttendanceStore store,
  SetupEditorKind kind, {
  String universityName = '',
  String facultyName = '',
  String grade = '',
  String stream = '',
  String year = '',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _SetupEditorDialog(
      store: store,
      kind: kind,
      universityName: universityName,
      facultyName: facultyName,
      grade: grade,
      stream: stream,
      year: year,
    ),
  );
}

class _SetupEditorDialog extends StatefulWidget {
  const _SetupEditorDialog({
    required this.store,
    required this.kind,
    required this.universityName,
    required this.facultyName,
    required this.grade,
    required this.stream,
    required this.year,
  });

  final AttendanceStore store;
  final SetupEditorKind kind;
  final String universityName;
  final String facultyName;
  final String grade;
  final String stream;
  final String year;

  @override
  State<_SetupEditorDialog> createState() => _SetupEditorDialogState();
}

class _SetupEditorDialogState extends State<_SetupEditorDialog> {
  late List<_EditableEntry> _entries = _buildEntries();

  String get _scopeLabel => switch (widget.kind) {
    SetupEditorKind.schoolGrade => 'grades',
    SetupEditorKind.universityYear => 'years',
    SetupEditorKind.university => 'institutions',
    SetupEditorKind.faculty => 'faculties for ${widget.universityName}',
    SetupEditorKind.schoolSubject => 'subjects for ${widget.grade}',
    SetupEditorKind.campusCourse =>
      'courses for ${widget.facultyName} · ${widget.year}',
  };

  String get _itemLabel => switch (widget.kind) {
    SetupEditorKind.schoolGrade => 'Grade',
    SetupEditorKind.universityYear => 'Year',
    SetupEditorKind.university => 'Institution',
    SetupEditorKind.faculty => 'Faculty',
    SetupEditorKind.schoolSubject => 'Subject',
    SetupEditorKind.campusCourse => 'Course',
  };

  List<_EditableEntry> _buildEntries() {
    final store = widget.store;
    List<String> names;
    List<String> customNames;
    bool Function(String from, String to) rename;
    switch (widget.kind) {
      case SetupEditorKind.schoolGrade:
        names = store.schoolGradeOptions;
        customNames = store.customSchoolGrades;
        rename = store.renameSchoolGrade;
      case SetupEditorKind.universityYear:
        names = store.universityYearOptions;
        customNames = store.customUniversityYears;
        rename = store.renameUniversityYear;
      case SetupEditorKind.university:
        names = store.universities;
        customNames = store.customUniversities;
        rename = store.renameUniversity;
      case SetupEditorKind.faculty:
        names = store.facultiesFor(widget.universityName);
        customNames = store.customFacultiesFor(widget.universityName);
        rename = (from, to) => store.renameFaculty(
          universityName: widget.universityName,
          currentName: from,
          newName: to,
        );
      case SetupEditorKind.schoolSubject:
        names = store.schoolSubjectsFor(widget.grade, stream: widget.stream);
        customNames = store.customSchoolSubjectsFor(
          widget.grade,
          stream: widget.stream,
        );
        rename = (from, to) => store.renameSchoolSubject(
          grade: widget.grade,
          stream: widget.stream,
          currentName: from,
          newName: to,
        );
      case SetupEditorKind.campusCourse:
        names = store.campusSubjectsFor(
          universityName: widget.universityName,
          facultyName: widget.facultyName,
          year: widget.year,
        );
        customNames = store.customCampusSubjectsFor(
          universityName: widget.universityName,
          facultyName: widget.facultyName,
          year: widget.year,
        );
        rename = (from, to) => store.renameCampusSubject(
          universityName: widget.universityName,
          facultyName: widget.facultyName,
          year: widget.year,
          currentName: from,
          newName: to,
        );
    }
    return [
      for (final name in names)
        _EditableEntry(
          name: name,
          builtIn: !customNames.any(
            (custom) => custom.trim().toLowerCase() == name.toLowerCase(),
          ),
          rename: (newName) => rename(name, newName),
        ),
    ];
  }

  Future<void> _rename(_EditableEntry entry) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => RenameEntryDialog(
        title: 'Edit $_itemLabel',
        label: '$_itemLabel name',
        initialValue: entry.name,
      ),
    );
    if (!mounted || newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      _showMessage('Enter a name.');
      return;
    }
    if (trimmed == entry.name) return;
    if (!entry.rename(trimmed)) {
      _showMessage('"$_itemLabel $trimmed" already exists.');
      return;
    }
    setState(() => _entries = _buildEntries());
    _showMessage('$_itemLabel updated to "$trimmed".');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Edit setup'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fix the $_scopeLabel. Changes update every screen.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (_entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Nothing to edit yet. Use the + button to add a '
                  '$_itemLabel first.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return ListTile(
                      key: ValueKey('setup-edit-${entry.name}'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.drive_file_rename_outline),
                      title: Text(entry.name),
                      subtitle: entry.builtIn
                          ? Text(
                              'Built-in',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            )
                          : null,
                      trailing: IconButton(
                        tooltip: 'Edit ${entry.name}',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _rename(entry),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _EditableEntry {
  const _EditableEntry({
    required this.name,
    required this.builtIn,
    required this.rename,
  });

  final String name;
  final bool builtIn;
  final bool Function(String newName) rename;
}

class RenameEntryDialog extends StatefulWidget {
  const RenameEntryDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
  });

  final String title;
  final String label;
  final String initialValue;

  @override
  State<RenameEntryDialog> createState() => _RenameEntryDialogState();
}

class _RenameEntryDialogState extends State<RenameEntryDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

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
        key: const Key('rename-entry-field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('rename-entry-save'),
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
