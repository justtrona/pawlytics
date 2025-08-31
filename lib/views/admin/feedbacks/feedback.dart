import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // App palette (same vibe as your other screens)
  static const navy = Color(0xFF0F2D50);
  static const subtitle = Color(0xFF6E7B8A);
  static const bg = Color(0xFFF6F7F9);

  // Sample data (percent values 0..1)
  final List<_FeedbackEntry> entries = const [
    _FeedbackEntry(label: 'Very Satisfied', percent: 0.30, emoji: '😊'),
    _FeedbackEntry(label: 'Satisfied', percent: 0.14, emoji: '🙂'),
    _FeedbackEntry(label: 'Neutral', percent: 0.08, emoji: '😐'),
    _FeedbackEntry(label: 'Dissatisfied', percent: 0.05, emoji: '🙁'),
    _FeedbackEntry(label: 'Very Dissatisfied', percent: 0.03, emoji: '☹️'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.maybePop(context),
          color: Colors.black87,
        ),
        title: const Text(
          'Feedbacks',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: entries.length,
        itemBuilder: (_, i) => _FeedbackCard(entry: entries[i]),
      ),
    );
  }
}

class _FeedbackEntry {
  final String label;
  final double percent; // 0..1
  final String emoji;
  const _FeedbackEntry({
    required this.label,
    required this.percent,
    required this.emoji,
  });
}

class _FeedbackCard extends StatelessWidget {
  static const navy = Color(0xFF0F2D50);
  static const subtitle = Color(0xFF6E7B8A);

  final _FeedbackEntry entry;
  const _FeedbackCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final percentText = '${(entry.percent * 100).toStringAsFixed(0)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: navy,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                percentText,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Icon + progress
          Row(
            children: [
              // Emoji “icon”
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: navy.withOpacity(.06),
                ),
                child: Text(entry.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),

              // Nice rounded progress bar
              Expanded(
                child: _SoftProgress(
                  value: entry.percent,
                  trackColor: Colors.grey.shade300,
                  fillColor: navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A softer, rounded progress bar (looks like your mock but cleaner)
class _SoftProgress extends StatelessWidget {
  final double value; // 0..1
  final Color trackColor;
  final Color fillColor;

  const _SoftProgress({
    required this.value,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = 14.0;

        // ✅ Ensure fillW is always a double
        final fillW = (w * value).clamp(0, w).toDouble();

        return Container(
          height: h,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Subtle inner shadow for the track
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [trackColor, trackColor.withOpacity(.9)],
                    ),
                  ),
                ),
              ),
              // Fill bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                width: fillW, // ✅ Safe double value
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
