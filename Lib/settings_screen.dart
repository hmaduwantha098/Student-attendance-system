import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_store.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openProfileEditor(
    BuildContext context,
    AccountStore account,
  ) async {
    final profile = await showDialog<UserProfile>(
      context: context,
      builder: (context) => ProfileEditorDialog(profile: account.profile),
    );
    if (profile == null || !context.mounted) return;
    account.saveProfile(profile);
    _showMessage(context, 'Profile saved for ${profile.displayName}.');
  }

  Future<void> _openEmailEditor(
    BuildContext context,
    AccountStore account,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => const ChangeEmailDialog(),
    );
    if (updated != true || !context.mounted) return;
    _showMessage(context, 'Email address updated to ${account.email}.');
  }

  Future<void> _openPasswordEditor(
    BuildContext context,
    AccountStore account,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
    if (updated != true || !context.mounted) return;
    _showMessage(context, 'Password updated. Use it the next time you log in.');
  }

  @override
  Widget build(BuildContext context) {
    final account = AccountStore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: AnimatedBuilder(
        animation: account,
        builder: (context, _) {
          final profile = account.profile;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ProfileCard(
                profile: profile,
                email: account.email,
                onEdit: () => _openProfileEditor(context, account),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Your profile',
                icon: Icons.badge_outlined,
                children: [
                  _DetailRow(label: 'Email', value: account.email),
                  _DetailRow(label: 'Full name', value: profile.displayName),
                  _DetailRow(
                    label: 'Role',
                    value: profile.role.isEmpty ? 'Not set' : profile.role,
                  ),
                  _DetailRow(
                    label: 'Institution',
                    value: profile.institution.isEmpty
                        ? 'Not set'
                        : profile.institution,
                  ),
                  _DetailRow(
                    label: 'Department',
                    value: profile.department.isEmpty
                        ? 'Not set'
                        : profile.department,
                  ),
                  _DetailRow(
                    label: 'Phone',
                    value: profile.phone.isEmpty ? 'Not set' : profile.phone,
                  ),
                  _DetailRow(
                    label: 'Employee ID',
                    value: profile.employeeId.isEmpty
                        ? 'Not set'
                        : profile.employeeId,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Login details',
                icon: Icons.lock_outline_rounded,
                children: [
                  Text(
                    'Keep your sign-in details up to date. Changing them does not '
                    'remove anything from your attendance records.',
                    style: GoogleFonts.inter(color: textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('settings-email-open'),
                      onPressed: () => _openEmailEditor(context, account),
                      icon: const Icon(Icons.alternate_email_rounded),
                      label: const Text('Change email address'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('settings-password-open'),
                      onPressed: () => _openPasswordEditor(context, account),
                      icon: const Icon(Icons.password_rounded),
                      label: const Text('Change password'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Profiles and account details are kept on this device only.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: textGrey, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.email,
    required this.onEdit,
  });

  final UserProfile profile;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const textDark = Color(0xFF0F172A);
    const textGrey = Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  profile.initials,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
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
                      key: const Key('settings-profile-name'),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: GoogleFonts.inter(color: textGrey)),
                    if (profile.role.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile.role,
                          key: const Key('settings-profile-role'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('settings-profile-open'),
              onPressed: onEdit,
              icon: Icon(
                profile.isCreated
                    ? Icons.edit_outlined
                    : Icons.person_add_alt_1_rounded,
              ),
              label: Text(
                profile.isCreated ? 'Edit profile' : 'Create profile',
              ),
            ),
          ),
          if (!profile.isCreated) ...[
            const SizedBox(height: 10),
            Text(
              'Add your name, role and contact details so attendance records '
              'are linked to the right person.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: textGrey,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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

class ProfileEditorDialog extends StatefulWidget {
  const ProfileEditorDialog({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends State<ProfileEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.profile.fullName,
  );
  late final TextEditingController _roleController = TextEditingController(
    text: widget.profile.role,
  );
  late final TextEditingController _institutionController =
      TextEditingController(text: widget.profile.institution);
  late final TextEditingController _departmentController =
      TextEditingController(text: widget.profile.department);
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.profile.phone,
  );
  late final TextEditingController _employeeIdController =
      TextEditingController(text: widget.profile.employeeId);

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _institutionController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      widget.profile.copyWith(
        fullName: _nameController.text.trim(),
        role: _roleController.text.trim(),
        institution: _institutionController.text.trim(),
        department: _departmentController.text.trim(),
        phone: _phoneController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.profile.isCreated ? 'Edit profile' : 'Create profile'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('settings-profile-name-field'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    helperText: 'Required',
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Enter your full name';
                    if (name.length < 2) return 'Enter at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('settings-profile-role-field'),
                  controller: _roleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Role / designation',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('settings-profile-institution-field'),
                  controller: _institutionController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Institution'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('settings-profile-department-field'),
                  controller: _departmentController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('settings-profile-phone-field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (value) => UserProfile.isValidPhone(value ?? '')
                      ? null
                      : 'Enter a valid phone number',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('settings-profile-employee-field'),
                  controller: _employeeIdController,
                  decoration: const InputDecoration(labelText: 'Employee ID'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('settings-profile-save'),
          onPressed: _save,
          child: const Text('Save profile'),
        ),
      ],
    );
  }
}

class ChangeEmailDialog extends StatefulWidget {
  const ChangeEmailDialog({super.key});

  @override
  State<ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<ChangeEmailDialog> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newEmailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newEmailController.dispose();
    _confirmEmailController.dispose();
    super.dispose();
  }

  void _save() {
    final error = AppAuth.changeEmail(
      currentPassword: _currentPasswordController.text,
      newEmail: _newEmailController.text,
      confirmEmail: _confirmEmailController.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change email address'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                key: const Key('settings-email-error'),
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              key: const Key('settings-email-current-password'),
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('settings-email-field'),
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'New email address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmEmailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Confirm new email'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('settings-email-save'),
          onPressed: _save,
          child: const Text('Update email'),
        ),
      ],
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _save() {
    final error = AppAuth.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                key: const Key('settings-password-error'),
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              key: const Key('settings-password-current'),
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('settings-password-field'),
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                helperText: 'At least 6 characters',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('settings-password-confirm'),
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('settings-password-save'),
          onPressed: _save,
          child: const Text('Update password'),
        ),
      ],
    );
  }
}
