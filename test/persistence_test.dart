import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_attendance_system/account_store.dart';
import 'package:student_attendance_system/attendance_store.dart';
import 'package:student_attendance_system/dashboard_screen.dart';

Future<void> flushPersistence() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('attendance data survives a restart via shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AttendanceStore();
    store.addStudent(
      name: 'Persist Student',
      institutionType: InstitutionType.school,
      groupName: 'Grade 8',
      subjectName: 'Mathematics',
    );
    final added = store.students.last;
    final dateKey = AttendanceStore.keyFor(DateTime.now());
    store.setStatus(dateKey, added.id, AttendanceStatus.present);
    store.setInstructor(
      institutionType: InstitutionType.school,
      groupName: 'Grade 8',
      subjectName: 'Mathematics',
      name: 'Ms. Perera',
    );
    store.recordAttendanceLog(
      dateKey: dateKey,
      institutionType: InstitutionType.school,
      groupName: 'Grade 8',
      subjectName: 'Mathematics',
      instructorName: 'Ms. Perera',
      studentIds: [added.id],
    );
    store.addSchoolGrade('Grade 99');
    store.renameSchoolGrade('Grade 8', 'Form 8');
    await flushPersistence();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('attendance_store_v1');
    expect(raw, isNotNull);
    expect(raw, contains('Persist Student'));

    final restarted = AttendanceStore();
    await restarted.ensureLoaded();
    expect(
      restarted.students.map((student) => student.name),
      contains('Persist Student'),
    );
    expect(restarted.statusFor(dateKey, added.id), AttendanceStatus.present);
    expect(restarted.logs, hasLength(1));
    expect(restarted.logs.first.instructorName, 'Ms. Perera');
    expect(restarted.customSchoolGrades, contains('Grade 99'));
    expect(restarted.schoolGradeOptions, contains('Form 8'));
    expect(
      restarted.instructorFor(
        institutionType: InstitutionType.school,
        groupName: 'Grade 8',
        subjectName: 'Mathematics',
      ),
      'Ms. Perera',
    );
    expect(restarted.schoolGradeOptions, isNot(contains('Grade 8')));
  });

  test('account password is stored hashed, not in plaintext', () async {
    SharedPreferences.setMockInitialValues({});
    final account = AccountStore();
    expect(
      account.changePassword(
        currentPassword: 'secure123',
        newPassword: 'newpass456',
        confirmPassword: 'newpass456',
      ),
      isNull,
    );
    await flushPersistence();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('account_store_v1');
    expect(raw, isNotNull);
    expect(raw, isNot(contains('secure123')));
    expect(raw, isNot(contains('newpass456')));
    expect(raw, contains('passwordHash'));

    final restarted = AccountStore();
    await restarted.ensureLoaded();
    expect(restarted.email, AccountStore.defaultEmail);
    expect(
      restarted.validateCredentials(AccountStore.defaultEmail, 'newpass456'),
      isTrue,
    );
    expect(
      restarted.validateCredentials(AccountStore.defaultEmail, 'secure123'),
      isFalse,
    );
  });

  test('profile and email changes persist across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final account = AccountStore();
    account.saveProfile(
      const UserProfile(
        fullName: 'Nimali Perera',
        role: 'Lecturer',
        institution: 'ATI Colombo',
        phone: '0771234567',
      ),
    );
    account.changeEmail(
      currentPassword: 'secure123',
      newEmail: 'nimali@attendify.com',
    );
    await flushPersistence();

    final restarted = AccountStore();
    await restarted.ensureLoaded();
    expect(restarted.email, 'nimali@attendify.com');
    expect(restarted.profile.fullName, 'Nimali Perera');
    expect(restarted.profile.role, 'Lecturer');
    expect(restarted.profile.institution, 'ATI Colombo');
    expect(restarted.profile.phone, '0771234567');
    expect(restarted.profile.displayName, 'Nimali Perera');
  });

  test('password hashes are salted so equal passwords differ', () {
    const firstSalt = 'firstSalt';
    const secondSalt = 'secondSalt';
    final first = AccountStore.hashPassword('hunter2', firstSalt);
    final second = AccountStore.hashPassword('hunter2', secondSalt);
    expect(first, isNot(second));
    expect(
      AccountStore.hashPassword('hunter2', firstSalt),
      first,
      reason: 'hashing the same password with the same salt is stable',
    );
  });

  test(
    'default credential flag clears once the account is customized',
    () async {
      SharedPreferences.setMockInitialValues({});
      final account = AccountStore();
      expect(account.usesDefaultCredentials, isTrue);

      account.changePassword(
        currentPassword: 'secure123',
        newPassword: 'ownpassword1',
        confirmPassword: 'ownpassword1',
      );
      expect(account.usesDefaultCredentials, isFalse);
      await flushPersistence();

      final restarted = AccountStore();
      await restarted.ensureLoaded();
      expect(restarted.usesDefaultCredentials, isFalse);
    },
  );

  testWidgets('dashboard warns until the default sign-in details are changed', (
    tester,
  ) async {
    AccountStore.instance.resetToDefaults();
    addTearDown(AccountStore.instance.resetToDefaults);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: DashboardScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-security-banner')), findsOneWidget);

    AccountStore.instance.changePassword(
      currentPassword: 'secure123',
      newPassword: 'ownpassword1',
      confirmPassword: 'ownpassword1',
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: DashboardScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-security-banner')), findsNothing);
  });
}
