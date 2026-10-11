import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_store.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AttendanceStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Attendify',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/features'),
            child: const Text('Features'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final dateKey = store.todayKey;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: Color(0xFF2563EB),
                      size: 42,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Attendance that gives teams time back',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Attendify brings daily check-ins, student records, and attendance insights into one calm workspace.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Live workspace stats',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Students',
                      value: '${store.students.length}',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Marked today',
                      value: '${store.markedCount(dateKey)}',
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Attendance',
                      value: '${store.attendanceRate(dateKey).round()}%',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Built for the school day',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'The app is designed around the moments that matter: taking attendance quickly, finding a student record, and understanding trends before they become problems.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Version 1.0.0',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/features'),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('Back to features'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/contact'),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Talk to our team'),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
