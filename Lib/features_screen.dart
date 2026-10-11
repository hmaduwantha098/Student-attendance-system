import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_store.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color textGrey = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        'Fast attendance tracking',
        'Mark daily attendance in seconds with a clear, focused workflow.',
        Icons.fact_check_rounded,
        '/attendance',
      ),
      (
        'Student management',
        'Add students and keep their class information organized in one place.',
        Icons.people_alt_rounded,
        '/students',
      ),
      (
        'Actionable reports',
        'Review attendance trends and spot patterns with simple visual reports.',
        Icons.bar_chart_rounded,
        '/reports',
      ),
      (
        'Saved categories',
        'Every grade, subject, year, institution and course you added, in one searchable list.',
        Icons.category_rounded,
        '/categories',
      ),
      (
        'University directory',
        'All 19 state universities, SLIATE advanced technological institutes '
            'and Sri Lankan university colleges with their faculties and courses.',
        Icons.account_balance_rounded,
        '/universities',
      ),
      (
        'Account settings',
        'Create your profile and update the email address or password you use to sign in.',
        Icons.settings_rounded,
        '/settings',
      ),
      (
        'Secure access',
        'Keep attendance data inside a focused workspace for your school team.',
        Icons.security_rounded,
        '/profile',
      ),
    ];

    final store = AttendanceStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Features',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/about'),
            child: const Text('About'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/contact'),
            child: const Text('Contact'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final dateKey = store.todayKey;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Everything you need to stay on track',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Attendify keeps the daily attendance workflow simple for teachers and administrators.',
                style: GoogleFonts.inter(color: textGrey, height: 1.5),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/attendance'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickStat(
                          label: 'Marked',
                          value: '${store.markedCount(dateKey)}',
                        ),
                      ),
                      Expanded(
                        child: _QuickStat(
                          label: 'Present',
                          value:
                              '${store.countFor(dateKey, AttendanceStatus.present)}',
                        ),
                      ),
                      Expanded(
                        child: _QuickStat(
                          label: 'Absent',
                          value:
                              '${store.countFor(dateKey, AttendanceStatus.absent)}',
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Today\'s numbers update as you mark attendance.',
                style: GoogleFonts.inter(fontSize: 12, color: textGrey),
              ),
              const SizedBox(height: 24),
              for (final feature in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, feature.$4),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(feature.$3, color: primaryBlue, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feature.$1,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  feature.$2,
                                  style: GoogleFonts.inter(
                                    color: textGrey,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: textGrey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/dashboard'),
                      icon: const Icon(Icons.dashboard_rounded),
                      label: const Text('Dashboard'),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/about'),
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('About us'),
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/contact'),
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: const Text('Contact us'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}
