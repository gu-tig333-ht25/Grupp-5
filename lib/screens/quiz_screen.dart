import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Varje fråga har en lista av svarsalternativ med poäng.
  final List<QuizQuestion> _questions = [
    QuizQuestion(
      text: 'Hur har din energinivå varit idag?',
      options: [
        QuizOption('Väldigt låg', 0),
        QuizOption('Lite låg', 1),
        QuizOption('Okej', 2),
        QuizOption('Ganska bra', 3),
        QuizOption('Toppen!', 4),
      ],
    ),
    QuizQuestion(
      text: 'Hur mycket oro/stress känner du just nu?',
      options: [
        QuizOption('Väldigt mycket', 0),
        QuizOption('Ganska mycket', 1),
        QuizOption('Lite', 2),
        QuizOption('Nästan inget', 3),
        QuizOption('Ingen alls', 4),
      ],
    ),
    QuizQuestion(
      text: 'Hur blev din sömn senaste natten?',
      options: [
        QuizOption('Mycket dålig', 0),
        QuizOption('Dålig', 1),
        QuizOption('Okej', 2),
        QuizOption('Bra', 3),
        QuizOption('Mycket bra', 4),
      ],
    ),
    QuizQuestion(
      text: 'Hur har dina sociala kontakter känts idag?',
      options: [
        QuizOption('Isolerad', 0),
        QuizOption('Lite ensam', 1),
        QuizOption('Neutralt', 2),
        QuizOption('Ganska bra', 3),
        QuizOption('Väldigt stödjande', 4),
      ],
    ),
    QuizQuestion(
      text: 'Hur snäll har du varit mot dig själv idag?',
      options: [
        QuizOption('Inte alls', 0),
        QuizOption('Lite', 1),
        QuizOption('Okej', 2),
        QuizOption('Ganska snäll', 3),
        QuizOption('Super-snäll', 4),
      ],
    ),
  ];

  // Håller valda svar (index per fråga)
  final Map<int, int> _answers = {};
  bool _showResult = false;
  late QuizResult _result;

  void _submit() {
    if (_answers.length != _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Svara på alla frågor först 😊')),
      );
      return;
    }
    final score = _answers.entries.fold<int>(
      0,
      (sum, e) => sum + _questions[e.key].options[e.value].score,
    );
    _result = _evaluate(score);
    setState(() => _showResult = true);
  }

  QuizResult _evaluate(int score) {
    // Maxpoäng: 5 frågor * 4 = 20
    if (score <= 6) {
      return QuizResult(
        title: 'Det är tufft just nu 💛',
        message:
            'Ta ett litet, snällt steg: drick ett glas vatten, 3 lugna andetag, '
            'och skriv en vänlig mening till dig själv. Om det känns mycket, '
            'hör gärna av dig till någon du litar på.',
        actions: const [
          '3 djupa andetag',
          'Väldigt kort promenad inomhus/ute',
          'Skriv ett snällt sms till dig själv',
        ],
      );
    } else if (score <= 13) {
      return QuizResult(
        title: 'Helt okej – bra jobbat ✨',
        message:
            'Du håller dig flytande. Välj en liten sak som kan ge +1 energi idag.',
        actions: const [
          '5 min frisk luft',
          'Lyssna på en låt du gillar',
          'Skicka ett “hej” till någon',
        ],
      );
    } else {
      return QuizResult(
        title: 'Starkt läge! 🌟',
        message:
            'Du tar hand om dig. Fira det – och fundera på vad som hjälpt idag '
            'så du kan göra mer av det imorgon.',
        actions: const [
          'Skriv ner 1 sak som funkat',
          'Dela något positivt med någon',
          'Planera en liten belöning',
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Snabbt välmående-quiz')),
      body: _showResult
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_result.title,
                            style: tt.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            )),
                        const SizedBox(height: 8),
                        Text(_result.message,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onPrimaryContainer,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Små förslag:',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 8),
                  ..._result.actions.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(a)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _answers.clear();
                        _showResult = false;
                      });
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Gör om quizzet'),
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length + 1,
              itemBuilder: (context, index) {
                if (index == _questions.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Text('Se resultat'),
                      ),
                    ),
                  );
                }
                final q = _questions[index];
                final selected = _answers[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.text,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 8),
                      ...List.generate(q.options.length, (i) {
                        final opt = q.options[i];
                        return RadioListTile<int>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(opt.label),
                          value: i,
                          groupValue: selected,
                          onChanged: (v) {
                            setState(() => _answers[index] = v!);
                          },
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class QuizQuestion {
  final String text;
  final List<QuizOption> options;
  QuizQuestion({required this.text, required this.options});
}

class QuizOption {
  final String label;
  final int score;
  QuizOption(this.label, this.score);
}

class QuizResult {
  final String title;
  final String message;
  final List<String> actions;
  const QuizResult({
    required this.title,
    required this.message,
    required this.actions,
  });
}
