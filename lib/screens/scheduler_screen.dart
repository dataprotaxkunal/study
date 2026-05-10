// lib/screens/scheduler_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/chapter.dart';
import '../widgets/notes_sheet.dart';
import 'study_timer_screen.dart';

class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});
  @override State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  DateTime _selected = DateTime.now();
  late DateTime _monthStart;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected   = DateTime(_selected.year, _selected.month, _selected.day);
    _monthStart = DateTime(_selected.year, _selected.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scrollToSelected() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo((_selected.day-1)*64.0, duration:const Duration(milliseconds:300), curve:Curves.easeOut);
    }
  }

  void _changeMonth(int dir) {
    setState(() {
      _monthStart = DateTime(_monthStart.year, _monthStart.month+dir, 1);
      if (_selected.month!=_monthStart.month||_selected.year!=_monthStart.year) _selected=_monthStart;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _goToday() {
    setState(() {
      _selected   = DateTime.now();
      _selected   = DateTime(_selected.year, _selected.month, _selected.day);
      _monthStart = DateTime(_selected.year, _selected.month, 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  Set<int> _getDaysWithEvents(List<Chapter> chapters, int year, int month, int daysInMonth) {
    final result = <int>{};
    for (final ch in chapters) {
      final s = Chapter.parseDate(ch.startDate);
      final e = Chapter.parseDate(ch.endDate.isNotEmpty?ch.endDate:ch.startDate);
      if (s==null&&e==null) continue;
      final rs=s??e!; final re=e??s!;
      final me=DateTime(year,month,daysInMonth);
      var cur=rs.isBefore(DateTime(year,month,1))?DateTime(year,month,1):rs;
      while(!cur.isAfter(re)&&!cur.isAfter(me)){ result.add(cur.day); cur=cur.add(const Duration(days:1)); }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Row(children:[
          IconButton(icon:const Icon(Icons.chevron_left),onPressed:()=>_changeMonth(-1),padding:EdgeInsets.zero),
          GestureDetector(onTap:_goToday,child:Text(DateFormat('MMMM yyyy').format(_monthStart),style:const TextStyle(fontSize:16))),
          IconButton(icon:const Icon(Icons.chevron_right),onPressed:()=>_changeMonth(1),padding:EdgeInsets.zero),
        ]),
        actions:[TextButton(onPressed:_goToday,child:const Text('Today'))],
      ),
      body: Consumer<AppProvider>(builder:(ctx,p,_) {
        final dim = DateUtils.getDaysInMonth(_monthStart.year,_monthStart.month);
        final dwe = _getDaysWithEvents(p.chapters,_monthStart.year,_monthStart.month,dim);

        return Column(children:[

          // ── Day strip ────────────────────────────────────────────────────
          SizedBox(height:76,child:ListView.builder(
            controller:_scrollCtrl, scrollDirection:Axis.horizontal,
            padding:const EdgeInsets.symmetric(horizontal:8,vertical:8),
            itemCount:dim,
            itemBuilder:(ctx,i){
              final day=i+1;
              final dt=DateTime(_monthStart.year,_monthStart.month,day);
              return _DayPill(
                day:day, weekday:DateFormat('EEE').format(dt).substring(0,3),
                isToday:DateUtils.isSameDay(dt,DateTime.now()),
                isSelected:DateUtils.isSameDay(dt,_selected),
                hasEvent:dwe.contains(day),
                onTap:()=>setState(()=>_selected=dt),
              );
            },
          )),
          const Divider(height:1),
          Expanded(child:_buildDayEvents(p)),
        ]);
      }),
    );
  }

  Widget _buildDayEvents(AppProvider p) {
    final selT = _selected.millisecondsSinceEpoch;
    final starting=<Chapter>[]; final ending=<Chapter>[]; final active=<Chapter>[];

    for (final ch in p.chapters) {
      final s=Chapter.parseDate(ch.startDate);
      final e=Chapter.parseDate(ch.endDate.isNotEmpty?ch.endDate:'');
      final sT=s?.millisecondsSinceEpoch; final eT=e?.millisecondsSinceEpoch;
      if(sT!=null&&eT!=null){
        if(selT>=sT&&selT<=eT){
          if(selT==sT&&selT==eT) starting.add(ch);
          else if(selT==sT) starting.add(ch);
          else if(selT==eT) ending.add(ch);
          else active.add(ch);
        }
      } else if(sT!=null&&selT==sT) starting.add(ch);
      else if(eT!=null&&selT==eT)   ending.add(ch);
    }

    sort(List<Chapter> l)=>l.sort((a,b)=>(a.studyTime.isEmpty?'99:99':a.studyTime).compareTo(b.studyTime.isEmpty?'99:99':b.studyTime));
    sort(starting); sort(ending); sort(active);

    final isToday  = DateUtils.isSameDay(_selected,DateTime.now());
    final allEmpty = starting.isEmpty&&ending.isEmpty&&active.isEmpty;

    return ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[
        Text('${_selected.day}',style:const TextStyle(fontSize:32,fontWeight:FontWeight.w300,color:Color(0xFF1a73e8))),
        const SizedBox(width:10),
        Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(DateFormat('EEEE').format(_selected),style:const TextStyle(fontSize:14,fontWeight:FontWeight.w500)),
          Text(DateFormat('MMMM yyyy').format(_selected),style:const TextStyle(fontSize:11,color:Colors.grey)),
        ]),
        if(isToday)...[const SizedBox(width:10),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),decoration:BoxDecoration(color:const Color(0xFF1a73e8),borderRadius:BorderRadius.circular(20)),child:const Text('TODAY',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700)))],
      ]),
      const SizedBox(height:16),
      if(allEmpty)...[
        const SizedBox(height:40),
        const Icon(Icons.calendar_today_outlined,size:48,color:Colors.grey),
        const SizedBox(height:12),
        const Center(child:Text('No topics scheduled for this day.',style:TextStyle(color:Colors.grey))),
        const Center(child:Text('Add start/end dates in Topic List.',style:TextStyle(color:Colors.grey,fontSize:12))),
      ] else ...[
        if(starting.isNotEmpty) _EventGroup(title:'🟢 Starting Today',chapters:starting,provider:p),
        if(ending.isNotEmpty)   _EventGroup(title:'🔴 Due Today',chapters:ending,provider:p),
        if(active.isNotEmpty)   _EventGroup(title:'🔵 In Progress',chapters:active,provider:p),
      ],
    ]);
  }
}

// ── Day Pill ──────────────────────────────────────────────────────────────
class _DayPill extends StatelessWidget {
  final int day; final String weekday;
  final bool isToday,isSelected,hasEvent;
  final VoidCallback onTap;
  const _DayPill({required this.day,required this.weekday,required this.isToday,required this.isSelected,required this.hasEvent,required this.onTap});
  @override
  Widget build(BuildContext context) {
    final bg=isSelected?const Color(0xFF1a73e8):(isToday?const Color(0xFFe8f0fe):Colors.transparent);
    final fg=isSelected?Colors.white:(isToday?const Color(0xFF1a73e8):Theme.of(context).colorScheme.onSurface);
    return GestureDetector(onTap:onTap,child:Container(
      width:52, margin:const EdgeInsets.only(right:4),
      decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(12),border:isToday&&!isSelected?Border.all(color:const Color(0xFF1a73e8)):null),
      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Text(weekday,style:TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:fg.withOpacity(.7))),
        const SizedBox(height:2),
        Text('$day',style:TextStyle(fontSize:17,fontWeight:isSelected?FontWeight.w500:FontWeight.w300,color:fg)),
        const SizedBox(height:3),
        Container(width:5,height:5,decoration:BoxDecoration(shape:BoxShape.circle,color:hasEvent?(isSelected?Colors.white70:const Color(0xFF1a73e8)):Colors.transparent)),
      ]),
    ));
  }
}

// ── Event Group ───────────────────────────────────────────────────────────
class _EventGroup extends StatelessWidget {
  final String title; final List<Chapter> chapters; final AppProvider provider;
  const _EventGroup({required this.title,required this.chapters,required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.only(bottom:8),child:Text(title,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:Colors.grey,letterSpacing:.5))),
      ...chapters.map((ch) {
        final pal=provider.palFor(ch.subject);
        final bg=Color(pal['bg']!); final fg=Color(pal['color']!);
        final isActive=provider.activeChapterId==ch.id;
        final hasRange=ch.startDate.isNotEmpty&&ch.endDate.isNotEmpty&&ch.startDate!=ch.endDate;
        final rangeTxt=hasRange?'${_fmt(ch.startDate)} → ${_fmt(ch.endDate)}':(ch.startDate.isNotEmpty?_fmt(ch.startDate):_fmt(ch.endDate));
        final hours=provider.totalHoursForChapter(ch.id);
        final sessions=provider.sessionCountForChapter(ch.id);

        return Container(
          margin:const EdgeInsets.only(bottom:10),
          decoration:BoxDecoration(
            color:isActive?const Color(0xFF1a73e8).withOpacity(.05):(ch.completed?Colors.grey.shade50:bg.withOpacity(.12)),
            borderRadius:BorderRadius.circular(12),
            border:Border(left:BorderSide(color:isActive?const Color(0xFF1a73e8):(ch.completed?Colors.grey:fg),width:4)),
          ),
          child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
            // Complete checkbox
            GestureDetector(onTap:()=>provider.toggleComplete(ch.id),child:Container(
              width:22,height:22,margin:const EdgeInsets.only(right:10),
              decoration:BoxDecoration(shape:BoxShape.circle,color:ch.completed?const Color(0xFF1e8e3e):Colors.transparent,border:Border.all(color:ch.completed?const Color(0xFF1e8e3e):Colors.grey.shade400,width:2)),
              child:ch.completed?const Icon(Icons.check,size:12,color:Colors.white):null,
            )),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(ch.topic,style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:ch.completed?Colors.grey:null,decoration:ch.completed?TextDecoration.lineThrough:null)),
              const SizedBox(height:4),
              Wrap(spacing:6,runSpacing:4,children:[
                Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(4)),child:Text(ch.subject,style:TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:fg))),
                Text(rangeTxt,style:const TextStyle(fontSize:10,color:Colors.grey)),
                if(ch.studyTime.isNotEmpty) _timeBadge(ch.studyTime),
                if(sessions>0) Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(border:Border.all(color:Colors.grey.shade300),borderRadius:BorderRadius.circular(6)),
                  child:Text('${hours.toStringAsFixed(1)}h · $sessions sess.',style:const TextStyle(fontSize:9,fontWeight:FontWeight.w600,color:Colors.grey))),
              ]),
            ])),
            const SizedBox(width:8),
            // Start / Stop timer
            if(!ch.completed)
              GestureDetector(
                onTap:(){
                  if(isActive) provider.stopTimer();
                  else provider.startTimer(ch.id);
                },
                child:Container(
                  width:36,height:36,
                  decoration:BoxDecoration(shape:BoxShape.circle,color:isActive?const Color(0xFFd93025):const Color(0xFF1a73e8)),
                  child:Icon(isActive?Icons.stop:Icons.play_arrow,color:Colors.white,size:20),
                ),
              ),
          ])),
        );
      }),
      const SizedBox(height:8),
    ]);
  }

  Widget _timeBadge(String t) {
    return Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(border:Border.all(color:Colors.grey.shade300),borderRadius:BorderRadius.circular(6)),
      child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.access_time,size:10,color:Colors.grey),const SizedBox(width:3),Text(_fmt12(t),style:const TextStyle(fontSize:9,fontWeight:FontWeight.w600,color:Colors.grey))]));
  }

  String _fmt(String d) { try{return DateFormat('dd MMM').format(DateFormat('yyyy-MM-dd').parse(d));}catch(_){return d;} }
  String _fmt12(String t) {
    if(t.isEmpty)return'';
    final p=t.split(':'); final h=int.tryParse(p[0])??0; final m=int.tryParse(p.length>1?p[1]:'0')??0;
    return '${h%12==0?12:h%12}:${m.toString().padLeft(2,'0')} ${h>=12?"PM":"AM"}';
  }
}

