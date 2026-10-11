import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:student_attendance_system/account_store.dart';
import 'package:student_attendance_system/attendance_store.dart';
import 'package:student_attendance_system/attendance_screen.dart';
import 'package:student_attendance_system/contact_store.dart';
import 'package:student_attendance_system/main.dart';
import 'package:student_attendance_system/reports_screen.dart';
import 'package:student_attendance_system/school_subject_catalog.dart';
import 'package:student_attendance_system/university_catalog.dart';

void main() {
  testWidgets('school subject attendance displays its assigned teacher', (
    tester,
  ) async {
    final store = AttendanceStore.instance;
    const name = 'Teacher Panel Student';
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    store.addStudent(
      name: name,
      className: 'Grade 5',
      groupName: 'Grade 5',
      subjectName: 'Mathematics',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AttendanceScreen(
          initialGroup: 'Grade 5',
          initialSubjectName: 'Mathematics',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mathematics · Grade 5'), findsOneWidget);
    expect(find.text(name), findsOneWidget);
    await tester.tap(find.byTooltip('Assign Teacher'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('instructor-name-field')),
      'Ms. Perera',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Teacher: Ms. Perera'), findsOneWidget);
    expect(
      store.instructorFor(
        institutionType: InstitutionType.school,
        groupName: 'Grade 5',
        subjectName: 'Mathematics',
      ),
      'Ms. Perera',
    );
  });

  testWidgets('reports show monthly and annual averages with late separate', (
    tester,
  ) async {
    final store = AttendanceStore();
    const studentName = 'Period Report Student';
    store.addStudent(
      name: studentName,
      className: 'Grade 8-A',
      institutionType: InstitutionType.school,
      groupName: 'Grade 8',
    );
    final student = store.students.singleWhere(
      (entry) => entry.name == studentName,
    );
    final now = DateTime.now();
    final monthlyPresent = AttendanceStore.keyFor(
      DateTime(now.year, now.month, 1),
    );
    final monthlyLate = AttendanceStore.keyFor(
      DateTime(now.year, now.month, 2),
    );
    final annualAbsent = AttendanceStore.keyFor(
      DateTime(now.year, now.month == 1 ? 2 : 1, 3),
    );
    store.setStatus(monthlyPresent, student.id, AttendanceStatus.present);
    store.setStatus(monthlyLate, student.id, AttendanceStatus.late);
    store.setStatus(annualAbsent, student.id, AttendanceStatus.absent);

    await tester.pumpWidget(MaterialApp(home: ReportsScreen(store: store)));
    await tester.pumpAndSettle();

    final studentReport = find.byKey(ValueKey('report-student-${student.id}'));
    await tester.scrollUntilVisible(
      studentReport,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(studentReport, findsOneWidget);
    expect(
      find.descendant(of: studentReport, matching: find.text('100%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: studentReport, matching: find.text('67%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: studentReport, matching: find.text('Late 1')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: studentReport, matching: find.text('Absent 0')),
      findsOneWidget,
    );

    store.clearDate(monthlyPresent);
    store.clearDate(monthlyLate);
    store.clearDate(annualAbsent);
    AppAuth.signOut();
  });

  test('student reports separate monthly and annual late attendance', () {
    final store = AttendanceStore();
    const studentId = 'period-report-student';
    store.setStatus('2026-03-02', studentId, AttendanceStatus.present);
    store.setStatus('2026-03-03', studentId, AttendanceStatus.late);
    store.setStatus('2026-03-04', studentId, AttendanceStatus.absent);
    store.setStatus('2026-04-01', studentId, AttendanceStatus.absent);
    store.setStatus('2027-03-01', studentId, AttendanceStatus.late);

    final march = store.reportForStudent(
      studentId,
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 3, 31),
    );
    expect(march.presentDays, 1);
    expect(march.lateDays, 1);
    expect(march.absentDays, 1);
    expect(march.averageAttendance, closeTo(200 / 3, 0.001));

    final year = store.reportForStudent(
      studentId,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
    );
    expect(year.presentDays, 1);
    expect(year.lateDays, 1);
    expect(year.absentDays, 2);
    expect(year.averageAttendance, 50);
  });

  test('school grades and university years keep separate attendance', () {
    final store = AttendanceStore();
    final dateKey = store.todayKey;

    expect(schoolGrades, hasLength(13));
    expect(universityYears, hasLength(4));
    expect(
      store.addStudent(
        name: 'Alex Morgan',
        className: 'Grade 1-A',
        institutionType: InstitutionType.school,
        groupName: 'Grade 1',
      ),
      isTrue,
    );
    expect(
      store.addStudent(
        name: 'Alex Morgan',
        className: 'First Year',
        institutionType: InstitutionType.university,
        groupName: 'First Year',
      ),
      isTrue,
    );

    final gradeOne = store.studentsFor(InstitutionType.school, 'Grade 1');
    final firstYear = store.studentsFor(
      InstitutionType.university,
      'First Year',
    );
    expect(gradeOne, hasLength(1));
    expect(firstYear, hasLength(1));

    store.markAllPresent(
      dateKey,
      studentIds: gradeOne.map((student) => student.id),
    );
    store.setStatus(dateKey, firstYear.single.id, AttendanceStatus.absent);
    expect(
      store.markedCount(dateKey, studentIds: gradeOne.map((s) => s.id)),
      1,
    );
    expect(
      store.countFor(
        dateKey,
        AttendanceStatus.absent,
        studentIds: gradeOne.map((s) => s.id),
      ),
      0,
    );

    store.clearDate(dateKey, studentIds: gradeOne.map((student) => student.id));
    expect(store.statusFor(dateKey, gradeOne.single.id), isNull);
    expect(
      store.statusFor(dateKey, firstYear.single.id),
      AttendanceStatus.absent,
    );
  });

  test('school subjects cover Grades 1-13 and have separate attendance', () {
    final store = AttendanceStore();
    expect(
      subjectsForSchoolGrade('Grade 1'),
      contains('Environmental Studies'),
    );
    expect(subjectsForSchoolGrade('Grade 5'), contains('Mathematics'));
    expect(subjectsForSchoolGrade('Grade 6'), contains('Science'));
    expect(
      subjectsForSchoolGrade('Grade 11'),
      contains('Business and Accounting Studies'),
    );
    expect(
      subjectsForSchoolGrade('Grade 12', stream: 'Commerce'),
      containsAll(['Accounting', 'Business Studies', 'Economics']),
    );
    expect(
      subjectsForSchoolGrade('Grade 13', stream: 'Technology'),
      containsAll(['Engineering Technology', 'Biosystems Technology']),
    );

    expect(
      store.addStudent(
        name: 'Sahan Silva',
        className: 'Grade 6',
        groupName: 'Grade 6',
        subjectName: 'Mathematics',
      ),
      isTrue,
    );
    expect(
      store.addStudent(
        name: 'Sahan Silva',
        className: 'Grade 6',
        groupName: 'Grade 6',
        subjectName: 'Science',
      ),
      isTrue,
    );
    final mathStudent = store
        .studentsFor(
          InstitutionType.school,
          'Grade 6',
          subjectName: 'Mathematics',
        )
        .single;
    final scienceStudent = store
        .studentsFor(InstitutionType.school, 'Grade 6', subjectName: 'Science')
        .single;
    final dateKey = store.todayKey;
    store.setStatus(dateKey, mathStudent.id, AttendanceStatus.late);
    store.setStatus(dateKey, scienceStudent.id, AttendanceStatus.present);

    expect(store.statusFor(dateKey, mathStudent.id), AttendanceStatus.late);
    expect(
      store.statusFor(dateKey, scienceStudent.id),
      AttendanceStatus.present,
    );
    expect(store.markedCount(dateKey, studentIds: [mathStudent.id]), 1);
  });

  test('instructor names are scoped to each subject and campus offering', () {
    final store = AttendanceStore();
    store.setInstructor(
      institutionType: InstitutionType.school,
      groupName: 'Grade 12',
      subjectName: 'Accounting',
      schoolStream: 'Commerce',
      name: 'Ms. Perera',
    );
    store.setInstructor(
      institutionType: InstitutionType.school,
      groupName: 'Grade 12',
      subjectName: 'Economics',
      schoolStream: 'Commerce',
      name: 'Mr. Silva',
    );
    store.setInstructor(
      institutionType: InstitutionType.university,
      groupName: 'First Year',
      universityName: 'University of Colombo',
      facultyName: 'Faculty of Science',
      name: 'Dr. Fernando',
    );

    expect(
      store.instructorFor(
        institutionType: InstitutionType.school,
        groupName: 'Grade 12',
        subjectName: 'Accounting',
        schoolStream: 'Commerce',
      ),
      'Ms. Perera',
    );
    expect(
      store.instructorFor(
        institutionType: InstitutionType.school,
        groupName: 'Grade 12',
        subjectName: 'Economics',
        schoolStream: 'Commerce',
      ),
      'Mr. Silva',
    );
    expect(
      store.instructorFor(
        institutionType: InstitutionType.school,
        groupName: 'Grade 13',
        subjectName: 'Accounting',
        schoolStream: 'Commerce',
      ),
      isEmpty,
    );
    expect(
      store.instructorFor(
        institutionType: InstitutionType.university,
        groupName: 'First Year',
        universityName: 'University of Colombo',
        facultyName: 'Faculty of Science',
      ),
      'Dr. Fernando',
    );
  });

  test(
    'university attendance is isolated by university, faculty, and year',
    () {
      final store = AttendanceStore();
      final dateKey = store.todayKey;
      const university = 'University of Colombo';
      const arts = 'Faculty of Arts';
      const science = 'Faculty of Science';

      expect(sriLankanInstitutionFaculties.length, greaterThanOrEqualTo(17));
      expect(
        store.addStudent(
          name: 'Nimal Perera',
          institutionType: InstitutionType.university,
          universityName: university,
          facultyName: arts,
          groupName: universityYears.first,
        ),
        isTrue,
      );
      expect(
        store.addStudent(
          name: 'Nimal Perera',
          institutionType: InstitutionType.university,
          universityName: university,
          facultyName: science,
          groupName: universityYears.first,
        ),
        isTrue,
      );

      final artsStudents = store.studentsFor(
        InstitutionType.university,
        universityYears.first,
        universityName: university,
        facultyName: arts,
      );
      final scienceStudents = store.studentsFor(
        InstitutionType.university,
        universityYears.first,
        universityName: university,
        facultyName: science,
      );
      expect(artsStudents, hasLength(1));
      expect(scienceStudents, hasLength(1));

      store.setStatus(dateKey, artsStudents.single.id, AttendanceStatus.late);
      store.setStatus(
        dateKey,
        scienceStudents.single.id,
        AttendanceStatus.present,
      );
      expect(
        store.markedCount(dateKey, studentIds: artsStudents.map((s) => s.id)),
        1,
      );
      expect(
        store.countFor(
          dateKey,
          AttendanceStatus.present,
          studentIds: artsStudents.map((s) => s.id),
        ),
        0,
      );
    },
  );

  testWidgets('login page appears first and accepts valid credentials', (
    tester,
  ) async {
    AppAuth.signOut();
    await tester.pumpWidget(const StudentAttendanceApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@attendify.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secure123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Smart Attendance'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Get Started'), findsNothing);
  });

  testWidgets('invalid credentials are rejected before dashboard access', (
    tester,
  ) async {
    AppAuth.signOut();
    await tester.pumpWidget(const StudentAttendanceApp());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'wrong@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(
      find.text('Invalid email or password. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Smart Attendance'), findsNothing);
  });

  testWidgets('home actions open the dashboard and profile can log out', (
    tester,
  ) async {
    AppAuth.signOut();
    await tester.pumpWidget(const StudentAttendanceApp());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@attendify.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secure123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(find.text('admin@attendify.com'), findsOneWidget);

    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(AppAuth.isAuthenticated, isFalse);
  });

  testWidgets('administrator can mark attendance and save the results', (
    tester,
  ) async {
    final store = AttendanceStore.instance;
    store.clearDate(store.todayKey);
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
    expect(find.text('Mark Attendance'), findsOneWidget);
    expect(find.text('Ava Thompson'), findsOneWidget);

    final rosterIds = store
        .studentsFor(InstitutionType.school, 'Grade 8')
        .map((student) => student.id)
        .toList();
    final total = rosterIds.length;
    await tester.tap(find.text('Mark all present'));
    await tester.pumpAndSettle();
    expect(store.markedCount(store.todayKey, studentIds: rosterIds), total);

    final avaCard = find.byKey(const ValueKey('attendance-student-1'));
    await tester.tap(
      find.descendant(of: avaCard, matching: find.text('Absent')),
    );
    await tester.pumpAndSettle();
    expect(store.statusFor(store.todayKey, '1'), AttendanceStatus.absent);
    expect(
      store.attendedCount(store.todayKey, studentIds: rosterIds),
      total - 1,
    );

    await tester.tap(find.text('Save attendance'));
    await tester.pump();
    expect(
      find.textContaining('Attendance saved: ${total - 1} attended'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Dashboard'));
    await tester.pumpAndSettle();
    final profilesCard = find.text('Manage profiles');
    await tester.ensureVisible(profilesCard);
    await tester.pumpAndSettle();
    await tester.tap(profilesCard);
    await tester.pumpAndSettle();
    expect(find.text('Ava Thompson'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);

    store.clearDate(store.todayKey, studentIds: rosterIds);
    AppAuth.signOut();
  });

  testWidgets('administrator can add a student name', (tester) async {
    final store = AttendanceStore.instance;
    final initialCount = store.students.length;
    AppAuth.signOut();

    await tester.pumpWidget(const StudentAttendanceApp());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@attendify.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secure123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Dashboard'));
    await tester.pumpAndSettle();
    final profilesCard = find.text('Manage profiles');
    await tester.ensureVisible(profilesCard);
    await tester.pumpAndSettle();
    await tester.tap(profilesCard);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add student'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add-student-name-field')),
      'Ravi Kumar',
    );
    await tester.enterText(
      find.byKey(const Key('add-student-class-field')),
      'Grade 9-C',
    );
    await tester.tap(find.byKey(const Key('add-student-submit')));
    await tester.pumpAndSettle();

    expect(store.students.length, initialCount + 1);
    expect(store.students.last.name, 'Ravi Kumar');
    expect(store.students.last.className, 'Grade 9-C');

    await tester.tap(find.byKey(const Key('students-group-school')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grade 9').last);
    await tester.pumpAndSettle();
    expect(find.text('Ravi Kumar'), findsOneWidget);

    await tester.tap(find.text('Mark'));
    await tester.pumpAndSettle();
    expect(find.text('Grade 9 students'), findsOneWidget);
    final studentSearch = find.byKey(const Key('attendance-student-search'));
    await tester.ensureVisible(studentSearch);
    await tester.enterText(studentSearch, 'Ravi');
    await tester.pumpAndSettle();
    expect(find.text('Ravi Kumar'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear student search'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add student'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add-student-name-field')),
      'ravi kumar',
    );
    await tester.tap(find.byKey(const Key('add-student-submit')));
    await tester.pumpAndSettle();
    expect(find.text('This student already exists'), findsOneWidget);
    expect(store.students.length, initialCount + 1);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('University'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('students-faculty-University of Colombo')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Faculty of Science').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add student'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add-student-name-field')),
      'Asha Fernando',
    );
    await tester.tap(find.byKey(const Key('add-student-submit')));
    await tester.pumpAndSettle();

    final universityStudent = store.students.singleWhere(
      (student) => student.name == 'Asha Fernando',
    );
    expect(universityStudent.universityName, 'University of Colombo');
    expect(universityStudent.facultyName, 'Faculty of Science');
    expect(universityStudent.groupName, 'First Year');
    await tester.tap(find.text('Mark'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('attendance-university-filter')),
      findsOneWidget,
    );
    expect(find.text('Faculty of Science'), findsOneWidget);
    expect(find.text('First Year'), findsOneWidget);
    final attendanceCard = find.byKey(
      ValueKey('attendance-student-${universityStudent.id}'),
    );
    await tester.scrollUntilVisible(
      attendanceCard,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Asha Fernando'), findsOneWidget);
    expect(
      find.text('First Year · Faculty of Science students'),
      findsOneWidget,
    );
    final assignLecturer = find.byTooltip('Assign Lecturer');
    await tester.scrollUntilVisible(
      assignLecturer,
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(assignLecturer);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('instructor-name-field')),
      'Dr. Fernando',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Lecturer: Dr. Fernando'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    AppAuth.signOut();
  });

  testWidgets('features page opens the matching screens', (tester) async {
    AppAuth.signOut();

    await tester.pumpWidget(const StudentAttendanceApp());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@attendify.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secure123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    final featuresLink = find.text('Features');
    await tester.ensureVisible(featuresLink);
    await tester.pumpAndSettle();
    await tester.tap(featuresLink);
    await tester.pumpAndSettle();
    expect(find.text('Everything you need to stay on track'), findsOneWidget);

    final studentFeature = find.text('Student management');
    await tester.ensureVisible(studentFeature);
    await tester.pumpAndSettle();
    await tester.tap(studentFeature);
    await tester.pumpAndSettle();
    expect(find.text('Class overview'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 900));
    await tester.pumpAndSettle();
    final attendanceFeature = find.text('Fast attendance tracking');
    expect(attendanceFeature, findsOneWidget);
    await tester.ensureVisible(attendanceFeature);
    await tester.pumpAndSettle();
    await tester.tap(attendanceFeature);
    await tester.pumpAndSettle();
    expect(find.text('Mark all present'), findsOneWidget);

    AppAuth.signOut();
  });

  testWidgets('contact page validates and keeps sent messages', (tester) async {
    final store = ContactStore.instance;
    store.clear();
    AppAuth.signOut();

    await tester.pumpWidget(const StudentAttendanceApp());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@attendify.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secure123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();
    expect(find.text("Let's talk"), findsOneWidget);

    await tester.tap(find.byKey(const Key('contact-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name'), findsOneWidget);
    expect(store.messages, isEmpty);

    await tester.enterText(
      find.byKey(const Key('contact-name-field')),
      'Nimal Perera',
    );
    await tester.enterText(
      find.byKey(const Key('contact-email-field')),
      'nimal@school.lk',
    );
    await tester.enterText(
      find.byKey(const Key('contact-message-field')),
      'How do I add a new class?',
    );
    await tester.tap(find.byKey(const Key('contact-submit')));
    await tester.pumpAndSettle();

    expect(store.messages.length, 1);
    expect(store.messages.first.name, 'Nimal Perera');
    expect(store.messages.first.message, 'How do I add a new class?');
    final savedCard = find.byKey(const ValueKey('contact-message-0'));
    for (var i = 0; i < 6 && savedCard.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
    }
    expect(
      find.descendant(
        of: savedCard,
        matching: find.text('How do I add a new class?'),
      ),
      findsOneWidget,
    );
    expect(find.text('Thanks. Your message has been sent.'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('contact-name-field')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('contact-name-field')),
      'Second Sender',
    );
    await tester.enterText(
      find.byKey(const Key('contact-email-field')),
      'second@school.lk',
    );
    await tester.enterText(
      find.byKey(const Key('contact-message-field')),
      'Second message body',
    );
    await tester.ensureVisible(find.byKey(const Key('contact-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('contact-submit')));
    await tester.pumpAndSettle();
    expect(store.messages.length, 2);

    await tester.tap(find.byTooltip('Delete all messages'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all messages?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(store.messages, isEmpty);
    expect(
      find.text('No messages yet. Messages you send appear here.'),
      findsOneWidget,
    );

    AppAuth.signOut();
  });

  testWidgets(
    'school grades, subjects and streams can be added while logged in',
    (tester) async {
      final store = AttendanceStore.instance;
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

      const grade = 'Grade 13';
      expect(store.schoolGradeOptions, contains(grade));

      final gradeFilter = find.byKey(const ValueKey('attendance-group-school'));
      await tester.ensureVisible(gradeFilter);
      await tester.tap(gradeFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a grade...').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('attendance-name-entry-field')),
        'Grade 99',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(store.schoolGradeOptions, contains('Grade 99'));

      expect(store.addSchoolGrade('grade 99'), isFalse);

      await tester.tap(gradeFilter);
      await tester.pumpAndSettle();
      expect(find.text('Grade 99'), findsWidgets);
      await tester.tapAt(const Offset(700, 1800));
      await tester.pumpAndSettle();

      final subjectFilter = find.byKey(
        const ValueKey('attendance-subject-Grade 99-'),
      );
      await tester.ensureVisible(subjectFilter);
      await tester.tap(subjectFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a subject...').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('attendance-name-entry-field')),
        'Computer Science',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(store.schoolSubjectsFor('Grade 99'), contains('Computer Science'));
      expect(find.text('Computer Science · Grade 99'), findsOneWidget);

      AppAuth.signOut();
    },
  );

  testWidgets(
    'university years, institutions and courses can be added while logged in',
    (tester) async {
      final store = AttendanceStore.instance;
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

      await tester.tap(find.text('University'));
      await tester.pumpAndSettle();

      final universityFilter = find.byKey(
        const Key('attendance-university-filter'),
      );
      await tester.ensureVisible(universityFilter);
      await tester.tap(find.byTooltip('Add university or institute'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('attendance-name-entry-field')),
        'Test Institute of Technology',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(store.universities, contains('Test Institute of Technology'));

      final facultyFilter = find.byKey(
        ValueKey('attendance-faculty-Test Institute of Technology'),
      );
      await tester.ensureVisible(facultyFilter);
      await tester.tap(facultyFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a faculty...').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('attendance-name-entry-field')),
        'Faculty of Computing',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(
        store.facultiesFor('Test Institute of Technology'),
        contains('Faculty of Computing'),
      );

      final yearFilter = find.byKey(
        const ValueKey('attendance-group-university'),
      );
      await tester.ensureVisible(yearFilter);
      await tester.tap(yearFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a year...').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('attendance-name-entry-field')),
        'Fifth Year',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(store.universityYearOptions, contains('Fifth Year'));

      final yearFilterUpdated = find.byKey(
        ValueKey('attendance-group-university'),
      );
      await tester.ensureVisible(yearFilterUpdated);
      await tester.tap(yearFilterUpdated);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fifth Year').last);
      await tester.pumpAndSettle();

      final courseFilter = find.byKey(
        ValueKey(
          'attendance-campus-course-Test Institute of Technology-Faculty of Computing-Fifth Year',
        ),
      );
      await tester.ensureVisible(courseFilter);
      await tester.tap(courseFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add a course / subject...').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('attendance-name-entry-field')),
        'Software Engineering',
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(
        store.campusSubjectsFor(
          universityName: 'Test Institute of Technology',
          facultyName: 'Faculty of Computing',
          year: 'Fifth Year',
        ),
        contains('Software Engineering'),
      );

      AppAuth.signOut();
    },
  );

  testWidgets('students can be added to a new grade and campus course', (
    tester,
  ) async {
    final store = AttendanceStore.instance;
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

    await tester.tap(find.text('Open Dashboard'));
    await tester.pumpAndSettle();
    final profilesCard = find.text('Manage profiles');
    await tester.ensureVisible(profilesCard);
    await tester.pumpAndSettle();
    await tester.tap(profilesCard);
    await tester.pumpAndSettle();

    final groupFilter = find.byKey(const ValueKey('students-group-school'));
    await tester.ensureVisible(groupFilter);
    await tester.tap(groupFilter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a grade...').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('students-name-entry-field')),
      'Grade 14',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(store.schoolGradeOptions, contains('Grade 14'));

    final subjectFilter = find.byKey(
      const ValueKey('students-subject-Grade 14-'),
    );
    await tester.ensureVisible(subjectFilter);
    await tester.tap(subjectFilter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a subject...').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('students-name-entry-field')),
      'ICT',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add student'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('add-student-name-field')),
      'New Grade Student',
    );
    await tester.tap(find.byKey(const Key('add-student-submit')));
    await tester.pumpAndSettle();

    expect(
      store
          .studentsFor(InstitutionType.school, 'Grade 14', subjectName: 'ICT')
          .map((student) => student.name),
      contains('New Grade Student'),
    );

    AppAuth.signOut();
  });

  test('marking attendance records the date and time it was marked', () {
    final store = AttendanceStore();
    const studentId = '1';
    final before = DateTime.now();

    expect(store.markedAtFor(store.todayKey), isNull);
    store.markAllPresent(store.todayKey, studentIds: [studentId]);
    final markedAt = store.markedAtFor(store.todayKey);
    expect(markedAt, isNotNull);
    expect(
      markedAt!.isBefore(before.subtract(const Duration(seconds: 1))),
      isFalse,
    );
    expect(
      markedAt.isAfter(DateTime.now().add(const Duration(seconds: 1))),
      isFalse,
    );
    expect(
      store.markedAtLabelFor(store.todayKey),
      contains('T'.replaceAll('T', ':')),
    );

    store.clearStatus(store.todayKey, studentId);
    expect(store.statusFor(store.todayKey, studentId), isNull);
    expect(store.markedAtFor(store.todayKey), isNotNull);

    store.clearDate(store.todayKey);
    expect(store.markedAtFor(store.todayKey), isNull);
    expect(store.markedAtLabelFor(store.todayKey), isNull);
  });

  testWidgets('university marking shows the lecturer and subject taught', (
    tester,
  ) async {
    final store = AttendanceStore.instance;
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    store.addUniversityYear('Fifth Year');
    store.addUniversity('Lecturer Panel Institute');
    store.addFaculty('Lecturer Panel Institute', 'Institute of Technology');
    store.addCampusSubject(
      universityName: 'Lecturer Panel Institute',
      facultyName: 'Institute of Technology',
      year: 'Fifth Year',
      subjectName: 'Robotics',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceScreen(
          initialInstitutionType: InstitutionType.university,
          initialGroup: 'Fifth Year',
          initialUniversityName: 'Lecturer Panel Institute',
          initialFacultyName: 'Institute of Technology',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Subject taught: All subjects'), findsOneWidget);
    expect(
      find.textContaining('Robotics — Lecturer not assigned'),
      findsOneWidget,
    );

    store.setInstructor(
      institutionType: InstitutionType.university,
      groupName: 'Fifth Year',
      subjectName: 'Robotics',
      universityName: 'Lecturer Panel Institute',
      facultyName: 'Institute of Technology',
      name: 'Dr. Silva',
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'attendance-campus-course-Lecturer Panel Institute-Institute of Technology-Fifth Year',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Robotics').last);
    await tester.pumpAndSettle();

    expect(find.text('Subject taught: Robotics'), findsOneWidget);
    expect(find.text('Lecturer: Dr. Silva'), findsOneWidget);
    expect(
      find.text(
        'Lecturer Panel Institute · Institute of Technology · Fifth Year',
      ),
      findsOneWidget,
    );
  });

  test('added setup entries can be renamed and updates follow the change', () {
    final store = AttendanceStore();

    expect(store.addSchoolGrade('Grade 77'), isTrue);
    expect(store.addSchoolSubject('Grade 77', 'Astronomy'), isTrue);
    expect(
      store.addStudent(
        name: 'Grade 77 Pupil',
        groupName: 'Grade 77',
        subjectName: 'Astronomy',
      ),
      isTrue,
    );
    store.setInstructor(
      institutionType: InstitutionType.school,
      groupName: 'Grade 77',
      subjectName: 'Astronomy',
      name: 'Ms. Perera',
    );

    expect(store.renameSchoolGrade('Grade 77', 'Grade 70'), isTrue);
    expect(store.schoolGradeOptions, isNot(contains('Grade 77')));
    expect(store.schoolGradeOptions, contains('Grade 70'));
    expect(store.schoolSubjectsFor('Grade 70'), contains('Astronomy'));
    expect(store.customSchoolSubjectsFor('Grade 70'), contains('Astronomy'));
    expect(
      store
          .studentsFor(
            InstitutionType.school,
            'Grade 70',
            subjectName: 'Astronomy',
          )
          .map((student) => student.name),
      contains('Grade 77 Pupil'),
    );
    expect(
      store.instructorFor(
        institutionType: InstitutionType.school,
        groupName: 'Grade 70',
        subjectName: 'Astronomy',
      ),
      'Ms. Perera',
    );
    expect(store.renameSchoolGrade('Grade 70', 'Grade 8'), isFalse);
    expect(store.renameSchoolGrade('Grade 8', 'Grade 9'), isFalse);

    expect(
      store.addSchoolSubject('Grade 70', 'Astronomy', stream: 'Science'),
      isTrue,
    );
    expect(
      store.renameSchoolSubject(
        grade: 'Grade 70',
        stream: 'Science',
        currentName: 'Astronomy',
        newName: 'Astrophysics',
      ),
      isTrue,
    );
    expect(
      store.customSchoolSubjectsFor('Grade 70', stream: 'Science'),
      contains('Astrophysics'),
    );

    expect(store.addUniversityYear('Fifth Year'), isTrue);
    expect(store.addUniversity('Edit Institute'), isTrue);
    expect(store.addFaculty('Edit Institute', 'Institute of Science'), isTrue);
    expect(
      store.addCampusSubject(
        universityName: 'Edit Institute',
        facultyName: 'Institute of Science',
        year: 'Fifth Year',
        subjectName: 'Robotics',
      ),
      isTrue,
    );
    expect(
      store.addStudent(
        name: 'Campus Student',
        institutionType: InstitutionType.university,
        groupName: 'Fifth Year',
        universityName: 'Edit Institute',
        facultyName: 'Institute of Science',
        subjectName: 'Robotics',
      ),
      isTrue,
    );

    expect(
      store.renameUniversity('Edit Institute', 'Edited Institute'),
      isTrue,
    );
    expect(
      store.facultiesFor('Edited Institute'),
      contains('Institute of Science'),
    );
    expect(
      store.customCampusSubjectsFor(
        universityName: 'Edited Institute',
        facultyName: 'Institute of Science',
        year: 'Fifth Year',
      ),
      contains('Robotics'),
    );
    expect(
      store
          .studentsFor(
            InstitutionType.university,
            'Fifth Year',
            universityName: 'Edited Institute',
            subjectName: 'Robotics',
          )
          .map((student) => student.name),
      contains('Campus Student'),
    );

    expect(
      store.renameFaculty(
        universityName: 'Edited Institute',
        currentName: 'Institute of Science',
        newName: 'Institute of Computing',
      ),
      isTrue,
    );
    expect(
      store.customCampusSubjectsFor(
        universityName: 'Edited Institute',
        facultyName: 'Institute of Computing',
        year: 'Fifth Year',
      ),
      contains('Robotics'),
    );

    expect(store.renameUniversityYear('Fifth Year', 'Sixth Year'), isTrue);
    expect(
      store.customCampusSubjectsFor(
        universityName: 'Edited Institute',
        facultyName: 'Institute of Computing',
        year: 'Sixth Year',
      ),
      contains('Robotics'),
    );
    expect(
      store.renameCampusSubject(
        universityName: 'Edited Institute',
        facultyName: 'Institute of Computing',
        year: 'Sixth Year',
        currentName: 'Robotics',
        newName: 'Advanced Robotics',
      ),
      isTrue,
    );
    expect(
      store
          .studentsFor(
            InstitutionType.university,
            'Sixth Year',
            universityName: 'Edited Institute',
            facultyName: 'Institute of Computing',
            subjectName: 'Advanced Robotics',
          )
          .map((student) => student.name),
      contains('Campus Student'),
    );
  });

  testWidgets('setup entries added by mistake can be edited from the app', (
    tester,
  ) async {
    final store = AttendanceStore.instance;
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

    final gradeFilter = find.byKey(const ValueKey('attendance-group-school'));
    await tester.ensureVisible(gradeFilter);
    await tester.tap(gradeFilter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a grade...').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('attendance-name-entry-field')),
      'Grade 96',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(store.schoolGradeOptions, contains('Grade 96'));

    await tester.tap(find.byTooltip('Edit grades'));
    await tester.pumpAndSettle();
    final editorList = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byTooltip('Edit Grade 96'),
      120,
      scrollable: editorList,
    );
    await tester.drag(editorList, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(find.text('Grade 96'), findsWidgets);

    await tester.tap(find.byTooltip('Edit Grade 96'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('rename-entry-field')),
      'Grade 96 - A',
    );
    await tester.tap(find.byKey(const Key('rename-entry-save')));
    await tester.pumpAndSettle();

    expect(store.schoolGradeOptions, isNot(contains('Grade 96')));
    expect(store.schoolGradeOptions, contains('Grade 96 - A'));

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attendance-group-school')));
    await tester.pumpAndSettle();
    expect(find.text('Grade 96 - A'), findsOneWidget);

    AppAuth.signOut();
  });

  testWidgets('added categories are listed, searchable and editable', (
    tester,
  ) async {
    final store = AttendanceStore.instance;
    AppAuth.signOut();
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    store.addUniversity('Listing Institute');
    store.addFaculty('Listing Institute', 'Institute of Listing');
    store.addCampusSubject(
      universityName: 'Listing Institute',
      facultyName: 'Institute of Listing',
      year: 'Fifth Year',
      subjectName: 'Catalogue Design',
    );
    store.addSchoolSubject('Grade 95', 'Searchable Subject');

    await tester.pumpWidget(const StudentAttendanceApp());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@attendify.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secure123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Features'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved categories'));
    await tester.pumpAndSettle();

    expect(find.text('Saved Categories'), findsOneWidget);
    expect(find.text('Listing Institute'), findsWidgets);
    expect(find.text('Institute of Listing'), findsOneWidget);
    expect(find.text('Catalogue Design'), findsOneWidget);
    expect(find.text('Searchable Subject'), findsOneWidget);
    expect(find.textContaining('categories added'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('categories-search')), 'cata');
    await tester.pumpAndSettle();
    expect(find.text('Catalogue Design'), findsOneWidget);
    expect(find.text('Institute of Listing'), findsNothing);
    expect(find.textContaining('match "cata"'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('categories-search')),
      'Listing Institute',
    );
    await tester.pumpAndSettle();
    expect(find.text('Institute of Listing'), findsOneWidget);
    expect(find.text('Catalogue Design'), findsOneWidget);
    expect(find.text('Searchable Subject'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('categories-search')),
      'nothing matches this',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No categories match'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit Catalogue Design'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('rename-entry-field')),
      'Catalogue Design II',
    );
    await tester.tap(find.byKey(const Key('rename-entry-save')));
    await tester.pumpAndSettle();

    expect(
      store.customCampusSubjectsFor(
        universityName: 'Listing Institute',
        facultyName: 'Institute of Listing',
        year: 'Fifth Year',
      ),
      contains('Catalogue Design II'),
    );
    expect(find.text('Catalogue Design II'), findsOneWidget);

    AppAuth.signOut();
  });

  testWidgets('about page opens from features and home navigation', (
    tester,
  ) async {
    AppAuth.signOut();

    await tester.pumpWidget(const StudentAttendanceApp());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@attendify.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secure123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    final aboutLink = find.text('About');
    await tester.ensureVisible(aboutLink);
    await tester.pumpAndSettle();
    await tester.tap(aboutLink);
    await tester.pumpAndSettle();

    expect(find.text('About Attendify'), findsOneWidget);
    expect(find.text('Live workspace stats'), findsOneWidget);

    final version = find.text('Version 1.0.0');
    await tester.scrollUntilVisible(version, 200);
    await tester.pumpAndSettle();
    expect(version, findsOneWidget);

    final talkButton = find.text('Talk to our team');
    await tester.scrollUntilVisible(talkButton, 200);
    await tester.pumpAndSettle();
    await tester.tap(talkButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('question about Attendify'), findsOneWidget);

    AppAuth.signOut();
  });

  test('authentication accepts only the configured administrator account', () {
    AppAuth.signOut();

    expect(
      AppAuth.validateCredentials('admin@attendify.com', 'secure123'),
      isTrue,
    );
    expect(
      AppAuth.validateCredentials(' ADMIN@ATTENDIFY.COM ', 'secure123'),
      isTrue,
    );
    expect(
      AppAuth.validateCredentials('admin@attendify.com', 'wrong'),
      isFalse,
    );
    expect(AppAuth.signIn('admin@attendify.com', 'secure123'), isTrue);
    expect(AppAuth.isAuthenticated, isTrue);
    expect(AppAuth.authenticatedEmail, 'admin@attendify.com');

    AppAuth.signOut();
    expect(AppAuth.isAuthenticated, isFalse);
    expect(AppAuth.authenticatedEmail, isNull);
  });

  test('catalog covers the 19 state universities and university colleges', () {
    final store = AttendanceStore.instance;

    expect(sriLankanStateUniversities.length, 19);
    expect(sriLankanStateUniversityCount, 19);
    expect(sriLankanTechnologicalInstitutes.length, 19);
    expect(sriLankanTechnologicalInstituteCount, 19);
    expect(sriLankanUniversityColleges, isNotEmpty);
    expect(
      sriLankanStateUniversityCount +
          sriLankanUniversityCollegeCount +
          sriLankanTechnologicalInstituteCount,
      sriLankanInstitutions.length,
    );

    final names = sriLankanInstitutions.map((item) => item.name).toList();
    expect(
      names.toSet().length,
      names.length,
      reason: 'institution names must be unique',
    );

    for (final institution in sriLankanInstitutions) {
      expect(institution.faculties, isNotEmpty, reason: institution.name);
      expect(institution.courseCount, greaterThan(0), reason: institution.name);
      expect(institution.city, isNotEmpty, reason: institution.name);
    }

    expect(
      universityKindFor('University of Colombo'),
      UniversityKind.stateUniversity,
    );
    expect(
      universityKindFor('University of Vavuniya'),
      UniversityKind.stateUniversity,
    );
    expect(
      universityKindFor('Bhiksu University of Sri Lanka'),
      UniversityKind.stateUniversity,
    );
    expect(
      universityKindFor(
        'Sri Lanka Institute of Information Technology (SLIIT)',
      ),
      UniversityKind.universityCollege,
    );
    expect(
      universityKindFor('ATI Colombo (Mattakkuliya / Maradana)'),
      UniversityKind.advancedTechnologicalInstitute,
    );
    expect(
      universityKindFor('University College of Ratmalana (UCR)'),
      UniversityKind.universityCollege,
    );
    expect(universityCityFor('University of Peradeniya'), 'Peradeniya');
    expect(universityCityFor('University College of Jaffna (UCJ)'), 'Jaffna');

    expect(store.catalogStateUniversities.length, 19);
    expect(store.catalogUniversityColleges, isNotEmpty);
    expect(store.universities, containsAll(names));
    expect(
      store.universities,
      containsAll([
        'The Open University of Sri Lanka',
        'Gampaha Wickramarachchi University of Indigenous Medicine',
        'Buddhist and Pali University of Sri Lanka',
        'ATI Jaffna',
        'ATI Sammanthurai',
        'University College of Matara (UCM)',
        'University College of Batangala (UCB - Ratnapura)',
      ]),
    );
    expect(
      store.facultiesFor('University of Peradeniya'),
      contains('Faculty of Medicine'),
    );

    expect(
      store.campusSubjectsFor(
        universityName: 'University of Peradeniya',
        facultyName: 'Faculty of Medicine',
        year: 'First Year',
      ),
      contains('MBBS'),
    );
    expect(
      store.campusSubjectsFor(
        universityName: 'ATI Colombo (Mattakkuliya / Maradana)',
        facultyName: 'Higher National Diploma Programmes',
        year: 'First Year',
      ),
      contains('HNDIT (Higher National Diploma in Information Technology)'),
    );
    expect(
      store.campusSubjectsFor(
        universityName: 'University College of Ratmalana (UCR)',
        facultyName: 'NVQ Level 5 and 6 Programmes',
        year: 'First Year',
      ),
      contains('Hospitality Management'),
    );
    expect(
      store.addCampusSubject(
        universityName: 'University of Peradeniya',
        facultyName: 'Faculty of Medicine',
        year: 'First Year',
        subjectName: 'mbbs',
      ),
      isFalse,
      reason: 'catalog courses already exist for this offering',
    );
    expect(store.isBuiltInInstitution('University of Colombo'), isTrue);
  });

  testWidgets(
    'university directory lists state universities and their courses',
    (tester) async {
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

      await tester.tap(find.text('Features'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('University directory'));
      await tester.pumpAndSettle();

      expect(find.text('University Directory'), findsOneWidget);
      expect(find.textContaining('19 state universities'), findsOneWidget);
      expect(find.text('State universities (19)'), findsOneWidget);
      expect(find.text('University of Moratuwa'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('university-University of Moratuwa')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('BSc in Computer Science and Engineering'),
        findsOneWidget,
      );
      expect(find.textContaining('State university'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('universities-search')),
        'SLIIT',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Sri Lanka Institute of Information Technology (SLIIT)'),
        findsOneWidget,
      );
      expect(find.text('University of Moratuwa'), findsNothing);
      expect(find.textContaining('match "SLIIT"'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('State universities (19)'), findsOneWidget);

      AppAuth.signOut();
    },
  );

  testWidgets('settings create a profile and update email and password', (
    tester,
  ) async {
    final account = AccountStore.instance;
    addTearDown(account.resetToDefaults);
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

    await tester.tap(find.text('Features'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Create profile'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-profile-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-profile-save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('settings-profile-name-field')),
      'Nimali Perera',
    );
    await tester.enterText(
      find.byKey(const Key('settings-profile-role-field')),
      'Lecturer',
    );
    await tester.enterText(
      find.byKey(const Key('settings-profile-institution-field')),
      'Green Valley Academy',
    );
    await tester.enterText(
      find.byKey(const Key('settings-profile-department-field')),
      'Computer Science',
    );
    await tester.enterText(
      find.byKey(const Key('settings-profile-phone-field')),
      '0771234567',
    );
    await tester.enterText(
      find.byKey(const Key('settings-profile-employee-field')),
      'EMP-204',
    );
    await tester.tap(find.byKey(const Key('settings-profile-save')));
    await tester.pumpAndSettle();

    expect(account.profile.fullName, 'Nimali Perera');
    expect(account.profile.role, 'Lecturer');
    expect(account.profile.employeeId, 'EMP-204');
    expect(find.text('Nimali Perera'), findsWidgets);
    expect(find.text('Edit profile'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-email-open')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('settings-email-current-password')),
      'wrongpass',
    );
    await tester.enterText(
      find.byKey(const Key('settings-email-field')),
      'nimali@attendify.com',
    );
    await tester.tap(find.byKey(const Key('settings-email-save')));
    await tester.pumpAndSettle();
    expect(find.text('Your current password is incorrect.'), findsOneWidget);
    expect(account.email, 'admin@attendify.com');

    await tester.enterText(
      find.byKey(const Key('settings-email-current-password')),
      'secure123',
    );
    await tester.tap(find.byKey(const Key('settings-email-save')));
    await tester.pumpAndSettle();
    expect(account.email, 'nimali@attendify.com');
    expect(AppAuth.authenticatedEmail, 'nimali@attendify.com');

    await tester.tap(find.byKey(const Key('settings-password-open')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('settings-password-current')),
      'secure123',
    );
    await tester.enterText(
      find.byKey(const Key('settings-password-field')),
      'newpass123',
    );
    await tester.enterText(
      find.byKey(const Key('settings-password-confirm')),
      'newpass456',
    );
    await tester.tap(find.byKey(const Key('settings-password-save')));
    await tester.pumpAndSettle();
    expect(
      find.text('New password confirmation does not match.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('settings-password-confirm')),
      'newpass123',
    );
    await tester.tap(find.byKey(const Key('settings-password-save')));
    await tester.pumpAndSettle();
    expect(account.password, 'newpass123');
    expect(
      account.validateCredentials('nimali@attendify.com', 'newpass123'),
      isTrue,
    );
    expect(
      account.validateCredentials('admin@attendify.com', 'secure123'),
      isFalse,
    );

    AppAuth.signOut();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const StudentAttendanceApp());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'admin@attendify.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secure123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(
      find.text('Invalid email or password. Please try again.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'nimali@attendify.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'newpass123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    expect(find.text('Smart Attendance'), findsOneWidget);

    AppAuth.signOut();
  });

  test('attendance logs group by teacher and subject with marked time', () {
    final store = AttendanceStore();
    final ids = ['1', '2', '3'];

    store.markAllPresent(store.todayKey, studentIds: ids);
    store.recordAttendanceLog(
      dateKey: store.todayKey,
      institutionType: InstitutionType.school,
      groupName: 'Grade 7',
      subjectName: 'Mathematics',
      instructorName: 'Nimali Perera',
      studentIds: ids,
    );
    store.setStatus(store.todayKey, '3', AttendanceStatus.absent);
    store.recordAttendanceLog(
      dateKey: store.todayKey,
      institutionType: InstitutionType.school,
      groupName: 'Grade 7',
      subjectName: 'Mathematics',
      instructorName: 'Nimali Perera',
      studentIds: ids,
    );
    store.recordAttendanceLog(
      dateKey: store.todayKey,
      institutionType: InstitutionType.school,
      groupName: 'Grade 7',
      subjectName: 'Science',
      instructorName: 'Nimali Perera',
      studentIds: ids,
    );

    final period = {
      'startDate': DateTime.now().subtract(const Duration(days: 1)),
      'endDate': DateTime.now().add(const Duration(days: 1)),
    };
    final logs = store.logsForPeriod(
      startDate: period['startDate']!,
      endDate: period['endDate']!,
    );

    expect(logs.length, 2, reason: 'saving again replaces the same session');
    expect(
      logs.map((entry) => entry.subjectLabel),
      containsAll(['Mathematics', 'Science']),
    );
    expect(
      logs.every((entry) => entry.instructorLabel == 'Nimali Perera'),
      isTrue,
    );
    expect(
      logs.every((entry) => entry.markedAt.day == DateTime.now().day),
      isTrue,
    );
    expect(logs.map((entry) => entry.absentCount), contains(1));
    expect(
      store
          .logsForPeriod(
            startDate: period['startDate']!,
            endDate: period['endDate']!,
            subjectName: 'Mathematics',
          )
          .length,
      1,
    );
    expect(
      store.logsForPeriod(
        startDate: DateTime.now().subtract(const Duration(days: 6)),
        endDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      isEmpty,
    );

    store.clearLogs();
    expect(store.logs, isEmpty);
  });

  testWidgets(
    'subject picker filters by typed text and student search narrows the roster',
    (tester) async {
      final store = AttendanceStore.instance;
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

      final subjectPicker = find.byKey(
        const ValueKey('attendance-subject-Grade 8-'),
      );
      await tester.ensureVisible(subjectPicker);
      await tester.tap(subjectPicker);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('search-picker-field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('search-picker-field')),
        'sci',
      );
      await tester.pumpAndSettle();
      expect(find.text('Science'), findsOneWidget);
      expect(find.text('Mathematics'), findsNothing);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('search-picker-field')),
        'all',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('search-picker-option-All subjects')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('search-picker-field')), findsNothing);

      final roster = store.studentsFor(InstitutionType.school, 'Grade 8');
      final search = find.byKey(const Key('attendance-student-search'));
      await tester.ensureVisible(search);
      expect(
        find.text('Showing all ${roster.length} students'),
        findsOneWidget,
      );

      await tester.enterText(search, 'ava');
      await tester.pumpAndSettle();
      expect(
        find.text('Showing 1 of ${roster.length} students'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('attendance-student-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('attendance-student-${roster.last.id}')),
        findsNothing,
      );

      await tester.enterText(search, 'zzz');
      await tester.pumpAndSettle();
      expect(
        find.text('Showing 0 of ${roster.length} students'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Clear student search'));
      await tester.pumpAndSettle();
      expect(
        find.text('Showing all ${roster.length} students'),
        findsOneWidget,
      );

      AppAuth.signOut();
    },
  );

  testWidgets('saving attendance files a log grouped by teacher and subject', (
    tester,
  ) async {
    final store = AttendanceStore.instance;
    store.clearLogs();
    addTearDown(store.clearLogs);
    store.addStudent(
      name: 'Log Test One',
      institutionType: InstitutionType.school,
      groupName: 'Grade 8',
      subjectName: 'Mathematics',
    );
    store.addStudent(
      name: 'Log Test Two',
      institutionType: InstitutionType.school,
      groupName: 'Grade 8',
      subjectName: 'Mathematics',
    );
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

    final subjectPicker = find.byKey(
      const ValueKey('attendance-subject-Grade 8-'),
    );
    await tester.ensureVisible(subjectPicker);
    await tester.tap(subjectPicker);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('search-picker-field')),
      'math',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('search-picker-option-Mathematics')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Assign Teacher'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('instructor-name-field')),
      'Nimali Perera',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark all present'));
    await tester.pumpAndSettle();
    final saveButton = find.text('Save attendance');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(store.logs.length, 1);
    expect(store.logs.first.instructorName, 'Nimali Perera');
    expect(store.logs.first.subjectName, 'Mathematics');
    expect(store.logs.first.presentCount, 2);

    await tester.pumpWidget(MaterialApp(home: ReportsScreen(store: store)));
    await tester.pumpAndSettle();

    expect(find.text('Attendance log'), findsOneWidget);
    expect(find.text('1 saved'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report-log-teacher-Nimali Perera')),
      findsOneWidget,
    );
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('2 present · 0 late · 0 absent'), findsOneWidget);
    expect(find.byKey(const Key('report-log-empty')), findsNothing);
    expect(
      find.textContaining('2 student records across 1 teacher'),
      findsOneWidget,
    );

    AppAuth.signOut();
  });
}
