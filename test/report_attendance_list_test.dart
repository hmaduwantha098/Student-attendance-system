import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_attendance_system/attendance_store.dart';
import 'package:student_attendance_system/reports_screen.dart';

void main() {
  test('markedDatesFor lists sorted marked dates for a student set', () {
    final store = AttendanceStore();
    store.setStatus('2026-05-02', 'a', AttendanceStatus.present);
    store.setStatus('2026-05-05', 'a', AttendanceStatus.present);
    store.setStatus('2026-05-05', 'b', AttendanceStatus.late);
    store.setStatus('2026-06-01', 'a', AttendanceStatus.present);

    expect(
      store.markedDatesFor(
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 31),
        studentIds: ['a'],
      ),
      ['2026-05-02', '2026-05-05'],
    );
    expect(
      store.markedDatesFor(
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 31),
        studentIds: ['a', 'b'],
      ),
      ['2026-05-02', '2026-05-05'],
    );
    expect(
      store.markedDatesFor(
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 31),
        studentIds: const <String>[],
      ),
      isEmpty,
    );
  });

  testWidgets('report shows grade totals and an attendance list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AttendanceStore();
    for (final name in ['Anil Perera', 'Bimala Silva', 'Chandra Weer']) {
      store.addStudent(
        name: name,
        institutionType: InstitutionType.school,
        groupName: 'Grade 8',
        subjectName: 'Mathematics',
      );
    }
    final ids = {
      for (final student in store.studentsFor(
        InstitutionType.school,
        'Grade 8',
      ))
        student.name: student.id,
    };
    final now = DateTime.now();
    final day1 = AttendanceStore.keyFor(DateTime(now.year, now.month, 1));
    final day2 = AttendanceStore.keyFor(DateTime(now.year, now.month, 2));

    store.setStatus(day1, ids['Anil Perera']!, AttendanceStatus.present);
    store.setStatus(day1, ids['Bimala Silva']!, AttendanceStatus.present);
    store.setStatus(day1, ids['Chandra Weer']!, AttendanceStatus.absent);
    store.setStatus(day2, ids['Anil Perera']!, AttendanceStatus.late);
    store.setStatus(day2, ids['Bimala Silva']!, AttendanceStatus.present);
    store.setStatus(day2, ids['Chandra Weer']!, AttendanceStatus.present);

    await tester.pumpWidget(MaterialApp(home: ReportsScreen(store: store)));
    await tester.pumpAndSettle();

    final totals = find.byKey(const Key('report-totals'));
    expect(totals, findsOneWidget);
    final roster = store.studentsFor(InstitutionType.school, 'Grade 8');
    expect(
      find.descendant(
        of: totals,
        matching: find.textContaining(
          '${roster.length} students in this selection',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: totals, matching: find.text('83%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: totals, matching: find.text('Sessions')),
      findsOneWidget,
    );

    final list = find.byKey(const Key('report-attendance-list'));
    expect(list, findsOneWidget);
    final day1Card = find.byKey(ValueKey('report-attendance-date-$day1'));
    final day2Card = find.byKey(ValueKey('report-attendance-date-$day2'));
    expect(day1Card, findsOneWidget);
    expect(day2Card, findsOneWidget);

    expect(
      find.descendant(of: day1Card, matching: find.text('Absent (1)')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: day1Card, matching: find.text('Chandra Weer')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: day2Card, matching: find.text('Late (1)')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: day2Card, matching: find.text('Anil Perera')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('report-attendance-empty')), findsNothing);
  });

  testWidgets('attendance list narrows to the chosen subject', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AttendanceStore();
    store.addStudent(
      name: 'Math Kid',
      institutionType: InstitutionType.school,
      groupName: 'Grade 8',
      subjectName: 'Mathematics',
    );
    store.addStudent(
      name: 'Science Kid',
      institutionType: InstitutionType.school,
      groupName: 'Grade 8',
      subjectName: 'Science',
    );
    final mathId = store.students.firstWhere((s) => s.name == 'Math Kid').id;
    final scienceId = store.students
        .firstWhere((s) => s.name == 'Science Kid')
        .id;
    final now = DateTime.now();
    final day1 = AttendanceStore.keyFor(DateTime(now.year, now.month, 1));
    store.setStatus(day1, mathId, AttendanceStatus.present);
    store.setStatus(day1, scienceId, AttendanceStatus.present);

    await tester.pumpWidget(MaterialApp(home: ReportsScreen(store: store)));
    await tester.pumpAndSettle();

    final list = find.byKey(const Key('report-attendance-list'));
    expect(
      find.descendant(of: list, matching: find.text('Math Kid, Science Kid')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('reports-subject-Grade 8-')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mathematics').last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: list, matching: find.text('Math Kid')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: list, matching: find.text('Science Kid')),
      findsNothing,
    );
  });

  testWidgets('university course filter narrows the list and totals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AttendanceStore();
    final courses = store.campusSubjectsFor(
      universityName: 'University of Colombo',
      facultyName: 'Faculty of Arts',
      year: 'First Year',
    );
    expect(courses.length, greaterThanOrEqualTo(2));
    final firstCourse = courses.first;
    final secondCourse = courses[1];

    store.addStudent(
      name: 'Alpha Kid',
      institutionType: InstitutionType.university,
      universityName: 'University of Colombo',
      facultyName: 'Faculty of Arts',
      groupName: 'First Year',
      subjectName: firstCourse,
    );
    store.addStudent(
      name: 'Beta Kid',
      institutionType: InstitutionType.university,
      universityName: 'University of Colombo',
      facultyName: 'Faculty of Arts',
      groupName: 'First Year',
      subjectName: secondCourse,
    );
    final firstId = store.students.singleWhere((s) => s.name == 'Alpha Kid').id;
    final secondId = store.students
        .singleWhere((s) => s.name == 'Beta Kid')
        .id;
    final now = DateTime.now();
    final day1 = AttendanceStore.keyFor(DateTime(now.year, now.month, 1));
    store.setStatus(day1, firstId, AttendanceStatus.present);
    store.setStatus(day1, secondId, AttendanceStatus.present);

    await tester.pumpWidget(MaterialApp(home: ReportsScreen(store: store)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('University'));
    await tester.pumpAndSettle();

    final courseDropdown = find.byKey(
      const ValueKey(
        'reports-course-University of Colombo-Faculty of Arts-First Year',
      ),
    );
    expect(courseDropdown, findsOneWidget);

    final totals = find.byKey(const Key('report-totals'));
    final list = find.byKey(const Key('report-attendance-list'));
    expect(
      find.descendant(
        of: totals,
        matching: find.textContaining('2 students in this selection'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: list, matching: find.text('Alpha Kid, Beta Kid')),
      findsOneWidget,
    );

    await tester.tap(courseDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(firstCourse).last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: list, matching: find.text('Alpha Kid')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: list, matching: find.text('Beta Kid')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: totals,
        matching: find.textContaining('1 student in this selection'),
      ),
      findsOneWidget,
    );
  });
}
