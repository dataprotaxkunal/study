// lib/screens/topic_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/chapter.dart';
import '../widgets/notes_sheet.dart';

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});
  @override State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  String _filterSubject = 'ALL';
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(builder: (ctx, p, _) {
        final q = _searchCtrl.text.toLowerCase();
        final filtered = p.chapters.where((ch) {
          if (_filterSubject != 'ALL' && ch.subject != _filterSubject) return false;
          if (q.isNotEmpty &&
              !ch.topic.toLowerCase().contains(q) &&
              !ch.subject.toLowerCase().contains(q) &&
              !ch.notes.toLowerCase().contains(q)) return false;
          return true;
        }).toList();

        return Column(children: [
          // ── Filter bar ────────────────────────────────────────────────
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search topics and notes…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear_rounded, size: 16), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              if (p.subjects.isNotEmpty)
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterSubject,
                    isDense: true,
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('All', style: TextStyle(fontSize: 12))),
                      ...p.subjects.map((s) => DropdownMenuItem(value: s.code, child: Text(s.code, style: const TextStyle(fontSize: 12)))),
                    ],
                    onChanged: (v) => setState(() => _filterSubject = v ?? 'ALL'),
                  ),
                ),
            ]),
          ),

          // ── Count bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Text('${filtered.length} of ${p.chapters.length} chapters',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const Spacer(),
              if (p.chaptersWithNotesCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                  child: Text('${p.chaptersWithNotesCount} with notes',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF92400E))),
                ),
            ]),
          ),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No chapters match.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _ChapterTile(chapter: filtered[i], index: i + 1),
                  ),
          ),
        ]);
      }),
    );
  }

  // ── Add chapter dialog with proper date pickers ────────────────────────
  void _showAddDialog(BuildContext context) {
    final p = context.read<AppProvider>();
    if (p.subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a subject first in Settings')));
      return;
    }
    final topicCtrl = TextEditingController();
    String selectedSubject = p.subjects.first.code;
    DateTime? startDate, endDate;
    TimeOfDay? studyTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Add Chapter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Topic name
            TextField(
              controller: topicCtrl,
              decoration: const InputDecoration(labelText: 'Chapter / Topic Name'),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            // Subject picker
            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: p.subjects.map((s) => DropdownMenuItem(
                  value: s.code,
                  child: Text('${s.code} – ${s.name}', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setS(() => selectedSubject = v ?? selectedSubject),
            ),
            const SizedBox(height: 12),

            // Date pickers row
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    startDate == null ? 'Start Date' : DateFormat('dd MMM yyyy').format(startDate!),
                    style: TextStyle(fontSize: 12,
                        color: startDate != null ? Theme.of(ctx).colorScheme.primary : Colors.grey),
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setS(() => startDate = d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: Text(
                    endDate == null ? 'End Date' : DateFormat('dd MMM yyyy').format(endDate!),
                    style: TextStyle(fontSize: 12,
                        color: endDate != null ? Theme.of(ctx).colorScheme.primary : Colors.grey),
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setS(() => endDate = d);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 8),

            // Time picker
            OutlinedButton.icon(
              icon: const Icon(Icons.access_time_rounded, size: 16),
              label: Text(
                studyTime == null ? 'Set Study Time (optional)' : studyTime!.format(ctx),
                style: TextStyle(fontSize: 12,
                    color: studyTime != null ? Theme.of(ctx).colorScheme.primary : Colors.grey),
              ),
              onPressed: () async {
                final t = await showTimePicker(
                    context: ctx, initialTime: const TimeOfDay(hour: 9, minute: 0));
                if (t != null) setS(() => studyTime = t);
              },
            ),
            const SizedBox(height: 16),

            // Add button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Chapter'),
                onPressed: () {
                  final name = topicCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter a chapter name')));
                    return;
                  }
                  final st = studyTime != null
                      ? '${studyTime!.hour.toString().padLeft(2, '0')}:${studyTime!.minute.toString().padLeft(2, '0')}'
                      : '';
                  p.addChapter(Chapter(
                    id: 0, topic: name, subject: selectedSubject,
                    startDate: startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : '',
                    endDate: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : '',
                    studyTime: st,
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chapter added ✓')));
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Chapter tile — NO complete checkbox, just info + edit + notes ─────────
class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final int index;
  const _ChapterTile({required this.chapter, required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, p, _) {
      final pal = p.palFor(chapter.subject);
      final bg  = Color(pal['bg']!);
      final fg  = Color(pal['color']!);

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            // Index
            Text('$index',
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(width: 10),

            // Content
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(chapter.topic,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Wrap(spacing: 6, runSpacing: 4, children: [
                // Subject
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
                  child: Text(chapter.subject,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
                ),
                // Start date
                if (chapter.startDate.isNotEmpty)
                  _chip(Icons.play_arrow_rounded, _fmtDate(chapter.startDate)),
                // End date
                if (chapter.endDate.isNotEmpty)
                  _chip(Icons.flag_rounded, _fmtDate(chapter.endDate)),
                // Study time
                if (chapter.studyTime.isNotEmpty)
                  _chip(Icons.access_time_rounded, _fmt12(chapter.studyTime)),
                // Sessions count
                if (p.sessionCountForChapter(chapter.id) > 0)
                  _chip(Icons.timer_outlined,
                      '${p.totalHoursForChapter(chapter.id).toStringAsFixed(1)}h'),
              ]),

              // Notes preview
              if (chapter.hasNotes) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(children: [
                    const Icon(Icons.note_alt_rounded, size: 11, color: Color(0xFF92400E)),
                    const SizedBox(width: 5),
                    Expanded(child: Text(
                      chapter.notes.split('\n').first.trim(),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                  ]),
                ),
              ],
            ])),

            const SizedBox(width: 8),

            // Action buttons
            Column(mainAxisSize: MainAxisSize.min, children: [
              // Notes
              _iconBtn(
                icon: chapter.hasNotes ? Icons.note_alt_rounded : Icons.note_alt_outlined,
                color: chapter.hasNotes ? const Color(0xFF92400E) : Colors.grey,
                bg: chapter.hasNotes ? const Color(0xFFFEF3C7) : Colors.grey.shade100,
                onTap: () => NotesSheet.show(context, chapter, p),
              ),
              const SizedBox(height: 4),
              // More options
              _iconBtn(
                icon: Icons.more_vert_rounded,
                color: Colors.grey,
                bg: Colors.grey.shade100,
                onTap: () => _showOptions(context, p, chapter),
              ),
            ]),
          ]),
        ),
      );
    });
  }

  Widget _chip(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: Colors.grey),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ],
  );

  Widget _iconBtn({required IconData icon, required Color color, required Color bg, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 16, color: color),
        ),
      );

  void _showOptions(BuildContext context, AppProvider p, Chapter ch) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_calendar_rounded, color: Colors.blue),
            title: const Text('Edit Dates & Time'),
            onTap: () { Navigator.pop(ctx); _showEditDialog(context, p, ch); },
          ),
          ListTile(
            leading: const Icon(Icons.note_alt_rounded, color: Color(0xFF92400E)),
            title: const Text('Open Notes'),
            onTap: () { Navigator.pop(ctx); NotesSheet.show(context, ch, p); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            title: const Text('Remove Chapter', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (dlg) => AlertDialog(
                  title: const Text('Remove chapter?'),
                  content: Text('"${ch.topic}" will be permanently deleted.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dlg), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () { p.deleteChapter(ch.id); Navigator.pop(dlg); },
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showEditDialog(BuildContext context, AppProvider p, Chapter ch) {
    DateTime? startDate = Chapter.parseDate(ch.startDate);
    DateTime? endDate   = Chapter.parseDate(ch.endDate);
    TimeOfDay? studyTime;
    if (ch.studyTime.isNotEmpty) {
      final parts = ch.studyTime.split(':');
      studyTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Edit Chapter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(ch.topic, style: const TextStyle(fontSize: 13, color: Colors.grey),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),

            // Date pickers
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    startDate == null ? 'Start Date' : DateFormat('dd MMM yyyy').format(startDate!),
                    style: TextStyle(fontSize: 12,
                        color: startDate != null ? Theme.of(ctx).colorScheme.primary : Colors.grey),
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2024), lastDate: DateTime(2030),
                    );
                    if (d != null) setS(() => startDate = d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: Text(
                    endDate == null ? 'End Date' : DateFormat('dd MMM yyyy').format(endDate!),
                    style: TextStyle(fontSize: 12,
                        color: endDate != null ? Theme.of(ctx).colorScheme.primary : Colors.grey),
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: endDate ?? startDate ?? DateTime.now(),
                      firstDate: DateTime(2024), lastDate: DateTime(2030),
                    );
                    if (d != null) setS(() => endDate = d);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              icon: const Icon(Icons.access_time_rounded, size: 16),
              label: Text(
                studyTime == null ? 'Set Study Time' : studyTime!.format(ctx),
                style: TextStyle(fontSize: 12,
                    color: studyTime != null ? Theme.of(ctx).colorScheme.primary : Colors.grey),
              ),
              onPressed: () async {
                final t = await showTimePicker(
                    context: ctx,
                    initialTime: studyTime ?? const TimeOfDay(hour: 9, minute: 0));
                if (t != null) setS(() => studyTime = t);
              },
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Changes'),
                onPressed: () {
                  final st = studyTime != null
                      ? '${studyTime!.hour.toString().padLeft(2, '0')}:${studyTime!.minute.toString().padLeft(2, '0')}'
                      : '';
                  p.updateChapter(ch.id,
                    startDate: startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : '',
                    endDate: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : '',
                    studyTime: st,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chapter updated ✓')));
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(String d) {
    try { return DateFormat('dd MMM').format(DateFormat('yyyy-MM-dd').parse(d)); }
    catch (_) { return d; }
  }

  String _fmt12(String t) {
    if (t.isEmpty) return '';
    final parts = t.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2, '0')} ${h >= 12 ? "PM" : "AM"}';
  }
}
