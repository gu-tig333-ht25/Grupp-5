import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/local_profiles.dart';
import '../services/select_profile.dart';
import '../services/mood_store.dart';

// 👇 Ny import för e-post-inloggning
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback onProfileChanged;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onProfileChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final store = LocalProfiles();
  String? currentUserId;
  Map<String, Map<String, dynamic>> profiles = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await store.seedIfNeeded();
    final all = await store.getAllProfiles();
    final uid = await store.getCurrentUserId();
    setState(() {
      profiles = all;
      currentUserId = uid;
    });
  }

  Map<String, dynamic>? get currentProfile =>
      currentUserId == null ? null : profiles[currentUserId];

  /// 🔁 Byt användare – visar lista (som tidigare)
  Future<void> _chooseAccount() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SelectProfilePage(
          profiles: profiles,
          currentUserId: currentUserId,
        ),
      ),
    );

    if (selected != null) {
      await store.setCurrentUserId(selected);
      final all = await store.getAllProfiles();

      setState(() {
        profiles = all;
        currentUserId = selected;
      });

      await context.read<MoodStore>().switchUser(selected);
      widget.onProfileChanged();
    }
  }

  /// 🚪 Logga ut -> gå till e-post-login
  Future<void> _logout() async {
    await store.setCurrentUserId(null);
    await context.read<MoodStore>().clear();

    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LoginPage(profiles: profiles),
      ),
    );

    if (selected != null) {
      await store.setCurrentUserId(selected);
      final all = await store.getAllProfiles();
      setState(() {
        profiles = all;
        currentUserId = selected;
      });
      await context.read<MoodStore>().switchUser(selected);
      widget.onProfileChanged();
    } else {
      // backade från login – visa "Ingen profil vald"
      setState(() {
        currentUserId = null;
      });
    }
  }

  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Om MoodMap'),
        content: const Text(
          'MoodMap hjälper dig att reflektera över hur plats och miljö påverkar ditt välmående. '
          'Genom att logga ditt humör på olika platser får du en personlig karta över ditt mående '
          'och kan se mönster över tid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stäng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cp = currentProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        elevation: 0,
      ),
      body: profiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _chooseAccount,
                          icon: const Icon(Icons.switch_account),
                          label: const Text('Byt konto'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logga ut'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (cp != null) ...[
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueAccent.shade100,
                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      cp['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(cp['email'] ?? '', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 24),
                  ] else ...[
                    const Text('Ingen profil vald'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _logout,
                      child: const Text('Logga in'),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Inställningar',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.wb_sunny_outlined, size: 26),
                              Switch(
                                value: widget.isDarkMode,
                                activeThumbColor: Colors.deepPurpleAccent,
                                inactiveThumbColor: Colors.amber,
                                onChanged: widget.onThemeChanged,
                              ),
                              const Icon(Icons.nightlight_outlined, size: 26),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showAppInfo(context),
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.deepPurpleAccent, size: 26),
                                SizedBox(width: 8),
                                Text('Information'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SupportHelpCard(),
                ],
              ),
            ),
    );
  }
}

// ---------- Hjälpkort för stöd ----------
class SupportHelpCard extends StatelessWidget {
  const SupportHelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget item(String title, String number) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _confirmCall(context, title, number),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 4),
                color: Colors.black.withOpacity(0.06),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(number,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.lightBlue.shade50,
            Colors.cyan.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.07),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stöd för mental hälsa',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Om du är i kris eller behöver stöd finns dessa resurser tillgängliga dygnet runt:',
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          item('Självmordslinjen', '90101'),
          item('Mind', '020-850 600'),
          item('BRIS', '116 111'),
        ],
      ),
    );
  }

  Future<void> _confirmCall(
      BuildContext context, String title, String number) async {
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ring $title?'),
        content: Text(number),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ring'),
          ),
        ],
      ),
    );

    if (shouldCall == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ringer $number... (simulerat)')),
      );
    }
  }
}
