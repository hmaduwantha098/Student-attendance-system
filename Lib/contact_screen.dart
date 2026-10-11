import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'contact_store.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final sent = ContactStore.instance.send(
      name: _nameController.text,
      email: _emailController.text,
      message: _messageController.text,
    );

    if (!sent) return;

    FocusScope.of(context).unfocus();
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    _formKey.currentState?.reset();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks. Your message has been sent.')),
    );
  }

  Future<void> _confirmClear() async {
    final store = ContactStore.instance;
    if (store.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all messages?'),
        content: const Text('This removes every message saved on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    store.clear();
  }

  @override
  Widget build(BuildContext context) {
    final store = ContactStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete all messages',
            onPressed: store.isEmpty ? null : _confirmClear,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/about'),
            child: const Text('About'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  "Let's talk",
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Have a question about Attendify? Send a message to our team.',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('contact-name-field'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('contact-email-field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('contact-message-field'),
                  controller: _messageController,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a message'
                      : null,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('contact-submit'),
                  onPressed: _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send message'),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Text(
                      'Sent messages',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${store.messages.length}',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (store.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'No messages yet. Messages you send appear here.',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    ),
                  )
                else
                  for (int i = 0; i < store.messages.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey('contact-message-$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => store.removeAt(i),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      store.messages[i].name,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    store.messages[i].sentAt
                                        .toIso8601String()
                                        .split('T')
                                        .first,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                store.messages[i].email,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                store.messages[i].message,
                                style: GoogleFonts.inter(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
