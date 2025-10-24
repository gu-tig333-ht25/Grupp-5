import 'package:flutter/material.dart';

class SelectProfilePage extends StatefulWidget {
  final Map<String, Map<String, dynamic>> profiles;
  final String? currentUserId;
  const SelectProfilePage({
    super.key,
    required this.profiles,
    required this.currentUserId,
  });

  @override
  State<SelectProfilePage> createState() => _SelectProfilePageState();
}

class _SelectProfilePageState extends State<SelectProfilePage> {
  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.currentUserId ?? 'alex';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget tile(String id) {
      final p = widget.profiles[id]!;
      final isSelected = selected == id;
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => selected = id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] ?? '',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(p['email'] ?? '',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey[700])),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Välj profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            tile('alex'),
            const SizedBox(height: 12),
            tile('maya'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.login),
                label: Text('Fortsätt som ${selected == 'maya' ? 'Maya' : 'Alex'}'),
                onPressed: selected == null
                    ? null
                    : () => Navigator.pop(context, selected),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Avbryt'),
            ),
          ],
        ),
      ),
    );
  }
}