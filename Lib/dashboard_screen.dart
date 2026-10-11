import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_store.dart';
import 'attendance_store.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF1E3A8A);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final store = AttendanceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final dateKey = store.todayKey;
        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? 'Good morning'
            : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
        final adminName =
            AppAuth.authenticatedEmail?.split('@').first ?? 'Admin';
        final metrics = [
          _MetricCard(
            'Students',
            '${store.students.length}',
            Icons.people_alt_rounded,
            primaryBlue,
          ),
          _MetricCard(
            'Present',
            '${store.attendedCount(dateKey)}',
            Icons.check_circle_rounded,
            const Color(0xFF16A34A),
          ),
          _MetricCard(
            'Absent',
            '${store.countFor(dateKey, AttendanceStatus.absent)}',
            Icons.cancel_rounded,
            const Color(0xFFDC2626),
          ),
          _MetricCard(
            'Attendance',
            '${store.attendanceRate(dateKey).round()}%',
            Icons.analytics_rounded,
            const Color(0xFFF59E0B),
          ),
        ];

        final navItems = [
          _NavCard(
            'Students',
            'Manage profiles',
            Icons.people_alt_rounded,
            '/students',
          ),
          _NavCard(
            'Attendance',
            'Track daily check-ins',
            Icons.fact_check_rounded,
            '/attendance',
          ),
          _NavCard(
            'Reports',
            'Review insights',
            Icons.bar_chart_rounded,
            '/reports',
          ),
          _NavCard(
            'Profile',
            'Manage settings',
            Icons.account_circle_rounded,
            '/profile',
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Dashboard',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                icon: const Icon(Icons.notifications_none_rounded),
                color: textDark,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, $adminName',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here is your attendance summary for today.',
                    style: GoogleFonts.inter(fontSize: 14, color: textGrey),
                  ),
                  if (AccountStore.instance.usesDefaultCredentials) ...[
                    const SizedBox(height: 14),
                    Container(
                      key: const Key('dashboard-security-banner'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You are still using the default sign-in '
                              'details. Set your own email and password to '
                              'protect your records.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF92400E),
                                height: 1.4,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/settings'),
                            child: Text(
                              'Set up',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    crossAxisCount: 2,
                    childAspectRatio: 1.65,
                    physics: const NeverScrollableScrollPhysics(),
                    children: metrics,
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Attendance',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 120,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              _ChartBar(45),
                              _ChartBar(65),
                              _ChartBar(55),
                              _ChartBar(78),
                              _ChartBar(70),
                              _ChartBar(92),
                              _ChartBar(88),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Quick access',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    crossAxisCount: 2,
                    childAspectRatio: 1.9,
                    physics: const NeverScrollableScrollPhysics(),
                    children: navItems,
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/attendance'),
            backgroundColor: primaryBlue,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Mark attendance',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.value, this.icon, this.color);

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard(this.title, this.subtitle, this.icon, this.routeName);

  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, routeName),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
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

class _ChartBar extends StatelessWidget {
  const _ChartBar(this.value);

  final double value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: value / 100,
            widthFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
