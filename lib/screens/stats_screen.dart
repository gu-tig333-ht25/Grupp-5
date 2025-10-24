// lib/screens/statistik.dart
import 'package:flutter/material.dart';

class StatistikPage extends StatelessWidget {
  const StatistikPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // --- FEJKDATA (byt mot riktig data senare) ---
    // 0–10 skala på humör
    final last14Days = <double>[4, 6, 5, 7, 6, 8, 7, 5, 6, 7, 6, 7.5, 7, 8];

    // Enkel väderserie lika lång som last14Days:
    // sun, cloud, rain -> renderas som emoji i grafen
    final weather = <_Weather>[
      _Weather.sun,
      _Weather.cloud,
      _Weather.sun,
      _Weather.rain,
      _Weather.cloud,
      _Weather.sun,
      _Weather.sun,
      _Weather.rain,
      _Weather.cloud,
      _Weather.sun,
      _Weather.cloud,
      _Weather.sun,
      _Weather.rain,
      _Weather.sun,
    ];

    final places = <_PlaceMood>[
      const _PlaceMood('Hemma', 6.2),
      const _PlaceMood('Skola', 5.1),
      const _PlaceMood('Gym', 7.9),
      const _PlaceMood('Café', 7.1),
    ];

    final heat = List.generate(
      4, // veckor
      (row) => List.generate(7, (col) => (row * 7 + col) % 10 / 10),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // -------- Linjediagram: Humör + väder ----------
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.show_chart,
                    text: 'Senaste 14 dagarna',
                  ),
                  const SizedBox(height: 6),
                  // liten legend för väder
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: const [
                      _LegendDot(label: 'Humör', colorDot: null),
                      _LegendEmoji(emoji: '☀️', label: 'Sol'),
                      _LegendEmoji(emoji: '☁️', label: 'Moln'),
                      _LegendEmoji(emoji: '🌧️', label: 'Regn'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 200,
                    child: _LineChart(
                      values: last14Days,
                      weather: weather,
                      stroke: cs.primary,
                      fillTop: cs.primary.withValues(alpha: .10),
                      fillBottom: cs.primary.withValues(alpha: .00),
                      gridColor: theme.dividerColor.withValues(alpha: .35),
                      dotColor: cs.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // --------- Humör per plats ----------
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.bar_chart,
                    text: 'Humör per plats',
                  ),
                  const SizedBox(height: 8),
                  ...places.map((p) => _PlaceBarRow(place: p)),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // --------- Heatmap 4 veckor ----------
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.grid_on,
                    text: 'Heatmap (senaste 4 veckor)',
                  ),
                  const SizedBox(height: 10),
                  _HeatGrid(values: heat),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: .7,
                    child: Text(
                      'Mån  Tis  Ons  Tor  Fre  Lör  Sön',
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // --------- Tre sammanfattningskort ----------
            Row(
              children: const [
                Expanded(
                  child: _SummaryCard(
                    title: 'Snitt',
                    value: '6.8',
                    icon: Icons.emoji_emotions,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    title: 'Inlägg',
                    value: '24',
                    icon: Icons.edit_note,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    title: 'Vanligast',
                    value: '😊',
                    icon: Icons.mood,
                  ),
                ),
              ],
            ),
          ],
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
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
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
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
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
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
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
                        color: cs.surfaceContainerHighest.withValues(alpha: .6),
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
                            cs.primary.withValues(alpha: .90),
                            cs.primary.withValues(alpha: .55),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: .20),
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
          _ValuePill(text: place.value.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}

/* --------------------------------- Heatmap -------------------------------- */

class _HeatGrid extends StatelessWidget {
  const _HeatGrid({required this.values});
  final List<List<double>> values; // 4 rader x 7 kolumner (0..1)

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 7 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: values
              .map(
                (row) => Expanded(
                  child: Row(
                    children: row
                        .map(
                          (v) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Color.lerp(
                                  cs.errorContainer,
                                  cs.primaryContainer,
                                  v,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/* --------------------------- LineChart (med väder) -------------------------- */

enum _Weather { sun, cloud, rain }

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.values,
    required this.weather,
    required this.stroke,
    required this.fillTop,
    required this.fillBottom,
    required this.gridColor,
    required this.dotColor,
  });

  final List<double> values; // skala 0–10
  final List<_Weather> weather;
  final Color stroke;
  final Color fillTop;
  final Color fillBottom;
  final Color gridColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        values: values,
        weather: weather,
        stroke: stroke,
        fillTop: fillTop,
        fillBottom: fillBottom,
        gridColor: gridColor,
        dotColor: dotColor,
        textStyle: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.weather,
    required this.stroke,
    required this.fillTop,
    required this.fillBottom,
    required this.gridColor,
    required this.dotColor,
    required this.textStyle,
  });

  final List<double> values;
  final List<_Weather> weather;
  final Color stroke;
  final Color fillTop;
  final Color fillBottom;
  final Color gridColor;
  final Color dotColor;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const padding = 16.0;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    // --- Grid (horisontella linjer) + y-etiketter 0,5,10 ---
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final dy = rect.top + rect.height * i / 4;
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), gridPaint);
    }
    _drawLabel(canvas, '10', Offset(rect.left - 10, rect.top - 6));
    _drawLabel(
      canvas,
      '5',
      Offset(rect.left - 10, rect.top + rect.height / 2 - 6),
    );
    _drawLabel(canvas, '0', Offset(rect.left - 10, rect.bottom - 6));

    // --- Linjeväg ---
    const maxY = 10.0;
    final stepX = rect.width / (values.length - 1);
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = rect.left + stepX * i;
      final y = rect.bottom - (values[i] / maxY) * rect.height;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // --- Area-fill (vertikal gradient) ---
    final fillPath = Path.from(path)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();

    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fillTop, fillBottom],
    ).createShader(rect);

    final fillPaint = Paint()..shader = shader;
    canvas.drawPath(fillPath, fillPaint);

    // --- Stroke ---
    final linePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..isAntiAlias = true;
    canvas.drawPath(path, linePaint);

    // --- Dots + väderemoji under varje punkt ---
    final dotPaint = Paint()..color = dotColor;
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 3.0, dotPaint);

      final emoji = switch (weather[i]) {
        _Weather.sun => '☀️',
        _Weather.cloud => '☁️',
        _Weather.rain => '🌧️',
      };

      final tp = TextPainter(
        text: TextSpan(text: emoji, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // placera strax under datapunkten, men inte under diagrammet
      final emojiOffset = Offset(
        p.dx - tp.width / 2,
        (p.dy + 12).clamp(rect.top, rect.bottom - tp.height),
      );
      tp.paint(canvas, emojiOffset);
    }

    // --- x-etiketter (glest för läsbarhet) ---
    for (int i = 0; i < values.length; i++) {
      if (i % 3 != 0) continue;
      final label = 'd${i + 1}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = Offset(rect.left + stepX * i - tp.width / 2, rect.bottom + 4);
      tp.paint(canvas, pos);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) {
    return old.values != values ||
        old.weather != weather ||
        old.stroke != stroke ||
        old.fillTop != fillTop ||
        old.fillBottom != fillBottom ||
        old.gridColor != gridColor ||
        old.dotColor != dotColor ||
        old.textStyle != textStyle;
  }
}
