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
  Map<DateTime, int>? _weatherCodes;

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

      setState(() {
        _weatherCodes = {
          for (final entry in codes.entries) DateTime.parse(entry.key): entry.value
        };
      });
    } catch (e) {
      debugPrint('Fel vid väderhämtning: $e');
    }
  }

  DateTime _mondayOf(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  List<DateTime> _daysOfWeek(DateTime monday) =>
      List.generate(7, (i) => monday.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final store = context.watch<MoodStore>();
    final entries = store.entries;

    final moodSeriesNullable = <double?>[];
    final xLabels = _weekdayLabelsSv(_weekDays);

    for (final d in _weekDays) {
      final todays = entries.where((e) => _sameLocalDay(_entryLocalDate(e), d)).toList();
      final moodVals = todays.map((e) => _scoreFromEmoji(e.emoji)).toList();
      final avgMood =
          moodVals.isEmpty ? null : moodVals.reduce((a, b) => a + b) / moodVals.length;
      moodSeriesNullable.add(avgMood);
    }

    final moodSeries = _fillGaps(moodSeriesNullable, 5.0);

    final allMoodValues = entries.map((e) => _scoreFromEmoji(e.emoji)).toList();
    final avgAll = allMoodValues.isEmpty
        ? 0.0
        : allMoodValues.reduce((a, b) => a + b) / allMoodValues.length;
    final mostCommonEmoji = _mostCommon(entries.map((e) => e.emoji));

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik'), centerTitle: true),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _initWeek();
            });
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
                        values: moodSeries,
                        color: cs.primary,
                        gridColor: theme.dividerColor.withOpacity(.35),
                        yTickEmojis: const ['😔', '😐', '😄'],
                        yTickValues: const [3.0, 5.0, 8.0],
                        weatherEmojis: _weatherCodes != null
                            ? _weekDays.map((d) {
                                final code = _weatherCodes![d];
                                return code != null ? _emojiForWeatherCode(code) : '–';
                              }).toList()
                            : null,
                      ),
                    ),
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
                    value: allMoodValues.isEmpty ? '–' : avgAll.toStringAsFixed(1),
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
    const ordered = [
      "😭", "😫", "😢", "☹️", "🙁", "😐", "🙂", "😊", "😄", "😃", "😁",
    ];
    final i = ordered.indexOf(e);
    return i < 0 ? 5.0 : i.toDouble();
  }

  List<double> _fillGaps(List<double?> src, double fallback) {
    if (src.isEmpty) return [];
    final out = List<double?>.from(src);
    double last = src.firstWhere((e) => e != null, orElse: () => fallback) ?? fallback;
    for (int i = 0; i < out.length; i++) {
      out[i] ??= last;
      last = out[i]!;
    }
    for (int i = out.length - 2; i >= 0; i--) {
      if (src[i] == null) out[i] = out[i + 1];
    }
    return out.cast<double>();
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
        border: Border.all(color: cs.outlineVariant.withOpacity(.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
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
        border: Border.all(color: cs.outlineVariant.withOpacity(.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
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

/* -------- Enkel linjegraf -------- */

class _SingleLineChart extends StatelessWidget {
  const _SingleLineChart({
    required this.xLabels,
    required this.values,
    required this.color,
    required this.gridColor,
    required this.yTickEmojis,
    required this.yTickValues,
    this.weatherEmojis,
  });

  final List<String> xLabels;
  final List<double> values;
  final Color color;
  final Color gridColor;
  final List<String> yTickEmojis;
  final List<double> yTickValues;
  final List<String>? weatherEmojis;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SingleLineChartPainter(
        xLabels: xLabels,
        values: values,
        color: color,
        gridColor: gridColor,
        yTickEmojis: yTickEmojis,
        yTickValues: yTickValues,
        labelStyle: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(fontWeight: FontWeight.w600),
        weatherEmojis: weatherEmojis,
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
    required this.yTickValues,
    required this.labelStyle,
    this.weatherEmojis,
  });

  final List<String>? weatherEmojis;
  final List<String> xLabels;
  final List<double> values;
  final Color color;
  final Color gridColor;
  final List<String> yTickEmojis;
  final List<double> yTickValues;
  final TextStyle? labelStyle;

  static const double _minY = 0.0;
  static const double _maxY = 10.0;

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

    for (final yv in yTickValues) {
      final dy = _mapY(yv, rect);
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), gridPaint);
    }

    for (int i = 0; i < yTickEmojis.length && i < yTickValues.length; i++) {
      final emoji = yTickEmojis[i];
      final dy = _mapY(yTickValues[i], rect);
      _drawText(canvas, emoji, Offset(rect.left - 26, dy - 8), labelStyle);
    }

    // Center labels and weather icons
    final stepX = rect.width / (xLabels.length - 1);
    for (int i = 0; i < xLabels.length; i++) {
      final dx = rect.left + stepX * i;

      // Weekday
      _drawCenteredText(canvas, xLabels[i], Offset(dx, rect.bottom + 6), labelStyle);

      // Weather emoji below the weekday
      if (weatherEmojis != null && i < weatherEmojis!.length) {
        _drawCenteredText(canvas, weatherEmojis![i], Offset(dx, rect.bottom + 22), labelStyle);
      }
    }

    // Draw line
    final pts = List<Offset>.generate(values.length, (i) {
      final x = rect.left + stepX * i;
      final y = _mapY(values[i], rect);
      return Offset(x, y);
    });

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    for (int i = 1; i < pts.length; i++) {
      canvas.drawLine(pts[i - 1], pts[i], paint);
    }

    final dotPaint = Paint()..color = color;
    for (final p in pts) {
      canvas.drawCircle(p, 3.0, dotPaint);
    }
  }

  // Helper methods for text and positioning
  double _mapY(double v, Rect rect) {
    final clamped = v.clamp(_minY, _maxY);
    return rect.bottom - (clamped - _minY) / (_maxY - _minY) * rect.height;
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle? style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawCenteredText(Canvas canvas, String text, Offset center, TextStyle? style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
            textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    // Center the text horizontally around the X position (dx)
    final offset = Offset(center.dx - tp.width / 2, center.dy);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SingleLineChartPainter oldDelegate) => true;
}