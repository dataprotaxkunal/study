// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/subject.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AppProvider>(builder: (ctx, p, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Subjects ─────────────────────────────────────────────────
          _SectionLabel('Subjects'),
          _Card(children: [
            _Tile(
              icon: Icons.add_circle_outline_rounded,
              iconBg: const Color(0xFFEFF6FF), iconColor: const Color(0xFF2563EB),
              title: 'Add New Subject',
              subtitle: 'Add a subject to track',
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () => _showAddSubjectDialog(ctx, p),
            ),
            if (p.subjects.isNotEmpty) ...[
              const Divider(height: 1, indent: 56),
              ...p.subjects.map((s) {
                final pal = p.palFor(s.code);
                final bg  = Color(pal['bg']!); final fg = Color(pal['color']!);
                final chs = p.chapters.where((c) => c.subject == s.code).length;
                return Column(children: [
                  ListTile(
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(s.code, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                    title: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('$chs chapters', style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                      onPressed: () => showDialog(
                        context: ctx,
                        builder: (dlg) => AlertDialog(
                          title: const Text('Delete Subject?'),
                          content: Text('Deletes "${s.name}" and all its chapters.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dlg), child: const Text('Cancel')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () { p.deleteSubject(s.code); Navigator.pop(dlg); },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  ),
                  if (s != p.subjects.last) const Divider(height: 1, indent: 56),
                ]);
              }),
            ],
          ]),

          // ── Exam Date ─────────────────────────────────────────────────
          _SectionLabel('Exam'),
          _Card(children: [
            _Tile(
              icon: Icons.timer_outlined,
              iconBg: const Color(0xFFFCE8E6), iconColor: const Color(0xFFDC2626),
              title: 'Exam Date',
              subtitle: p.examDate.isNotEmpty ? _fmtDate(p.examDate) : 'Not set — tap to set',
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (d != null) p.setExamDate(DateFormat('yyyy-MM-dd').format(d));
              },
            ),
          ]),

          // ── Notifications & Alarms ────────────────────────────────────
          _SectionLabel('Notifications & Alarms'),
          _Card(children: [
            // Test notification
            _Tile(
              icon: Icons.notifications_active_outlined,
              iconBg: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706),
              title: 'Test Notification',
              subtitle: 'Send a test to verify notifications work on your phone',
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () async {
                await NotificationService.sendTestNotification();
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Test notification sent! Check your status bar ↑')));
              },
            ),
            const Divider(height: 1, indent: 56),
            // Grant alarm permission
            _Tile(
              icon: Icons.alarm_on_rounded,
              iconBg: const Color(0xFFEFF6FF), iconColor: const Color(0xFF2563EB),
              title: 'Grant Alarm Permission',
              subtitle: 'Required for study time alerts on Android 12+. Tap → allow "Alarms & Reminders"',
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () async {
                await NotificationService.requestExactAlarmPermission();
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Allow "Alarms & Reminders" → come back → tap Reschedule')));
              },
            ),
            const Divider(height: 1, indent: 56),
            // Reschedule all
            _Tile(
              icon: Icons.refresh_rounded,
              iconBg: const Color(0xFFE6F4EA), iconColor: const Color(0xFF16A34A),
              title: 'Reschedule All Notifications',
              subtitle: 'Tap after granting alarm permission to activate all study reminders',
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              onTap: () {
                p.rescheduleAll();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('All notifications rescheduled ✓')));
              },
            ),
          ]),

          // ── Study Focus / DND ─────────────────────────────────────────
          _SectionLabel('Study Focus (Do Not Disturb)'),
          _Card(children: [
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: const Color(0xFFF3E8FD), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.do_not_disturb_on_outlined, color: Color(0xFF7C3AED), size: 18),
              ),
              title: const Text('Enable Focus Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Reminds you to enable DND at study start time — calls still allowed',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              trailing: Switch(
                value: p.dndEnabled,
                onChanged: (v) { if (v) _showDndInfo(ctx, p); else p.setDnd(enabled: false); },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            if (p.dndEnabled) ...[
              const Divider(height: 1, indent: 56),
              _Tile(
                icon: Icons.play_circle_outline_rounded,
                iconBg: const Color(0xFFE6F4EA), iconColor: const Color(0xFF16A34A),
                title: 'Focus Start Time',
                subtitle: _fmt12(p.dndStart),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: _parseTime(p.dndStart));
                  if (t != null) p.setDnd(start: '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}');
                },
              ),
              const Divider(height: 1, indent: 56),
              _Tile(
                icon: Icons.stop_circle_outlined,
                iconBg: const Color(0xFFFCE8E6), iconColor: const Color(0xFFDC2626),
                title: 'Focus End Time',
                subtitle: _fmt12(p.dndEnd),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: _parseTime(p.dndEnd));
                  if (t != null) p.setDnd(end: '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}');
                },
              ),
            ],
          ]),

          // ── Appearance ────────────────────────────────────────────────
          _SectionLabel('Appearance'),
          _Card(children: [
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.dark_mode_outlined, color: Colors.white, size: 18),
              ),
              title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Switch to dark theme', style: TextStyle(fontSize: 11, color: Colors.grey)),
              trailing: Switch(value: p.darkMode, onChanged: p.setDarkMode),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ]),

          // ── Data ──────────────────────────────────────────────────────
          _SectionLabel('Data'),
          _Card(children: [
            _Tile(
              icon: Icons.delete_outline_rounded,
              iconBg: const Color(0xFFFCE8E6), iconColor: const Color(0xFFDC2626),
              title: 'Clear All Data',
              subtitle: 'Resets everything to default — cannot be undone',
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
              onTap: () => showDialog(
                context: ctx,
                builder: (dlg) => AlertDialog(
                  title: const Text('Clear All Data?'),
                  content: const Text('This deletes all subjects, chapters, sessions and settings.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dlg), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () { p.clearAll(); Navigator.pop(dlg); },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),
          const Center(child: Text('CMA Study Tracker v3.0',
              style: TextStyle(fontSize: 11, color: Colors.grey))),
        ],
      )),
    );
  }

  void _showAddSubjectDialog(BuildContext context, AppProvider p) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Subject Name'), autofocus: true),
          const SizedBox(height: 12),
          TextField(controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Short Code (e.g. SFM)'),
              textCapitalization: TextCapitalization.characters, maxLength: 6),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final code = codeCtrl.text.trim().toUpperCase();
              if (name.isEmpty || code.isEmpty) return;
              if (p.subjects.any((s) => s.code == code)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code already exists')));
                return;
              }
              p.addSubject(Subject(code: code, name: name));
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDndInfo(BuildContext context, AppProvider p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Study Focus Mode'),
        content: const Text(
          'When enabled, you will receive a notification at your study start time reminding you to turn on Do Not Disturb.\n\n'
          'To set up DND on Android:\n'
          '• Settings → Sound → Do Not Disturb\n'
          '• Set to "Priority Only"\n'
          '• Under Priority: Allow Calls\n\n'
          'The app cannot control DND automatically — Android requires manual permission.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { p.setDnd(enabled: true); Navigator.pop(ctx); },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(String d) {
    try { return DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd').parse(d)); }
    catch (_) { return d; }
  }

  static String _fmt12(String t) {
    if (t.isEmpty) return 'Not set';
    final parts = t.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2,'0')} ${h >= 12 ? "PM" : "AM"}';
  }

  static TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 9, minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 1.0)),
  );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 4), child: Column(children: children));
}

class _Tile extends StatelessWidget {
  final IconData icon; final Color iconBg, iconColor;
  final String title, subtitle; final Widget trailing; final VoidCallback? onTap;
  const _Tile({required this.icon, required this.iconBg, required this.iconColor,
      required this.title, required this.subtitle, required this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(width: 38, height: 38,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 18)),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    trailing: trailing,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}
