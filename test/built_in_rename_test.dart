import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_attendance_system/attendance_store.dart';
import 'package:student_attendance_system/main.dart';
import 'package:student_attendance_system/students_screen.dart';

void main() {
  group('built-in renames', () {
    late AttendanceStore store;

    setUp(() => store = AttendanceStore());

    test('renaming a built-in grade keeps its subjects and students', () {
      expect(store.schoolGradeOptions, contains('Grade 8'));
      expect(store.schoolGradeOptions, isNot(contains('Form 8')));
      expect(store.studentsFor(InstitutionType.school, 'Grade 8'), isNotEmpty);

      expect(store.renameSchoolGrade('Grade 8', 'Form 8'), isTrue);

      expect(store.schoolGradeOptions, contains('Form 8'));
      expect(store.schoolGradeOptions, isNot(contains('Grade 8')));
      expect(store.schoolGradeOptions, contains('Grade 9'));
      expect(store.schoolGradeNumber('Form 8'), 8);
      expect(store.schoolSubjectsFor('Form 8'), contains('Mathematics'));
      expect(store.studentsFor(InstitutionType.school, 'Form 8'), isNotEmpty);
      expect(store.studentsFor(InstitutionType.school, 'Grade 8'), isEmpty);
      expect(store.students.first.className, 'Form 8-A');
      expect(
        store.students.any((student) => student.className == 'Form 8-A'),
        isTrue,
      );
    });

    test('a built-in grade can be renamed twice and the latest name wins', () {
      expect(store.renameSchoolGrade('Grade 8', 'Form 8'), isTrue);
      expect(store.renameSchoolGrade('Form 8', 'Grade Eight'), isTrue);

      expect(store.schoolGradeOptions, contains('Grade Eight'));
      expect(store.schoolGradeOptions, isNot(contains('Grade 8')));
      expect(store.schoolGradeOptions, isNot(contains('Form 8')));
      expect(store.schoolGradeNumber('Grade Eight'), 8);
      expect(store.schoolSubjectsFor('Grade Eight'), contains('Mathematics'));
      expect(store.currentSchoolGradeName('Grade 8'), 'Grade Eight');
      expect(
        store.studentsFor(InstitutionType.school, 'Grade Eight'),
        isNotEmpty,
      );
    });

    test('renaming a built-in grade carries custom subjects across', () {
      expect(store.addSchoolSubject('Grade 8', 'Coding'), isTrue);

      expect(store.renameSchoolGrade('Grade 8', 'Form 8'), isTrue);

      expect(store.schoolSubjectsFor('Form 8'), contains('Coding'));
      expect(store.customSchoolSubjectsFor('Form 8'), contains('Coding'));
    });

    test('a built-in grade cannot be renamed onto an existing grade', () {
      expect(store.renameSchoolGrade('Grade 8', 'Grade 9'), isFalse);
      expect(store.schoolGradeOptions, contains('Grade 8'));
      expect(store.studentsFor(InstitutionType.school, 'Grade 8'), isNotEmpty);
    });

    test('unknown names and blank renames are rejected', () {
      expect(store.renameSchoolGrade('Grade 99', 'Form 99'), isFalse);
      expect(store.renameSchoolGrade('Grade 8', '   '), isFalse);
      expect(
        store.renameUniversity('Nowhere University', 'Somewhere'),
        isFalse,
      );
      expect(
        store.renameSchoolSubject(
          grade: 'Grade 8',
          currentName: 'Astrology',
          newName: 'Stars',
        ),
        isFalse,
      );
    });

    test('renaming a built-in subject keeps the rest of the list intact', () {
      final before = store.schoolSubjectsFor('Grade 8');
      expect(before, contains('Mathematics'));

      expect(
        store.renameSchoolSubject(
          grade: 'Grade 8',
          currentName: 'Mathematics',
          newName: 'Further Mathematics',
        ),
        isTrue,
      );

      final after = store.schoolSubjectsFor('Grade 8');
      expect(after, contains('Further Mathematics'));
      expect(after, isNot(contains('Mathematics')));
      expect(after.length, before.length);
      expect(after, contains('Science'));
      expect(
        store.currentSchoolSubjectName(
          grade: 'Grade 8',
          subjectName: 'Mathematics',
        ),
        'Further Mathematics',
      );
    });

    test('a built-in subject can be renamed twice', () {
      store.renameSchoolSubject(
        grade: 'Grade 8',
        currentName: 'Mathematics',
        newName: 'Further Mathematics',
      );
      expect(
        store.renameSchoolSubject(
          grade: 'Grade 8',
          currentName: 'Further Mathematics',
          newName: 'Advanced Maths',
        ),
        isTrue,
      );

      expect(store.schoolSubjectsFor('Grade 8'), contains('Advanced Maths'));
      expect(
        store.schoolSubjectsFor('Grade 8'),
        isNot(contains('Mathematics')),
      );
    });

    test('renaming a catalog institution keeps its badge and faculties', () {
      const original = 'University of Colombo';
      expect(store.universities, contains(original));
      expect(store.isBuiltInInstitution(original), isTrue);
      expect(store.kindFor(original), isNotNull);
      final faculties = store.facultiesFor(original);
      expect(faculties, isNotEmpty);

      expect(store.renameUniversity(original, 'Ceylon University'), isTrue);

      expect(store.universities, contains('Ceylon University'));
      expect(store.universities, isNot(contains(original)));
      expect(store.isBuiltInInstitution('Ceylon University'), isTrue);
      expect(store.kindFor('Ceylon University'), isNotNull);
      expect(store.facultiesFor('Ceylon University'), faculties);
    });

    test('renaming a built-in faculty keeps its catalog courses', () {
      const university = 'University of Colombo';
      const faculty = 'Faculty of Arts';
      expect(store.facultiesFor(university), contains(faculty));
      final courses = store.campusSubjectsFor(
        universityName: university,
        facultyName: faculty,
        year: 'First Year',
      );
      expect(courses, isNotEmpty);
      expect(
        store.catalogCourses(universityName: university, facultyName: faculty),
        isNotEmpty,
      );

      expect(
        store.renameFaculty(
          universityName: university,
          currentName: faculty,
          newName: 'Faculty of Humanities',
        ),
        isTrue,
      );

      final renamed = store.campusSubjectsFor(
        universityName: university,
        facultyName: 'Faculty of Humanities',
        year: 'First Year',
      );
      expect(renamed, courses);
      expect(store.facultiesFor(university), contains('Faculty of Humanities'));
      expect(store.facultiesFor(university), isNot(contains(faculty)));
      expect(store.facultiesFor(university), contains('Faculty of Science'));
      expect(
        store.currentFacultyName(
          universityName: university,
          facultyName: faculty,
        ),
        'Faculty of Humanities',
      );
    });

    test('renaming a built-in year updates the year options', () {
      expect(store.universityYearOptions, contains('First Year'));

      expect(store.renameUniversityYear('First Year', 'Year One'), isTrue);

      expect(store.universityYearOptions, contains('Year One'));
      expect(store.universityYearOptions, isNot(contains('First Year')));
      expect(store.universityYearOptions, contains('Second Year'));
      expect(store.currentUniversityYearName('First Year'), 'Year One');
    });

    test('renaming a built-in course updates the course list', () {
      const university = 'University of Colombo';
      const faculty = 'Faculty of Arts';
      final courses = store.campusSubjectsFor(
        universityName: university,
        facultyName: faculty,
        year: 'First Year',
      );
      final target = courses.first;
      final replacement = 'Course $target (Renamed)';

      expect(
        store.renameCampusSubject(
          universityName: university,
          facultyName: faculty,
          year: 'First Year',
          currentName: target,
          newName: replacement,
        ),
        isTrue,
      );

      final renamed = store.campusSubjectsFor(
        universityName: university,
        facultyName: faculty,
        year: 'First Year',
      );
      expect(renamed, contains(replacement));
      expect(renamed, isNot(contains(target)));
      expect(
        store.currentCampusCourseName(
          universityName: university,
          facultyName: faculty,
          year: 'First Year',
          courseName: target,
        ),
        replacement,
      );
    });

    test('custom entries still rename after built-in renames', () {
      expect(store.addUniversity('My Institute'), isTrue);
      expect(store.addFaculty('My Institute', 'Faculty of Design'), isTrue);
      expect(store.addSchoolSubject('Grade 8', 'Coding'), isTrue);
      expect(store.addSchoolGrade('Grade 14'), isTrue);

      expect(store.renameUniversity('My Institute', 'Our Institute'), isTrue);
      expect(store.universities, contains('Our Institute'));
      expect(
        store.facultiesFor('Our Institute'),
        contains('Faculty of Design'),
      );
      expect(
        store.renameFaculty(
          universityName: 'Our Institute',
          currentName: 'Faculty of Design',
          newName: 'Faculty of Art',
        ),
        isTrue,
      );
      expect(store.facultiesFor('Our Institute'), contains('Faculty of Art'));
      expect(
        store.renameSchoolSubject(
          grade: 'Grade 8',
          currentName: 'Coding',
          newName: 'Programming',
        ),
        isTrue,
      );
      expect(store.schoolSubjectsFor('Grade 8'), contains('Programming'));
      expect(store.renameSchoolGrade('Grade 14', 'Form 14'), isTrue);
      expect(store.schoolGradeOptions, contains('Form 14'));
      expect(store.schoolGradeOptions, isNot(contains('Grade 14')));
    });

    test('renaming a built-in grade does not touch other grades', () {
      expect(store.renameSchoolGrade('Grade 8', 'Form 8'), isTrue);

      expect(store.schoolSubjectsFor('Grade 7'), contains('Mathematics'));
      expect(store.schoolGradeNumber('Grade 7'), 7);
      expect(store.studentsFor(InstitutionType.school, 'Grade 7'), isEmpty);
      expect(
        store.schoolSubjectsFor('Grade 12', stream: 'Physical Science'),
        contains('Physics'),
      );
    });
  });

  group('setup editor lists built-in entries', () {
    Future<void> openAttendance(WidgetTester tester) async {
      AppAuth.signOut();
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const StudentAttendanceApp());
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'admin@attendify.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'secure123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Attendance'));
      await tester.pumpAndSettle();
    }

    testWidgets('the grade pencil lists built-in grades and can rename them', (
      tester,
    ) async {
      await openAttendance(tester);

      await tester.tap(find.byTooltip('Edit grades'));
      await tester.pumpAndSettle();

      expect(find.text('Edit setup'), findsOneWidget);
      expect(
        find.text('Fix the grades. Changes update every screen.'),
        findsOneWidget,
      );
      expect(find.textContaining('Nothing to edit yet'), findsNothing);
      expect(find.text('Built-in'), findsWidgets);

      await tester.tap(find.byTooltip('Edit Grade 1'));
      await tester.pumpAndSettle();

      final field = find.byKey(const Key('rename-entry-field'));
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Primary One');
      await tester.tap(find.byKey(const Key('rename-entry-save')));
      await tester.pumpAndSettle();

      expect(find.text('Grade updated to "Primary One".'), findsOneWidget);
      expect(find.text('Primary One'), findsWidgets);
      expect(find.text('Grade 1'), findsNothing);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // The untouched grade keeps its roster.
      expect(find.text('Grade 8'), findsWidgets);
      expect(find.text('Ava Thompson'), findsOneWidget);
      expect(
        AttendanceStore.instance.schoolGradeOptions,
        isNot(contains('Grade 1')),
      );
      expect(
        AttendanceStore.instance.schoolGradeOptions,
        contains('Primary One'),
      );

      final store = AttendanceStore.instance;
      addTearDown(() {
        store.renameSchoolGrade('Primary One', 'Grade 1');
      });
    });

    testWidgets('the subject pencil lists built-in subjects', (tester) async {
      await openAttendance(tester);

      await tester.tap(find.byTooltip('Edit subjects'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing to edit yet'), findsNothing);
      final editorList = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byTooltip('Edit Mathematics'),
        80,
        scrollable: editorList,
      );
      expect(find.text('Mathematics'), findsOneWidget);
    });

    testWidgets('the student screen pencil lists built-in subjects', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: StudentsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit subjects'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing to edit yet'), findsNothing);
      final editorList = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byTooltip('Edit Mathematics'),
        80,
        scrollable: editorList,
      );
      expect(find.text('Mathematics'), findsOneWidget);
    });

    testWidgets('the attendance subject picker reflects a renamed subject', (
      tester,
    ) async {
      final store = AttendanceStore.instance;
      addTearDown(() {
        store.renameSchoolSubject(
          grade: 'Grade 8',
          currentName: 'Further Mathematics',
          newName: 'Mathematics',
        );
      });

      await openAttendance(tester);

      await tester.tap(find.byTooltip('Edit subjects'));
      await tester.pumpAndSettle();
      final editorList = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byTooltip('Edit Mathematics'),
        80,
        scrollable: editorList,
      );
      await tester.ensureVisible(find.byTooltip('Edit Mathematics'));
      await tester.tap(find.byTooltip('Edit Mathematics'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('rename-entry-field')),
        'Further Mathematics',
      );
      await tester.tap(find.byKey(const Key('rename-entry-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('attendance-subject-Grade 8-')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('search-picker-field')),
        'Further',
      );
      await tester.pumpAndSettle();

      expect(find.text('Further Mathematics'), findsWidgets);
      expect(find.text('Mathematics'), findsNothing);
    });
  });
}
