import 'package:flutter/foundation.dart';

class ContactMessage {
  const ContactMessage({
    required this.name,
    required this.email,
    required this.message,
    required this.sentAt,
  });

  final String name;
  final String email;
  final String message;
  final DateTime sentAt;
}

class ContactStore extends ChangeNotifier {
  ContactStore();

  static final ContactStore instance = ContactStore._();

  ContactStore._();

  final List<ContactMessage> _messages = [];

  List<ContactMessage> get messages => List.unmodifiable(_messages);

  bool get isEmpty => _messages.isEmpty;

  bool send({
    required String name,
    required String email,
    required String message,
  }) {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedMessage = message.trim();

    if (trimmedName.isEmpty || trimmedEmail.isEmpty || trimmedMessage.isEmpty) {
      return false;
    }

    _messages.insert(
      0,
      ContactMessage(
        name: trimmedName,
        email: trimmedEmail,
        message: trimmedMessage,
        sentAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  void removeAt(int index) {
    if (index < 0 || index >= _messages.length) return;
    _messages.removeAt(index);
    notifyListeners();
  }

  void clear() {
    if (_messages.isEmpty) return;
    _messages.clear();
    notifyListeners();
  }
}
