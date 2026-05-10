// lib/screens/study_timer_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/chapter.dart';
import '../widgets/notes_sheet.dart';

class StudyTimerScreen extends StatelessWidget {
  const StudyTimerScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const StudyTimerScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final ch = p.activeChapterId == null ? null
          : p.chapters.firstWhere((c) => c.id == p.activeChapterId,
              orElse: () => Chapter(id: -1, topic: '', subject: ''));
      if (ch == null || ch.id == -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).maybePop());
        return const SizedBox.shrink();
      }

      final pal = p.palFor(ch.subject);
      final accent = Color(pal['color']!);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
          body: SafeArea(
            child: Column(children: [
              // ── Top bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(.1), shape: BoxShape.circle),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Studying', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const Spacer(),
                  // Notes button
                  GestureDetector(
                    onTap: () => NotesSheet.show(context, ch, p),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: ch.hasNotes ? accent.withOpacity(.3) : Colors.white.withOpacity(.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(ch.hasNotes ? Icons.note_alt_rounded : Icons.note_alt_outlined,
                          color: ch.hasNotes ? accent : Colors.white, size: 20),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Chapter info ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  Text('#Individually Studying',
                      style: TextStyle(color: Colors.white.withOpacity(.4), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(ch.topic,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -.3)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: accent.withOpacity(.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(ch.subject, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),

              // ── Circular timer ─────────────────────────────────────────
              Expanded(
                child: Center(
                  child: ValueListenableBuilder<Duration>(
                    valueListenable: p.timerDuration,
                    builder: (_, dur, __) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(
                        width: 260, height: 260,
                        child: Stack(alignment: Alignment.center, children: [
                          // Painter
                          CustomPaint(
                            size: const Size(260, 260),
                            painter: _TimerPainter(elapsed: dur, color: accent),
                          ),
                          // Time text
                          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(_formatTime(dur),
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 52,
                                  fontWeight: FontWeight.w300, letterSpacing: -2,
                                )),
                            const SizedBox(height: 4),
                            Text(_sessionLabel(p, ch.id),
                                style: TextStyle(color: Colors.white.withOpacity(.4), fontSize: 12, fontWeight: FontWeight.w500)),
                          ]),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),

              // ── Bottom controls ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(children: [
                  // Hours studied today
                  ValueListenableBuilder<Duration>(
                    valueListenable: p.timerDuration,
                    builder: (_, dur, __) {
                      final totalToday = p.sessions
                          .where((s) => s.chapterId == ch.id && s.date == _todayStr())
                          .fold(0, (sum, s) => sum + s.durationMinutes);
                      final totalH = (totalToday + dur.inMinutes) / 60.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                          _InfoPill('Today', '${totalH.toStringAsFixed(1)}h', Colors.white),
                          Container(width: 1, height: 30, color: Colors.white12),
                          _InfoPill('Sessions', '${p.sessionCountForChapter(ch.id)}', Colors.white),
                          Container(width: 1, height: 30, color: Colors.white12),
                          _InfoPill('All-time', '${p.totalHoursForChapter(ch.id).toStringAsFixed(1)}h', Colors.white),
                        ]),
                      );
                    },
                  ),
                  // Stop button
                  GestureDetector(
                    onTap: () {
                      p.stopTimer();
                      Navigator.of(context).maybePop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(.4), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.stop_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text('Stop Studying', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      );
    });
  }

  String _formatTime(Duration d) {
    final h = d.inHours; final m = d.inMinutes % 60; final s = d.inSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  String _sessionLabel(AppProvider p, int chId) {
    final n = p.sessionCountForChapter(chId) + 1;
    return 'Session $n today';
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }
}

// ── Circular arc painter ───────────────────────────────────────────────────
class _TimerPainter extends CustomPainter {
  final Duration elapsed;
  final Color color;
  const _TimerPainter({required this.elapsed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;

    // Background ring
    canvas.drawCircle(center, radius,
        Paint()..color = Colors.white.withOpacity(.08)..style = PaintingStyle.stroke..strokeWidth = 14);

    // Progress (1-hour cycle)
    final progress = (elapsed.inSeconds % 3600) / 3600.0;
    if (progress > 0) {
      // Glow
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false,
          Paint()..color = color.withOpacity(.3)..style = PaintingStyle.stroke..strokeWidth = 22..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      // Main arc
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round);
      // Dot at tip
      final angle = -pi / 2 + 2 * pi * progress;
      final tipX = center.dx + radius * cos(angle);
      final tipY = center.dy + radius * sin(angle);
      canvas.drawCircle(Offset(tipX, tipY), 7,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_TimerPainter old) => old.elapsed != elapsed;
}

class _InfoPill extends StatelessWidget {
  final String label, value; final Color color;
  const _InfoPill(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: color.withOpacity(.4), fontSize: 11, fontWeight: FontWeight.w500)),
  ]);
}

