// lib/screens/stats_screen.dart
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../services/mood_store.dart';
import '../services/weather_service.dart';
import '../models/mood_entry.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({super.key});

  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage> {
  late DateTime _weekStart;
  late List<DateTime> _weekDays;

  Map<String, int>? _weatherCodes; // "YYYY-MM-DD" -> Open-Meteo weathercode

  @override
  void initState() {
    super.initState();
    _initWeek();
    _loadWeather();
  }

  void _initWeek() {
    final nowLocal = DateTime.now();
    _weekStart = _mondayOf(nowLocal);
    _weekDays = _daysOfWeek(_weekStart);
  }

  Future<void> _loadWeather() async {
    try {
      const gothenburg = LatLng(57.7089, 11.9746);
      final codes = await WeatherService.fetchDailyWeatherCodes(
        at: gothenburg,
        start: _weekStart,
        end: _weekStart.add(const Duration(days: 6)),
      );
      if (!mounted) return;
      setState(() => _weatherCodes = codes);
    } catch (e) {
      debugPrint('Fel vid väderhämtning: $e');
    }
  }

  DateTime _mondayOf(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.subtract(Duration(days: d.weekday - 1)); // 1=mån
  }

  List<DateTime> _daysOfWeek(DateTime monday) =>
      List.generate(7, (i) => monday.add(Duration(days: i)));

  String _dateKeyLocal(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final store = context.watch<MoodStore>();
    final entries = store.entries;

    final xLabels = _weekdayLabelsSv(_weekDays);

    // 1) Medelhumör per dag (null där det saknas)
    List<double?> moodSeriesNullable = [];
    final rawValuesThisWeek = <double>[];

    for (final d in _weekDays) {
      final todays = entries.where((e) => _sameLocalDay(_entryLocalDate(e), d));
      final todaysVals = todays.map((e) => _scoreFromEmoji(e.emoji)).toList();
      final avg = todaysVals.isEmpty
          ? null
          : todaysVals.reduce((a, b) => a + b) / todaysVals.length;
      moodSeriesNullable.add(avg);
      if (avg != null) rawValuesThisWeek.add(avg);
    }

    // ---------- DEMO-LINE (debug-only): fyll mån–tor om för få punkter ----------
    if (kDebugMode) {
      final nonNullCount = moodSeriesNullable.where((v) => v != null).length;
      if (nonNullCount < 2) {
        // behåll ev. befintliga värden, fyll luckor mån–tor med en snygg linje
        final demo = <double>[6.5, 5.5, 7.0, 6.0]; // justerbar smakprofil 🙂
        for (int i = 0; i < 4 && i < moodSeriesNullable.length; i++) {
          moodSeriesNullable[i] ??= demo[i];
        }
      }
    }
    // ---------------------------------------------------------------------------

    // 2) Auto-skala Y-axeln runt faktiska punkter vi kommer rita
    final plottedValues = moodSeriesNullable.whereType<double>().toList(
      growable: false,
    );

    double minY = 0, maxY = 10;
    if (plottedValues.isNotEmpty) {
      minY = plottedValues.reduce((a, b) => a < b ? a : b);
      maxY = plottedValues.reduce((a, b) => a > b ? a : b);
      if (minY == maxY) {
        minY = (minY - 0.8).clamp(0.0, 10.0);
        maxY = (maxY + 0.8).clamp(0.0, 10.0);
      } else {
        const pad = 0.7;
        minY = (minY - pad).clamp(0.0, 10.0);
        maxY = (maxY + pad).clamp(0.0, 10.0);
      }
    }

    // 3) Stats
    final allMoodValues = entries.map((e) => _scoreFromEmoji(e.emoji)).toList();
    final avgAll = allMoodValues.isEmpty
        ? 0.0
        : allMoodValues.reduce((a, b) => a + b) / allMoodValues.length;
    final mostCommonEmoji = _mostCommon(entries.map((e) => e.emoji));

    // 4) Väder-emoji-lista i samma ordning som x-axeln
    final weatherEmojis = _weatherCodes != null
        ? _weekDays.map((d) {
            final code = _weatherCodes![_dateKeyLocal(d)];
            return code != null ? _emojiForWeatherCode(code) : '·';
          }).toList()
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik'), centerTitle: true),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(_initWeek);
            await _loadWeather();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      icon: Icons.show_chart,
                      text: 'Denna vecka · Humör och väder',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: const [
                        _LegendDot(label: 'Humör', colorDot: null),
                        _LegendEmoji(emoji: '😔', label: 'Lågt'),
                        _LegendEmoji(emoji: '😐', label: 'Medel'),
                        _LegendEmoji(emoji: '😄', label: 'Högt'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 260,
                      child: _SingleLineChart(
                        xLabels: xLabels,
                        values: moodSeriesNullable,
                        color: cs.primary,
                        gridColor: theme.dividerColor.withValues(alpha: 0.35),
                        yMin: minY,
                        yMax: maxY,
                        yTickEmojis: const ['😔', '😐', '😄'],
                        weatherEmojis: weatherEmojis,
                      ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Veckovärden: ${moodSeriesNullable.map((v) => v?.toStringAsFixed(1) ?? "–").join("  ")}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: .7,
                      child: Text(
                        'Dra nedåt för att uppdatera humör och väder.',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _SummaryCard(
                    title: 'Snitt',
                    value: allMoodValues.isEmpty
                        ? '–'
                        : avgAll.toStringAsFixed(1),
                    icon: Icons.emoji_emotions,
                  ).expanded(),
                  const SizedBox(width: 10),
                  _SummaryCard(
                    title: 'Inlägg',
                    value: entries.length.toString(),
                    icon: Icons.edit_note,
                  ).expanded(),
                  const SizedBox(width: 10),
                  _SummaryCard(
                    title: 'Vanligast',
                    value: mostCommonEmoji ?? '–',
                    icon: Icons.mood,
                  ).expanded(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _emojiForWeatherCode(int code) {
    if (code == 0) return '☀️';
    if (code == 1) return '🌤️';
    if (code == 2 || code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫️';
    if (code == 51 || code == 53 || code == 55) return '🌦️';
    if (code == 61 || code == 63 || code == 65) return '🌧️';
    if (code == 66 || code == 67) return '🌧️❄️';
    if (code == 71 || code == 73 || code == 75 || code == 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌧️';
    if (code >= 95) return '⛈️';
    return '❓';
  }

  DateTime _entryLocalDate(MoodEntry e) {
    final dt = e.date;
    final local = dt.isUtc ? dt.toLocal() : dt;
    return DateTime(local.year, local.month, local.day);
  }

  bool _sameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _scoreFromEmoji(String e) {
    const map = <String, int>{
      '😭': 0,
      '😫': 1,
      '😢': 1,
      '😡': 1,
      '😠': 2,
      '☹️': 3,
      '🙁': 3,
      '😞': 3,
      '😟': 3,
      '😕': 4,
      '😔': 4,
      '😣': 4,
      '😤': 4,
      '😐': 5,
      '😶': 5,
      '🙂': 6,
      '😊': 7,
      '☺️': 7,
      '😄': 8,
      '😃': 9,
      '😁': 10,
      '🤩': 10,
      '😆': 9,
      '😂': 8,
    };
    return (map[e] ?? 5).toDouble();
  }

  List<String> _weekdayLabelsSv(List<DateTime> days) {
    const names = ['Mån', 'Tis', 'Ons', 'Tor', 'Fre', 'Lör', 'Sön'];
    return days.map((d) => names[d.weekday - 1]).toList();
  }

  T? _mostCommon<T>(Iterable<T> items) {
    final map = <T, int>{};
    for (final v in items) {
      map[v] = (map[v] ?? 0) + 1;
    }
    T? best;
    int bestCount = -1;
    map.forEach((k, c) {
      if (c > bestCount) {
        best = k;
        bestCount = c;
      }
    });
    return best;
  }
}

/* ----------------------------- UI ---------------------------- */

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: .2,
    );
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(text, style: style),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, this.colorDot});
  final String label;
  final Color? colorDot;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dotColor = colorDot ?? cs.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _LegendEmoji extends StatelessWidget {
  const _LegendEmoji({required this.emoji, required this.label});
  final String emoji;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: t.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: t.textTheme.bodySmall),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget expanded() => Expanded(child: this);
}

/* -------- Enkel linjegraf (luckor + auto-skala) -------- */

class _SingleLineChart extends StatelessWidget {
  const _SingleLineChart({
    required this.xLabels,
    required this.values,
    required this.color,
    required this.gridColor,
    required this.yTickEmojis,
    required this.weatherEmojis,
    required this.yMin,
    required this.yMax,
  });

  final List<String> xLabels;
  final List<double?> values;
  final Color color;
  final Color gridColor;
  final List<String> yTickEmojis;
  final List<String>? weatherEmojis;
  final double yMin;
  final double yMax;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SingleLineChartPainter(
        xLabels: xLabels,
        values: values,
        color: color,
        gridColor: gridColor,
        yTickEmojis: yTickEmojis,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        weatherEmojis: weatherEmojis,
        yMin: yMin,
        yMax: yMax,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SingleLineChartPainter extends CustomPainter {
  _SingleLineChartPainter({
    required this.xLabels,
    required this.values,
    required this.color,
    required this.gridColor,
    required this.yTickEmojis,
    required this.labelStyle,
    this.weatherEmojis,
    required this.yMin,
    required this.yMax,
  });

  final List<String>? weatherEmojis;
  final List<String> xLabels;
  final List<double?> values;
  final Color color;
  final Color gridColor;
  final List<String> yTickEmojis;
  final TextStyle? labelStyle;
  final double yMin;
  final double yMax;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const padding = EdgeInsets.fromLTRB(36, 16, 12, 42);
    final rect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Låg/medel/hög relativt yMin/yMax
    final yGuide = <double>[
      yMin + (yMax - yMin) * 0.25,
      yMin + (yMax - yMin) * 0.50,
      yMin + (yMax - yMin) * 0.75,
    ];
    for (final yv in yGuide) {
      final dy = _mapY(yv, rect);
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), gridPaint);
    }

    // Emoji på Y-axel
    final yEmojiPos = <double>[
      yMin + (yMax - yMin) * 0.20,
      yMin + (yMax - yMin) * 0.50,
      yMin + (yMax - yMin) * 0.80,
    ];
    for (int i = 0; i < yTickEmojis.length && i < yEmojiPos.length; i++) {
      _drawText(
        canvas,
        yTickEmojis[i],
        Offset(rect.left - 26, _mapY(yEmojiPos[i], rect) - 8),
        labelStyle,
      );
    }

    // X-etiketter + väder
    final stepX = rect.width / (xLabels.length - 1);
    for (int i = 0; i < xLabels.length; i++) {
      final dx = rect.left + stepX * i;
      _drawCenteredText(
        canvas,
        xLabels[i],
        Offset(dx, rect.bottom + 6),
        labelStyle,
      );
      if (weatherEmojis != null && i < weatherEmojis!.length) {
        _drawCenteredText(
          canvas,
          weatherEmojis![i],
          Offset(dx, rect.bottom + 22),
          labelStyle,
        );
      }
    }

    // Linje (bara där data finns)
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    Offset? prev;
    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) {
        prev = null;
        continue;
      }
      final x = rect.left + stepX * i;
      final y = _mapY(v, rect);
      final p = Offset(x, y);
      if (prev != null) canvas.drawLine(prev, p, paint);
      prev = p;
    }

    // Prickar
    final dotPaint = Paint()..color = color;
    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final x = rect.left + stepX * i;
      final y = _mapY(v, rect);
      canvas.drawCircle(Offset(x, y), 3.0, dotPaint);
    }
  }

  double _mapY(double v, Rect rect) {
    final clamped = v.clamp(yMin, yMax);
    return rect.bottom - (clamped - yMin) / (yMax - yMin) * rect.height;
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle? style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle? style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset(center.dx - tp.width / 2, center.dy);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SingleLineChartPainter oldDelegate) => true;
}
