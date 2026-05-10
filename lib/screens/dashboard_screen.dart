// lib/screens/dashboard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/subject.dart';
import '../main.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(builder: (ctx, p, _) {
        final examDays  = _examDays(p.examDate);
        final weekHrs   = p.hoursThisWeek();
        final totalPct  = p.chapters.isEmpty ? 0.0 : p.completedCount / p.chapters.length;
        final hour      = DateTime.now().hour;
        final greeting  = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

        return CustomScrollView(slivers: [
          SliverAppBar(
            floating: true, pinned: false,
            backgroundColor: kBg,
            title: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: kBlue, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Text('CMA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              const Text('Study Tracker'),
            ]),
            actions: [
              IconButton(
                icon: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                  child: const Icon(Icons.settings_outlined, size: 17, color: kText2),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              const SizedBox(width: 6),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // ── Compact hero (greeting + rings + stats all in ONE card) ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

                    // Left: text + stats
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$greeting 👋',
                          style: const TextStyle(fontSize: 12, color: kText3, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        examDays != null
                            ? (examDays > 0 ? 'Exam in\n$examDays days' : 'Exam was\n${examDays.abs()} days ago')
                            : 'CMA Exam\nTracker',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5, height: 1.2, color: kText),
                      ),
                      const SizedBox(height: 14),
                      // 3 mini stat pills
                      _MiniStat('${p.completedCount}/${p.chapters.length}', 'Chapters', kGreen),
                      const SizedBox(height: 6),
                      _MiniStat('${weekHrs.toStringAsFixed(1)}h', 'This week', kBlue),
                      const SizedBox(height: 6),
                      _MiniStat('${p.sessions.length}', 'Sessions', kPurple),
                    ])),

                    const SizedBox(width: 16),

                    // Right: activity rings
                    _ActivityRings(
                      pct1: totalPct,
                      pct2: (weekHrs / 20.0).clamp(0.0, 1.0),
                      pct3: p.chapters.isEmpty ? 0.0 : (p.pendingRevisionCount == 0 ? 1.0 : (1.0 - p.pendingRevisionCount / 5.0).clamp(0.0, 1.0)),
                      label: '${(totalPct * 100).round()}%',
                      sub: 'done',
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              // ── Revision alert (compact) ──────────────────────────────
              if (p.pendingRevisionCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.replay_rounded, color: kAmber, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      '${p.pendingRevisionCount} revision${p.pendingRevisionCount > 1 ? "s" : ""} pending',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    )),
                    const Icon(Icons.chevron_right_rounded, color: kAmber, size: 18),
                  ]),
                ),
                const SizedBox(height: 12),
              ],

              // ── Subjects ─────────────────────────────────────────────
              Row(children: [
                const Text('Subjects', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -.2)),
                const Spacer(),
                Text('${p.subjects.length} total', style: const TextStyle(fontSize: 12, color: kText3)),
              ]),
              const SizedBox(height: 10),

              if (p.subjects.isEmpty)
                Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
                  const Icon(Icons.school_outlined, size: 40, color: kText3),
                  const SizedBox(height: 12),
                  const Text('No subjects yet', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Go to Settings to add subjects', style: TextStyle(color: kText3, fontSize: 12)),
                ])))
              else
                ...p.subjects.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SubjectCard(subject: s),
                )),
            ])),
          ),
        ]);
      }),
    );
  }

  int? _examDays(String d) {
    if (d.isEmpty) return null;
    try { return DateFormat('yyyy-MM-dd').parse(d).difference(DateTime.now()).inDays; }
    catch (_) { return null; }
  }
}

// ── Mini stat row ─────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String val, label; final Color color;
  const _MiniStat(this.val, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 7),
    Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 12, color: kText3, fontWeight: FontWeight.w400)),
  ]);
}

// ── Activity rings (3 concentric) ────────────────────────────────────────
class _ActivityRings extends StatelessWidget {
  final double pct1, pct2, pct3;
  final String label, sub;
  const _ActivityRings({required this.pct1, required this.pct2, required this.pct3, required this.label, required this.sub});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130, height: 130,
    child: Stack(alignment: Alignment.center, children: [
      CustomPaint(
        size: const Size(130, 130),
        painter: _RingsPainter(pct1: pct1, pct2: pct2, pct3: pct3),
      ),
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.5, color: kText)),
        Text(sub, style: const TextStyle(fontSize: 11, color: kText3, fontWeight: FontWeight.w500)),
      ]),
    ]),
  );
}

class _RingsPainter extends CustomPainter {
  final double pct1, pct2, pct3;
  const _RingsPainter({required this.pct1, required this.pct2, required this.pct3});

  void _ring(Canvas c, double cx, double cy, double r, Color bg, Color fg, double pct) {
    final trackP = Paint()..color = bg..style = PaintingStyle.stroke..strokeWidth = 9;
    c.drawCircle(Offset(cx, cy), r, trackP);
    if (pct > 0) {
      final arcP = Paint()
        ..color = fg..style = PaintingStyle.stroke..strokeWidth = 9..strokeCap = StrokeCap.round;
      c.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          -pi / 2, 2 * pi * pct.clamp(0.0, 1.0), false, arcP);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    _ring(canvas, cx, cy, 57, kBlue.withOpacity(.12), kBlue, pct1);
    _ring(canvas, cx, cy, 43, kGreen.withOpacity(.12), kGreen, pct2);
    _ring(canvas, cx, cy, 29, kAmber.withOpacity(.15), kAmber, pct3);
  }

  @override bool shouldRepaint(_) => true;
}

// ── Subject card ─────────────────────────────────────────────────────────
class _SubjectCard extends StatefulWidget {
  final Subject subject;
  const _SubjectCard({required this.subject});
  @override State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (_, p, __) {
      final pal   = p.palFor(widget.subject.code);
      final bg    = Color(pal['bg']!);
      final fg    = Color(pal['color']!);
      final chs   = p.chapters.where((c) => c.subject == widget.subject.code).toList();
      final done  = chs.where((c) => c.completed).length;
      final hours = p.totalHoursForSubject(widget.subject.code);
      final pct   = chs.isEmpty ? 0.0 : done / chs.length;

      return Card(child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(widget.subject.code, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.subject.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -.2)),
                  const SizedBox(height: 2),
                  Text('$done/${chs.length} chapters · ${hours.toStringAsFixed(1)}h',
                      style: const TextStyle(fontSize: 11, color: kText3)),
                ])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: pct == 1.0 ? kGreen.withOpacity(.1) : bg, borderRadius: BorderRadius.circular(20)),
                  child: Text('${(pct * 100).round()}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: pct == 1.0 ? kGreen : fg)),
                ),
                const SizedBox(width: 4),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: kText3, size: 18),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(
                value: pct, minHeight: 6,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(pct == 1.0 ? kGreen : fg),
              )),
            ]),
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
            child: Row(children: [
              const Icon(Icons.access_time_rounded, size: 14, color: kText3),
              const SizedBox(width: 6),
              Text('${hours.toStringAsFixed(1)}h studied', style: const TextStyle(fontSize: 12, color: kText2, fontWeight: FontWeight.w500)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Delete Subject?'),
                  content: Text('Deletes all chapters for ${widget.subject.name}.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    FilledButton(style: FilledButton.styleFrom(backgroundColor: kRed), onPressed: () { p.deleteSubject(widget.subject.code); Navigator.pop(ctx); }, child: const Text('Delete')),
                  ],
                )),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: kRed, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
              ),
            ]),
          ),
        ],
      ]));
    });
  }
}
