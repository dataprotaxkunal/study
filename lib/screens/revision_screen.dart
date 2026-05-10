// lib/screens/revision_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/revision.dart';
import '../models/chapter.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});
  @override State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override void initState() { super.initState(); _tab = TabController(length:3, vsync:this); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision'),
        bottom: TabBar(controller:_tab, tabs:const [
          Tab(text:'Due / Overdue'), Tab(text:'Upcoming'), Tab(text:'Completed'),
        ]),
      ),
      body: Consumer<AppProvider>(builder:(ctx,p,_) {
        final due       = p.revisions.where((r)=>!r.isCompleted&&(r.isDueToday||r.isOverdue)).toList()
            ..sort((a,b)=>a.scheduledDate.compareTo(b.scheduledDate));
        final upcoming  = p.revisions.where((r)=>r.isUpcoming).toList()
            ..sort((a,b)=>a.scheduledDate.compareTo(b.scheduledDate));
        final completed = p.revisions.where((r)=>r.isCompleted).toList()
            ..sort((a,b)=>b.completedDate.compareTo(a.completedDate));

        return TabBarView(controller:_tab, children:[
          _RevisionList(revisions:due, provider:p, emptyMsg:'No revisions due today!', emptyIcon:Icons.check_circle_outline, emptyColor:const Color(0xFF1e8e3e)),
          _RevisionList(revisions:upcoming, provider:p, emptyMsg:'No upcoming revisions.', emptyIcon:Icons.upcoming_outlined, emptyColor:Colors.grey),
          _RevisionList(revisions:completed, provider:p, emptyMsg:'No completed revisions yet.', emptyIcon:Icons.history, emptyColor:Colors.grey, isCompleted:true),
        ]);
      }),
    );
  }
}

class _RevisionList extends StatelessWidget {
  final List<Revision> revisions;
  final AppProvider provider;
  final String emptyMsg;
  final IconData emptyIcon;
  final Color emptyColor;
  final bool isCompleted;
  const _RevisionList({required this.revisions,required this.provider,required this.emptyMsg,required this.emptyIcon,required this.emptyColor,this.isCompleted=false});

  @override
  Widget build(BuildContext context) {
    if (revisions.isEmpty) return Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(emptyIcon,size:52,color:emptyColor),
      const SizedBox(height:12),
      Text(emptyMsg,style:TextStyle(color:emptyColor,fontWeight:FontWeight.w500)),
      if (!isCompleted) ...[
        const SizedBox(height:8),
        const Text('Complete chapters in Scheduler to schedule revisions.',textAlign:TextAlign.center,style:TextStyle(color:Colors.grey,fontSize:12)),
      ],
    ]));

    return ListView.builder(
      padding:const EdgeInsets.all(16),
      itemCount:revisions.length,
      itemBuilder:(ctx,i) {
        final r  = revisions[i];
        final ch = provider.chapters.firstWhere((c)=>c.id==r.chapterId, orElse:()=>Chapter(id:-1,topic:'Unknown',subject:''));
        final pal = provider.palFor(ch.subject);
        final bg  = Color(pal['bg']!); final fg = Color(pal['color']!);

        final isOverdue = r.isOverdue;
        final borderColor = isCompleted ? Colors.grey.shade300 : (isOverdue ? const Color(0xFFd93025) : const Color(0xFF1a73e8));
        final bgColor = isCompleted ? Colors.grey.shade50 : (isOverdue ? const Color(0xFFfce8e6) : const Color(0xFFe8f0fe));

        return Card(margin:const EdgeInsets.only(bottom:10),child:Container(
          decoration:BoxDecoration(border:Border(left:BorderSide(color:borderColor,width:4)),borderRadius:BorderRadius.circular(14)),
          child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:bgColor,borderRadius:BorderRadius.circular(6)),
                  child:Text(r.revisionLabel,style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:borderColor))),
                if (isOverdue && !isCompleted)...[const SizedBox(width:6),Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:const Color(0xFFfce8e6),borderRadius:BorderRadius.circular(6)),
                  child:const Text('OVERDUE',style:TextStyle(fontSize:9,fontWeight:FontWeight.w700,color:Color(0xFFd93025))))],
              ]),
              const SizedBox(height:6),
              Text(ch.topic,style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:isCompleted?Colors.grey:null,decoration:isCompleted?TextDecoration.lineThrough:null)),
              const SizedBox(height:4),
              Row(children:[
                Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(4)),
                  child:Text(ch.subject,style:TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:fg))),
                const SizedBox(width:8),
                Icon(isCompleted?Icons.check_circle:Icons.calendar_today,size:11,color:Colors.grey),
                const SizedBox(width:3),
                Text(isCompleted?'Done: ${_fmt(r.completedDate)}':'Due: ${_fmt(r.scheduledDate)}',style:const TextStyle(fontSize:11,color:Colors.grey)),
              ]),
            ])),
            if (!isCompleted)
              FilledButton(
                onPressed:()=>provider.completeRevision(r.id),
                style:FilledButton.styleFrom(backgroundColor:const Color(0xFF1e8e3e),padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),minimumSize:Size.zero),
                child:const Text('Done ✓',style:TextStyle(fontSize:12)),
              ),
          ])),
        ));
      },
    );
  }

  String _fmt(String d) {
    try { return DateFormat('dd MMM yyyy').format(DateFormat('yyyy-MM-dd').parse(d)); }
    catch (_) { return d; }
  }
}
