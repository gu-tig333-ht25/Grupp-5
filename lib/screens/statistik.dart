// lib/screens/statistik.dart
import 'package:flutter/material.dart';

class StatistikPage extends StatelessWidget {
  const StatistikPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // --- FEJKDATA (byt mot riktig data senare) ---
    final last14Days = <double>[4, 6, 5, 7, 6, 8, 7, 5, 6, 7, 6, 7.5, 7, 8];
    final places = <_PlaceMood>[
      _PlaceMood('Hemma', 6.2),
      _PlaceMood('Skola', 5.1),
      _PlaceMood('Gym', 7.9),
      _PlaceMood('Café', 7.1),
    ];
    final heat = List.generate(
      4,
      (row) => List.generate(7, (col) => (row * 7 + col) % 10 / 10),
    );
    const avg = 6.8;
    const count = 24;
    const common = '😊 Glad';
    const aiSentiment = 'Övervägande positivt';
    const aiNote =
        'Återkommande ord: “plugg”, “träning”, “vänner”. Stress syns inför tentor men lättar efter gympass.';

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(icon: Icons.auto_awesome, text: 'AI-översikt'),
                  const SizedBox(height: 8),
                  Row(children: [_Chip(text: aiSentiment)]),
                  const SizedBox(height: 8),
                  Text(
                    aiNote,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.show_chart,
                    text: 'Senaste 14 dagarna',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: _LineChart(
                      values: last14Days,
                      stroke: colorScheme.primary,
                      fill: colorScheme.primary.withOpacity(0.15),
                      gridColor: theme.dividerColor.withOpacity(.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(icon: Icons.bar_chart, text: 'Humör per plats'),
                  const SizedBox(height: 8),
                  ...places.map((p) => _PlaceBarRow(place: p)).toList(),
                ],
              ),
            ),

            const SizedBox(height: 12),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.grid_on,
                    text: 'Heatmap (senaste 4 veckor)',
                  ),
                  const SizedBox(height: 12),
                  _HeatGrid(values: heat),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: _SummaryCard(
                    title: 'Snitt',
                    value: '6.8',
                    icon: Icons.emoji_emotions,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Inlägg',
                    value: '24',
                    icon: Icons.edit_note,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Vanligast',
                    value: '😊',
                    icon: Icons.mood,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export påbörjad (mock)…')),
                );
              },
              icon: const Icon(Icons.file_download),
              label: const Text('Exportera data'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
    final style = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(text, style: style),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: t.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: t.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
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
          SizedBox(width: 72, child: Text(place.name)),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth * (place.value / 10).clamp(0.0, 1.0);
                return Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 12,
                      width: w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.primary.withOpacity(.6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              place.value.toStringAsFixed(1),
              textAlign: TextAlign.right,
            ),
          ),
        ],
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
      child: Column(
        children: values
            .map(
              (row) => Expanded(
                child: Row(
                  children: row
                      .map(
                        (v) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Container(
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
                        ),
                      )
                      .toList(),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/* --------------------------------- LineChart ------------------------------- */

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.values,
    required this.stroke,
    required this.fill,
    required this.gridColor,
  });

  final List<double> values; // skala 0–10
  final Color stroke;
  final Color fill;
  final Color gridColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(values, stroke, fill, gridColor),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.values, this.stroke, this.fill, this.gridColor);

  final List<double> values;
  final Color stroke;
  final Color fill;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final padding = 12.0;
    final chartRect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    // grid
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final dy = chartRect.top + chartRect.height * i / 4;
      canvas.drawLine(
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        gridPaint,
      );
    }

    // line path
    final maxY = 10.0;
    final stepX = chartRect.width / (values.length - 1);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = chartRect.left + stepX * i;
      final y = chartRect.bottom - (values[i] / maxY) * chartRect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // fill
    final fillPath = Path.from(path)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();
    final fillPaint = Paint()..color = fill;
    canvas.drawPath(fillPath, fillPaint);

    // stroke
    final linePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..isAntiAlias = true;
    canvas.drawPath(path, linePaint);

    // dots
    final dotPaint = Paint()..color = stroke;
    for (int i = 0; i < values.length; i++) {
      final x = chartRect.left + stepX * i;
      final y = chartRect.bottom - (values[i] / maxY) * chartRect.height;
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.stroke != stroke ||
        oldDelegate.fill != fill ||
        oldDelegate.gridColor != gridColor;
  }
}
