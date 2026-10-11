import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_store.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = AccountStore.instance;

    return AnimatedBuilder(
      animation: account,
      builder: (context, _) {
        final profile = account.profile;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Profile',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  profile.initials,
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      account.email,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ProfileItem(
                          'Role',
                          profile.isCreated && profile.role.isNotEmpty
                              ? profile.role
                              : 'Tap settings to create your profile',
                        ),
                        _ProfileItem(
                          'Institution',
                          profile.institution.isEmpty
                              ? 'Not set'
                              : profile.institution,
                        ),
                        _ProfileItem(
                          'Department',
                          profile.department.isEmpty
                              ? 'Not set'
                              : profile.department,
                        ),
                        _ProfileItem(
                          'Phone',
                          profile.phone.isEmpty ? 'Not set' : profile.phone,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('profile-settings-button'),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/settings'),
                            icon: const Icon(Icons.settings_rounded),
                            label: const Text('Account settings'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/students'),
                            icon: const Icon(Icons.people_alt_rounded),
                            label: const Text('View students'),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              AppAuth.signOut();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Log out',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
