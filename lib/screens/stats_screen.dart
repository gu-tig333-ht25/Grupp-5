// lib/screens/statistik.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../services/mood_store.dart';
import '../models/mood_entry.dart';
import '../services/weather_service.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({super.key});

  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage> {
  static const LatLng _fallback = LatLng(57.7089, 11.9746); // Göteborg

  late List<DateTime> _weekDays;          // Mån..Sön (denna vecka)
  Map<String, int> _dailyCodes = {};      // 'YYYY-MM-DD' -> weather_code
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _weekDays = _currentWeekDays();
    _loadWeekWeather();
  }

  List<DateTime> _currentWeekDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1)); // 1 = måndag
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  Future<void> _loadWeekWeather() async {
    try {
      // Försök använda senaste inläggets position (om någon); annars fallback
      final entries = context.read<MoodStore>().entries;
      LatLng at = _fallback;
      if (entries.isNotEmpty) {
        final last = entries.last;
        at = LatLng(last.position.latitude, last.position.longitude);
      }

      final start = _weekDays.first;
      final end = _weekDays.last;

      final codes = await WeatherService.fetchDailyWeatherCodes(
        at: at,
        start: start,
        end: end,
      );

      if (!mounted) return;
      setState(() {
        _dailyCodes = codes;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final store = context.watch<MoodStore>();
    final entries = store.entries;

    // --- Bygg serier ---
    final moodSeriesNullable = <double?>[];
    final weatherSeries = <double>[];
    final xLabels = _weekdayLabelsSv(_weekDays);
    final xWeatherEmojis = <String>[]; // ☀️/☁️/🌧️

    for (final d in _weekDays) {
      final todays = entries.where((e) => _isSameDay(e.date, d)).toList();

      // Humör från loggar (emoji -> 0..10), medel per dag
      final moodVals = todays.map((e) => _scoreFromEmoji(e.emoji)).toList();
      final avgMood = moodVals.isEmpty
          ? null
          : moodVals.reduce((a, b) => a + b) / moodVals.length;
      moodSeriesNullable.add(avgMood);

      // Väder från Open-Meteo (dagens kod → score + emoji)
      final key = _dateKey(d);
      final code = _dailyCodes[key]; // kan vara null om ej hunnit laddas
      final wScore = code == null ? 5.0 : _weatherCodeToScore(code);
      weatherSeries.add(wScore);
      xWeatherEmojis.add(code == null ? '' : _weatherEmojiFromCode(code));
    }

    final moodSeries = _fillGaps(moodSeriesNullable, 5.0);

    // --- Sammanfattning ---
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
              _loading = true;
              _error = false;
              _weekDays = _currentWeekDays();
            });
            await _loadWeekWeather();
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
                      text: 'Denna vecka · Humör vs. väder',
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: const [
                        _LegendDot(label: 'Humör', colorDot: null),
                        _LegendDot(label: 'Väder → humör', colorDot: Colors.teal),
                        _LegendEmoji(emoji: '😔', label: 'Lägre'),
                        _LegendEmoji(emoji: '😐', label: 'Neutralt'),
                        _LegendEmoji(emoji: '😄', label: 'Högre'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Kunde inte hämta veckans väder just nu.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
                        ),
                      )
                    else
                      SizedBox(
                        height: 260,
                        child: _DualLineChart(
                          xLabels: xLabels,
                          xWeatherEmojis: xWeatherEmojis, // ☀️/☁️/🌧️ under X
                          line1: moodSeries,
                          line2: weatherSeries,
                          line1Color: cs.primary,
                          line2Color: Colors.teal,
                          gridColor: theme.dividerColor.withOpacity(.35),
                          yTickEmojis: const ['😔', '😐', '😄'],
                          yTickValues: const [3.0, 5.0, 8.0],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: .7,
                      child: Text(
                        'Dra nedåt för att uppdatera vädret för veckan.',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Enkel placeholder för "Humör per plats"
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SectionTitle(icon: Icons.bar_chart, text: 'Humör per plats (exempel)'),
                    SizedBox(height: 8),
                    _PlaceBarRow(place: _PlaceMood('Hemma', 6.2)),
                    _PlaceBarRow(place: _PlaceMood('Skola', 5.1)),
                    _PlaceBarRow(place: _PlaceMood('Gym', 7.9)),
                    _PlaceBarRow(place: _PlaceMood('Café', 7.1)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Sammanfattning
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
}

/* ----------------------------- UI–hjälpwidgets ---------------------------- */

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

/* --------- Linjediagram (två linjer + emoji-Y + väder-emoji X), utan Path -------- */

class _DualLineChart extends StatelessWidget {
  const _DualLineChart({
    required this.xLabels,
    required this.xWeatherEmojis,
    required this.line1,
    required this.line2,
    required this.line1Color,
    required this.line2Color,
    required this.gridColor,
    required this.yTickEmojis,
    required this.yTickValues,
  });

  final List<String> xLabels;
  final List<String> xWeatherEmojis; // ☀️/☁️/🌧️
  final List<double> line1; // humör
  final List<double> line2; // väder→humör
  final Color line1Color;
  final Color line2Color;
  final Color gridColor;
  final List<String> yTickEmojis;
  final List<double> yTickValues;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DualLineChartPainter(
        xLabels: xLabels,
        xWeatherEmojis: xWeatherEmojis,
        line1: line1,
        line2: line2,
        line1Color: line1Color,
        line2Color: line2Color,
        gridColor: gridColor,
        yTickEmojis: yTickEmojis,
        yTickValues: yTickValues,
        labelStyle: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DualLineChartPainter extends CustomPainter {
  _DualLineChartPainter({
    required this.xLabels,
    required this.xWeatherEmojis,
    required this.line1,
    required this.line2,
    required this.line1Color,
    required this.line2Color,
    required this.gridColor,
    required this.yTickEmojis,
    required this.yTickValues,
    required this.labelStyle,
  });

  final List<String> xLabels;
  final List<String> xWeatherEmojis;
  final List<double> line1;
  final List<double> line2;
  final Color line1Color;
  final Color line2Color;
  final Color gridColor;
  final List<String> yTickEmojis;
  final List<double> yTickValues;
  final TextStyle? labelStyle;

  static const double _minY = 0.0;
  static const double _maxY = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (line1.isEmpty || line2.isEmpty) return;

    // extra space nederst för X-etikett + väder-emoji
    const padding = EdgeInsets.fromLTRB(36, 16, 12, 42);
    final rect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    // Grid (Y)
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final yv in yTickValues) {
      final dy = _mapY(yv, rect);
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), gridPaint);
    }

    // Emoji på Y-axeln
    for (int i = 0; i < yTickEmojis.length && i < yTickValues.length; i++) {
      final emoji = yTickEmojis[i];
      final dy = _mapY(yTickValues[i], rect);
      _drawText(canvas, emoji, Offset(rect.left - 26, dy - 8), labelStyle);
    }

    // X-etiketter + väder-emoji
    final stepX = rect.width / (xLabels.length - 1);
    for (int i = 0; i < xLabels.length; i++) {
      final dx = rect.left + stepX * i;
      _drawText(canvas, xLabels[i], Offset(dx - 10, rect.bottom + 6), labelStyle);

      final emoji = (i < xWeatherEmojis.length) ? xWeatherEmojis[i] : '';
      if (emoji.isNotEmpty) {
        _drawText(canvas, emoji, Offset(dx - 8, rect.bottom + 20), labelStyle);
      }
    }

    // Förbered punkter
    final pts1 = _pointsFor(line1, rect);
    final pts2 = _pointsFor(line2, rect);

    // Linje 1: Humör (hel linje)
    _drawPolyline(canvas, pts1, line1Color, dashed: false);

    // Linje 2: Väder (streckad)
    _drawPolyline(canvas, pts2, line2Color, dashed: true);

    // Punkter
    final p1 = Paint()..color = line1Color;
    final p2 = Paint()..color = line2Color;
    for (final p in pts1) {
      canvas.drawCircle(p, 3.0, p1);
    }
    for (final p in pts2) {
      canvas.drawCircle(p, 3.0, p2);
    }
  }

  List<Offset> _pointsFor(List<double> values, Rect rect) {
    final stepX = rect.width / (values.length - 1);
    final pts = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = rect.left + stepX * i;
      final y = _mapY(values[i], rect);
      pts.add(Offset(x, y));
    }
    return pts;
  }

  void _drawPolyline(Canvas canvas, List<Offset> pts, Color color, {required bool dashed}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    if (!dashed) {
      for (int i = 1; i < pts.length; i++) {
        canvas.drawLine(pts[i - 1], pts[i], paint);
      }
    } else {
      const dash = 6.0;
      const gap = 4.0;
      for (int i = 1; i < pts.length; i++) {
        _drawDashedSegment(canvas, pts[i - 1], pts[i], paint, dash, gap);
      }
    }
  }

  void _drawDashedSegment(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint,
    double dash,
    double gap,
  ) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;

    final ux = dx / dist;
    final uy = dy / dist;
    double drawn = 0;

    while (drawn < dist) {
      final len = min(dash, dist - drawn);
      final sx = a.dx + ux * drawn;
      final sy = a.dy + uy * drawn;
      final ex = a.dx + ux * (drawn + len);
      final ey = a.dy + uy * (drawn + len);
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);
      drawn += dash + gap;
    }
  }

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

  @override
  bool shouldRepaint(covariant _DualLineChartPainter old) => true;
}

/* ------------------------------- Hjälpfunktioner -------------------------- */

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Format YYYY-MM-DD (för _dailyCodes-nyckeln)
String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Emoji -> 0..10 (enkel ordning)
double _scoreFromEmoji(String e) {
  const ordered = ["😭","😫","😢","☹️","🙁","😐","🙂","😊","😄","😃","😁"];
  final i = ordered.indexOf(e);
  if (i < 0) return 5.0;
  return i.toDouble();
}

/// Open-Meteo weathercode -> approx “humörscore” (för väderlinjen)
double _weatherCodeToScore(int code) {
  if (code == 0) return 8.5; // klart
  if ([1, 2, 3].contains(code)) return 6.0; // halvklart/mulet
  if ([45, 48].contains(code)) return 4.0; // dimma
  if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code)) return 3.5; // regn
  if ([71, 73, 75].contains(code)) return 5.5; // snö
  if ([95, 96, 99].contains(code)) return 3.0; // åska
  return 5.0;
}

/// Emoji för kod – förenklad (visas under X-axeln)
String _weatherEmojiFromCode(int code) {
  if (code == 0) return '☀️'; // klart
  if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code)) return '🌧️'; // regn
  return '☁️'; // övrigt
}

/// Fyll null-värden i humörserien så att linjen inte bryts
List<double> _fillGaps(List<double?> source, double fallback) {
  if (source.isEmpty) return [];
  final out = List<double?>.from(source);

  double last = source.firstWhere((e) => e != null, orElse: () => fallback) ?? fallback;
  for (int i = 0; i < out.length; i++) {
    out[i] ??= last;
    last = out[i]!;
  }
  for (int i = out.length - 2; i >= 0; i--) {
    if (source[i] == null) out[i] = out[i + 1];
  }
  return out.cast<double>();
}

/// Veckodagar på svenska (Mån..Sön)
List<String> _weekdayLabelsSv(List<DateTime> days) {
  const names = ['Mån','Tis','Ons','Tor','Fre','Lör','Sön'];
  return List<String>.generate(days.length, (i) => names[i % 7]);
}

/// Vanligaste värdet i en iterable
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

/* ----------------------- Dummy “plats”-UI (placeholder) ------------------- */

class _PlaceMood {
  final String name;
  final double value;
  const _PlaceMood(this.name, this.value);
}

class _PlaceBarRow extends StatelessWidget {
  const _PlaceBarRow({required this.place});
  final _PlaceMood place;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              place.name,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final width = c.maxWidth * (place.value / 10).clamp(0.0, 1.0);
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: 14,
                      width: width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            cs.primary.withOpacity(.90),
                            cs.primary.withOpacity(.55),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(.20),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              place.value.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
