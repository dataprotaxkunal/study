// lib/widgets/notes_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chapter.dart';
import '../providers/app_provider.dart';

class NotesSheet extends StatefulWidget {
  final Chapter chapter;
  final AppProvider provider;

  const NotesSheet({super.key, required this.chapter, required this.provider});

  static Future<void> show(BuildContext context, Chapter chapter, AppProvider provider) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotesSheet(chapter: chapter, provider: provider),
    );
  }

  @override
  State<NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<NotesSheet> {
  late TextEditingController _ctrl;
  bool _changed = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.chapter.notes);
    _ctrl.addListener(() {
      setState(() => _changed = _ctrl.text != widget.chapter.notes);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.provider.updateNotes(widget.chapter.id, _ctrl.text);
    setState(() { _changed = false; _saved = true; });
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes saved ✓'), duration: Duration(seconds: 1)),
    );
  }

  void _clear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Notes?'),
        content: const Text('This will delete all notes for this chapter.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFd93025)),
            onPressed: () {
              _ctrl.clear();
              widget.provider.updateNotes(widget.chapter.id, '');
              setState(() { _changed = false; _saved = false; });
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _fmtTimestamp(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return 'Last edited: ${DateFormat('dd MMM yyyy, hh:mm a').format(dt)}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final pal  = widget.provider.palFor(widget.chapter.subject);
    final bg   = Color(pal['bg']!);
    final fg   = Color(pal['color']!);
    final ts   = _fmtTimestamp(widget.chapter.notesUpdatedAt);
    final charCount = _ctrl.text.length;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(children: [
          // ── Handle ────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),

          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
                    child: Text(widget.chapter.subject,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.note_alt_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('Notes', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 6),
                Text(widget.chapter.topic,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
              // Clear button
              if (widget.chapter.hasNotes || _ctrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFd93025)),
                  onPressed: _clear,
                  tooltip: 'Clear notes',
                ),
            ]),
          ),

          const Divider(height: 16),

          // ── Quick tags row ────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _QuickTag('⭐ Important', onTap: () => _insertTag('⭐ Important: ')),
              _QuickTag('📌 Remember', onTap: () => _insertTag('📌 Remember: ')),
              _QuickTag('🔗 Link', onTap: () => _insertTag('🔗 Ref: Ind AS ')),
              _QuickTag('❓ Doubt', onTap: () => _insertTag('❓ Doubt: ')),
              _QuickTag('✅ Formula', onTap: () => _insertTag('✅ Formula: ')),
              _QuickTag('📝 Example', onTap: () => _insertTag('📝 Example: ')),
            ]),
          ),
          const SizedBox(height: 10),

          // ── Text editor ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 14, height: 1.6),
                decoration: InputDecoration(
                  hintText: 'Write your notes here…\n\nTips:\n• Key formulas\n• Important points\n• Things to remember\n• Doubts to clarify',
                  hintStyle: TextStyle(color: Colors.grey.shade400, height: 1.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1a73e8), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(children: [
              // Timestamp + char count
              Row(children: [
                if (ts.isNotEmpty)
                  Text(ts, style: const TextStyle(fontSize: 10, color: Colors.grey))
                else
                  const Text('No notes yet', style: TextStyle(fontSize: 10, color: Colors.grey)),
                const Spacer(),
                Text('$charCount chars', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
              const SizedBox(height: 10),
              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _changed ? _save : null,
                  icon: Icon(_saved && !_changed ? Icons.check : Icons.save_outlined, size: 18),
                  label: Text(_saved && !_changed ? 'Saved ✓' : 'Save Notes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _changed ? const Color(0xFF1a73e8) : Colors.grey.shade300,
                    foregroundColor: _changed ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _insertTag(String tag) {
    final pos  = _ctrl.selection.end < 0 ? _ctrl.text.length : _ctrl.selection.end;
    final text = _ctrl.text;
    final prefix = pos > 0 && !text.substring(0, pos).endsWith('\n') ? '\n' : '';
    _ctrl.value = _ctrl.value.copyWith(
      text: '${text.substring(0, pos)}$prefix$tag${text.substring(pos)}',
      selection: TextSelection.collapsed(offset: pos + prefix.length + tag.length),
    );
  }
}

class _QuickTag extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickTag(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    ),
  );
}
