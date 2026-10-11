import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_attendance_system/attendance_store.dart';
import 'package:student_attendance_system/reports_screen.dart';

void main() {
  testWidgets(
    'report log splits school teachers and university lecturers by subject',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = AttendanceStore();
      store.addStudent(
        name: 'Split School Student',
        institutionType: InstitutionType.school,
        groupName: 'Grade 8',
        subjectName: 'Mathematics',
      );
      store.addStudent(
        name: 'Split Uni Student',
        institutionType: InstitutionType.university,
        universityName: 'University of Colombo',
        facultyName: 'Faculty of Arts',
        groupName: 'First Year',
        subjectName: 'Technology',
      );

      final schoolIds = store.students
          .where(
            (student) =>
                student.institutionType == InstitutionType.school &&
                student.groupName == 'Grade 8',
          )
          .map((student) => student.id)
          .toList();
      final uniIds = store.students
          .where(
            (student) =>
                student.institutionType == InstitutionType.university &&
                student.universityName == 'University of Colombo',
          )
          .map((student) => student.id)
          .toList();

      final dateKey = AttendanceStore.keyFor(DateTime.now());
      for (final id in [...schoolIds, ...uniIds]) {
        store.setStatus(dateKey, id, AttendanceStatus.present);
      }
      store.recordAttendanceLog(
        dateKey: dateKey,
        institutionType: InstitutionType.school,
        groupName: 'Grade 8',
        subjectName: 'Mathematics',
        instructorName: 'Ms. Perera',
        studentIds: schoolIds,
      );
      store.recordAttendanceLog(
        dateKey: dateKey,
        institutionType: InstitutionType.university,
        groupName: 'First Year',
        subjectName: 'Technology',
        universityName: 'University of Colombo',
        facultyName: 'Faculty of Arts',
        instructorName: 'Dr. Fernando',
        studentIds: uniIds,
      );

      await tester.pumpWidget(MaterialApp(home: ReportsScreen(store: store)));
      await tester.pumpAndSettle();

      expect(find.text('School teachers (1)'), findsOneWidget);
      expect(find.text('University lecturers (1)'), findsOneWidget);

      expect(
        find.byKey(const ValueKey('report-log-teacher-Ms. Perera')),
        findsOneWidget,
      );
      expect(find.text('Mathematics'), findsWidgets);
      expect(
        find.textContaining('1 student records across 1 teacher'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('report-log-empty')), findsNothing);

      await tester.tap(find.text('University lecturers (1)'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('report-log-teacher-Dr. Fernando')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('report-log-teacher-Ms. Perera')),
        findsNothing,
      );
      expect(find.text('Technology'), findsWidgets);
      expect(
        find.textContaining('1 student records across 1 lecturer'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('report-log-empty')), findsNothing);
    },
  );

  testWidgets(
    'report log filters are independent per teacher and lecturer type',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = AttendanceStore();
      store.addStudent(
        name: 'Filter School Student',
        institutionType: InstitutionType.school,
        groupName: 'Grade 8',
        subjectName: 'Mathematics',
      );
      store.addStudent(
        name: 'Filter Uni Student',
        institutionType: InstitutionType.university,
        universityName: 'University of Colombo',
        facultyName: 'Faculty of Arts',
        groupName: 'First Year',
        subjectName: 'Technology',
      );

      final schoolIds = store.students
          .where(
            (student) =>
                student.institutionType == InstitutionType.school &&
                student.groupName == 'Grade 8',
          )
          .map((student) => student.id)
          .toList();
      final dateKey = AttendanceStore.keyFor(DateTime.now());
      for (final id in schoolIds) {
        store.setStatus(dateKey, id, AttendanceStatus.present);
      }
      store.recordAttendanceLog(
        dateKey: dateKey,
        institutionType: InstitutionType.school,
        groupName: 'Grade 8',
        subjectName: 'Mathematics',
        instructorName: 'Ms. Perera',
        studentIds: schoolIds,
      );

      await tester.pumpWidget(MaterialApp(home: ReportsScreen(store: store)));
      await tester.pumpAndSettle();

      expect(find.text('School teachers (1)'), findsOneWidget);
      expect(find.text('University lecturers (0)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('report-log-teacher-Ms. Perera')),
        findsOneWidget,
      );

      await tester.tap(find.text('University lecturers (0)'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('report-log-empty')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('report-log-teacher-Ms. Perera')),
        findsNothing,
      );
    },
  );
}
