import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  /// key: userId (t.ex. 'alex', 'maya'), value: profil-data inkl. 'email'
  final Map<String, Map<String, dynamic>> profiles;

  const LoginPage({super.key, required this.profiles});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ange e-post';
    // En enkel e-postkontroll räcker här
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
      return 'Ogiltig e-postadress';
    }
    return null;
  }

  /// Försök logga in genom att matcha e-post mot profilerna.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final emailInput = _emailCtrl.text.trim().toLowerCase();

    // Leta upp userId som har denna e-post
    String? matchedUserId;
    widget.profiles.forEach((userId, data) {
      final mail = (data['email'] ?? '').toString().toLowerCase();
      if (mail == emailInput) matchedUserId = userId;
    });

    await Future.delayed(const Duration(milliseconds: 200)); // liten UX-delay

    if (mounted) {
      if (matchedUserId != null) {
        Navigator.pop(context, matchedUserId); // returnera userId till föregående sida
      } else {
        setState(() {
          _submitting = false;
          _errorText = 'Hittade inget konto med den e-postadressen';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Logga in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('Ange e-post för att logga in på ditt konto',
                    style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-post',
                      hintText: 't.ex. alex@example.com',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateEmail,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_errorText!, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Logga in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
