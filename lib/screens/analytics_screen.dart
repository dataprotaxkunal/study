// lib/screens/analytics_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/chapter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _sortBy = 'hours'; // hours | sessions | name

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<String>(
            onSelected:(v)=>setState(()=>_sortBy=v),
            itemBuilder:(_)=>[
              const PopupMenuItem(value:'hours',   child:Text('Sort by Hours')),
              const PopupMenuItem(value:'sessions', child:Text('Sort by Sessions')),
              const PopupMenuItem(value:'name',    child:Text('Sort by Name')),
            ],
          ),
        ],
      ),
      body: Consumer<AppProvider>(builder:(ctx,p,_) {
        final totalH = p.totalHoursAllTime;
        final weekH  = p.hoursThisWeek();
        final totalS = p.sessions.length;
        final avgH   = totalS==0 ? 0.0 : totalH/totalS;

        // Chapter list sorted
        final chaps = List<Chapter>.from(p.chapters);
        if (_sortBy=='hours')    chaps.sort((a,b)=>p.totalHoursForChapter(b.id).compareTo(p.totalHoursForChapter(a.id)));
        if (_sortBy=='sessions') chaps.sort((a,b)=>p.sessionCountForChapter(b.id).compareTo(p.sessionCountForChapter(a.id)));
        if (_sortBy=='name')     chaps.sort((a,b)=>a.topic.compareTo(b.topic));

        // Max hours (for bar scaling)
        double maxH = 1.0;
        for (final c in chaps) { final h = p.totalHoursForChapter(c.id); if (h > maxH) maxH = h; }

        // Subjects bar chart data
        final subjHours = { for (final s in p.subjects) s.code: p.totalHoursForSubject(s.code) };
        final maxSubjH  = subjHours.values.isEmpty ? 1.0 : subjHours.values.reduce(max);

        final unstudied = p.unstudiedChapters;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Summary cards ─────────────────────────────────────────────
            Row(children:[
              _SummaryCard(value:'${totalH.toStringAsFixed(1)}h', label:'Total Hours',   color:const Color(0xFF1a73e8)),
              const SizedBox(width:8),
              _SummaryCard(value:'${weekH.toStringAsFixed(1)}h',  label:'This Week',    color:const Color(0xFF7b1fa2)),
              const SizedBox(width:8),
              _SummaryCard(value:'$totalS',                        label:'Sessions',     color:const Color(0xFF1e8e3e)),
              const SizedBox(width:8),
              _SummaryCard(value:'${avgH.toStringAsFixed(1)}h',   label:'Avg/Session',  color:const Color(0xFFf59e0b)),
            ]),
            const SizedBox(height:20),

            // ── Subject hours bar chart ───────────────────────────────────
            Text('Hours by Subject', style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w600)),
            const SizedBox(height:12),
            Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
              ...p.subjects.map((s) {
                final h   = p.totalHoursForSubject(s.code);
                final pal = p.palFor(s.code);
                final fg  = Color(pal['color']!);
                final ratio = maxSubjH==0 ? 0.0 : h/maxSubjH;
                return Padding(padding:const EdgeInsets.only(bottom:12),child:Row(children:[
                  SizedBox(width:36,child:Text(s.code,style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:fg))),
                  Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(4),child:LinearProgressIndicator(
                    value:ratio, minHeight:18,
                    backgroundColor:Colors.grey.shade100,
                    valueColor:AlwaysStoppedAnimation<Color>(fg),
                  ))),
                  const SizedBox(width:8),
                  SizedBox(width:40,child:Text('${h.toStringAsFixed(1)}h',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600))),
                ]));
              }),
            ]))),
            const SizedBox(height:16),

            // ── Warning: unstudied chapters ───────────────────────────────
            if (unstudied.isNotEmpty)...[
              Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFfce8e6),borderRadius:BorderRadius.circular(12),border:Border.all(color:const Color(0xFFd93025).withOpacity(.3))),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(children:[const Icon(Icons.warning_amber_outlined,color:Color(0xFFd93025),size:18),const SizedBox(width:6),
                    Text('${unstudied.length} chapters never studied',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:Color(0xFFd93025)))]),
                  const SizedBox(height:4),
                  Text(unstudied.map((c)=>c.topic).take(3).join(', ')+(unstudied.length>3?'…':''),style:const TextStyle(fontSize:11,color:Color(0xFFd93025))),
                ])),
              const SizedBox(height:16),
            ],

            // ── Chapter-wise breakdown ────────────────────────────────────
            Row(children:[
              Text('Chapter-wise Hours', style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w600)),
              const Spacer(),
              Text('Sorted by $_sortBy',style:const TextStyle(fontSize:11,color:Colors.grey)),
            ]),
            const SizedBox(height:12),

            ...chaps.map((ch) {
              final h    = p.totalHoursForChapter(ch.id);
              final sess = p.sessionCountForChapter(ch.id);
              final pal  = p.palFor(ch.subject);
              final bg   = Color(pal['bg']!); final fg = Color(pal['color']!);
              final barW = maxH==0 ? 0.0 : (h/maxH).clamp(0.0,1.0);
              final isHeavy = h > (totalH / p.chapters.length * 2.5) && h > 1; // warn if 2.5x avg

              return Card(margin:const EdgeInsets.only(bottom:8),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[
                  Expanded(child:Text(ch.topic,style:TextStyle(fontSize:12,fontWeight:FontWeight.w500,color:h==0?Colors.grey:null),maxLines:2,overflow:TextOverflow.ellipsis)),
                  const SizedBox(width:8),
                  Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                    Text('${h.toStringAsFixed(1)}h',style:TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:isHeavy?const Color(0xFFd93025):fg)),
                    Text('$sess session${sess!=1?"s":""}',style:const TextStyle(fontSize:10,color:Colors.grey)),
                  ]),
                ]),
                const SizedBox(height:6),
                Row(children:[
                  Container(padding:const EdgeInsets.symmetric(horizontal:5,vertical:1),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(4)),
                    child:Text(ch.subject,style:TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:fg))),
                  const SizedBox(width:8),
                  Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(3),child:LinearProgressIndicator(
                    value:barW, minHeight:6,
                    backgroundColor:Colors.grey.shade100,
                    valueColor:AlwaysStoppedAnimation<Color>(isHeavy?const Color(0xFFd93025):fg),
                  ))),
                  if (ch.completed) ...[const SizedBox(width:6), const Icon(Icons.check_circle,size:14,color:Color(0xFF1e8e3e))],
                  if (isHeavy) ...[const SizedBox(width:4),const Tooltip(message:'Too much time on this topic',child:Icon(Icons.warning_amber,size:14,color:Color(0xFFd93025)))],
                  if (h==0 && ch.startDate.isNotEmpty) ...[const SizedBox(width:4),const Tooltip(message:'Never studied',child:Icon(Icons.hourglass_empty,size:14,color:Colors.grey))],
                ]),
              ])));
            }),
          ],
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value, label; final Color color;
  const _SummaryCard({required this.value,required this.label,required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child:Card(child:Padding(padding:const EdgeInsets.symmetric(vertical:12,horizontal:8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(value,style:TextStyle(fontSize:18,fontWeight:FontWeight.w300,color:color)),
    const SizedBox(height:2),
    Text(label,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:Colors.grey,letterSpacing:.4)),
  ]))));
}
