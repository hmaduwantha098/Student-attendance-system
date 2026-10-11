import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'about_screen.dart';
import 'account_store.dart';
import 'attendance_screen.dart';
import 'attendance_store.dart';
import 'categories_screen.dart';
import 'contact_screen.dart';
import 'dashboard_screen.dart';
import 'features_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'school_subject_catalog.dart';
import 'settings_screen.dart';
import 'students_screen.dart';
import 'universities_screen.dart';

export 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    AttendanceStore.instance.ensureLoaded(),
    AccountStore.instance.ensureLoaded(),
  ]);
  runApp(const StudentAttendanceApp());
}

class StudentAttendanceApp extends StatelessWidget {
  const StudentAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendify',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      initialRoute: AppAuth.isAuthenticated ? '/home' : '/login',
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/login';
        final protectedRoutes = {
          '/home',
          '/features',
          '/about',
          '/contact',
          '/dashboard',
          '/students',
          '/attendance',
          '/reports',
          '/profile',
          '/categories',
          '/settings',
          '/universities',
        };

        if (protectedRoutes.contains(name) && !AppAuth.isAuthenticated) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: '/login'),
            builder: (_) => const LoginScreen(),
          );
        }

        switch (name) {
          case '/login':
            if (AppAuth.isAuthenticated) {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/home'),
                builder: (_) => const HomePage(),
              );
            }
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomePage());
          case '/features':
            return MaterialPageRoute(builder: (_) => const FeaturesScreen());
          case '/about':
            return MaterialPageRoute(builder: (_) => const AboutScreen());
          case '/contact':
            return MaterialPageRoute(builder: (_) => const ContactScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/students':
            return MaterialPageRoute(builder: (_) => const StudentsScreen());
          case '/attendance':
            final arguments = settings.arguments;
            final institutionType =
                arguments is Map &&
                    arguments['institutionType'] is InstitutionType
                ? arguments['institutionType'] as InstitutionType
                : InstitutionType.school;
            final groupName =
                arguments is Map && arguments['groupName'] is String
                ? arguments['groupName'] as String
                : 'Grade 8';
            final universityName =
                arguments is Map && arguments['universityName'] is String
                ? arguments['universityName'] as String
                : 'University of Colombo';
            final facultyName =
                arguments is Map && arguments['facultyName'] is String
                ? arguments['facultyName'] as String
                : 'Faculty of Arts';
            final subjectName =
                arguments is Map && arguments['subjectName'] is String
                ? arguments['subjectName'] as String
                : allSubjectsOption;
            final schoolStream =
                arguments is Map && arguments['schoolStream'] is String
                ? arguments['schoolStream'] as String
                : '';
            return MaterialPageRoute(
              builder: (_) => AttendanceScreen(
                initialInstitutionType: institutionType,
                initialGroup: groupName,
                initialUniversityName: universityName,
                initialFacultyName: facultyName,
                initialSubjectName: subjectName,
                initialSchoolStream: schoolStream,
              ),
            );
          case '/reports':
            return MaterialPageRoute(builder: (_) => const ReportsScreen());
          case '/categories':
            return MaterialPageRoute(builder: (_) => const CategoriesScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/universities':
            return MaterialPageRoute(
              builder: (_) => const UniversitiesScreen(),
            );
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
      routes: {'/login': (context) => const LoginScreen()},
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavbar(context, isCompact),
                  _buildHeroSection(context, isCompact),
                  _buildFeaturesSection(context, isCompact),
                  _buildStatsSection(),
                  _buildFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context, bool isCompact) {
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 43,
          width: 43,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryBlue, darkBlue]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Attendify',
          style: GoogleFonts.inter(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
      ],
    );

    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (AppAuth.isAuthenticated)
          OutlinedButton.icon(
            onPressed: () => _logOut(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              'Log out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          )
        else
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Login',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );

    final navButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navItem(context, 'Home', true, '/home'),
        _navItem(context, 'Features', false, '/features'),
        _navItem(context, 'About', false, '/about'),
        _navItem(context, 'Contact', false, '/contact'),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 55,
        vertical: isCompact ? 12 : 0,
      ),
      height: isCompact ? null : 78,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: isCompact
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  logo,
                  const SizedBox(width: 12),
                  navButtons,
                  const SizedBox(width: 12),
                  actionButtons,
                ],
              ),
            )
          : Row(
              children: [
                logo,
                const Spacer(),
                navButtons,
                const SizedBox(width: 30),
                actionButtons,
              ],
            ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String title,
    bool active,
    String routeName,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: active
            ? null
            : () => Navigator.pushNamed(context, routeName),
        style: TextButton.styleFrom(
          foregroundColor: active ? primaryBlue : textGrey,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? primaryBlue : textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isCompact) {
    final heroContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 7,
                width: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SMART ATTENDANCE MANAGEMENT',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .6,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: isCompact ? 34 : 48,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
            children: const [
              TextSpan(text: 'Smart Attendance\n'),
              TextSpan(
                text: 'Made Simple.',
                style: TextStyle(color: primaryBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: isCompact ? double.infinity : 570,
          child: Text(
            'Manage student attendance faster and smarter. Track attendance, monitor student performance, and generate accurate reports from one powerful platform.',
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.7,
              color: textGrey,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              icon: const Icon(Icons.dashboard_rounded, size: 20),
              label: Text(
                'Open Dashboard',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 6,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/attendance'),
              icon: const Icon(Icons.fact_check_outlined, size: 20),
              label: Text(
                'Mark Attendance',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textDark,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/categories'),
              icon: const Icon(Icons.category_outlined, size: 20),
              label: Text(
                'Saved Categories',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textDark,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/universities'),
              icon: const Icon(Icons.account_balance_outlined, size: 20),
              label: Text(
                'Universities',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textDark,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: const Icon(Icons.settings_outlined, size: 20),
              label: Text(
                'Settings',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: textDark,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 38),
        Wrap(
          spacing: 25,
          runSpacing: 12,
          children: [
            _smallBenefit(Icons.check_circle_rounded, 'Easy to Use'),
            _smallBenefit(Icons.security_rounded, 'Secure'),
            _smallBenefit(Icons.analytics_rounded, 'Real-time Reports'),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 20 : 70,
        vertical: isCompact ? 40 : 75,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heroContent,
                const SizedBox(height: 32),
                _buildDashboardPreview(context),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 6, child: heroContent),
                const SizedBox(width: 50),
                Expanded(flex: 5, child: _buildDashboardPreview(context)),
              ],
            ),
    );
  }

  Widget _buildDashboardPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.notifications_none_rounded, color: textGrey),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Today\'s Overview',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _previewCard(
                    context,
                    'Students',
                    '1,248',
                    Icons.people_alt_rounded,
                    primaryBlue,
                    '/students',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _previewCard(
                    context,
                    'Present',
                    '1,086',
                    Icons.check_circle_rounded,
                    const Color(0xFF16A34A),
                    '/attendance',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _previewCard(
                    context,
                    'Absent',
                    '104',
                    Icons.cancel_rounded,
                    const Color(0xFFDC2626),
                    '/attendance',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _previewCard(
                    context,
                    'Attendance',
                    '87%',
                    Icons.analytics_rounded,
                    const Color(0xFFF59E0B),
                    '/reports',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 125,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Attendance',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _bar(55),
                        _bar(75),
                        _bar(65),
                        _bar(88),
                        _bar(78),
                        _bar(94),
                        _bar(85),
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

  Widget _previewCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String routeName,
  ) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, routeName),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              height: 31,
              width: 31,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 9, color: textGrey),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double height) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: height,
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.75),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
      ),
    );
  }

  Widget _smallBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF16A34A)),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isCompact) {
    final cards = [
      _featureCard(
        context,
        Icons.fact_check_rounded,
        'Smart Attendance',
        'Record and manage student attendance quickly and accurately.',
        '/attendance',
      ),
      _featureCard(
        context,
        Icons.people_alt_rounded,
        'Student Management',
        'Manage student profiles, classes and academic information.',
        '/students',
      ),
      _featureCard(
        context,
        Icons.bar_chart_rounded,
        'Reports & Analytics',
        'Generate detailed attendance reports and insights.',
        '/reports',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 20 : 70,
        vertical: 75,
      ),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Everything You Need',
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Powerful tools to make attendance management simple.',
            style: GoogleFonts.inter(fontSize: 14, color: textGrey),
          ),
          const SizedBox(height: 40),
          isCompact
              ? Column(
                  children: [
                    for (final card in cards) ...[
                      card,
                      const SizedBox(height: 20),
                    ],
                  ],
                )
              : Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i < cards.length - 1) const SizedBox(width: 20),
                    ],
                  ],
                ),
        ],
      ),
    );
  }

  Widget _featureCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String routeName,
  ) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, routeName),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryBlue, size: 24),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: primaryBlue, size: 20),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.6,
                color: textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stats = [
          _stat('1,248+', 'Students'),
          _stat('98%', 'Data Accuracy'),
          _stat('24/7', 'Availability'),
          _stat('100%', 'Secure'),
        ];

        if (constraints.maxWidth < 700) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            color: const Color(0xFF1E3A8A),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 28,
              runSpacing: 20,
              children: stats,
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 55),
          color: const Color(0xFF1E3A8A),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: stats,
          ),
        );
      },
    );
  }

  Widget _stat(String value, String title) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  void _logOut(BuildContext context) {
    AppAuth.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copyright = Text(
            '© 2026 Attendify',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
          );
          final description = Text(
            'Student Attendance Management System',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
          );

          if (constraints.maxWidth < 700) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                children: [copyright, const SizedBox(height: 10), description],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 30),
            child: Row(children: [copyright, const Spacer(), description]),
          );
        },
      ),
    );
  }
}
