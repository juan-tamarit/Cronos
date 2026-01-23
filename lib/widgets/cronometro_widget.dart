import 'dart:async';
import 'package:cronos/models/session.dart';
import 'package:flutter/material.dart';
import '../db/session_dao.dart';

class CronometroWidget extends StatefulWidget{
  final int objetiveMinutes;
  final int activityId;

  CronometroWidget({
    super.key,
    required this.objetiveMinutes,
    required this.activityId
  });

  @override
  State<CronometroWidget> createState()=> _CronometroWidgetState();
}

class _CronometroWidgetState extends State<CronometroWidget>{
  DateTime? _sessionStart;
  Timer? _timer;
  int _seconds=0;
  bool _running=false;

  @override
  void initState() {
    super.initState();
    _loadAccumulatedTime();
  }

  Future<void> _loadAccumulatedTime() async {
    final allSessions = await SessionDao().getByActivity(widget.activityId);
    final today = DateTime.now();
  
   // Filtramos solo las sesiones de hoy
    final todaySeconds = allSessions
      .where((s) =>
        s.start.year == today.year &&
        s.start.month == today.month &&
        s.start.day == today.day)
      .fold<int>(0, (sum, s) => sum + s.durationSecs);
  
    setState(() {
      _seconds = todaySeconds;
    });
}

  void _start(){
    _sessionStart??=DateTime.now();
    if (_running) return;
    _timer= Timer.periodic(const Duration(seconds:1),(timer){
      setState(() {_seconds++;});
    });
    setState(() {_running=true;});
  }

  void _pause() async{
    if (!_running|| _sessionStart==null||_seconds==0) return;
    _timer?.cancel();
    setState(() {_running=false;});
    final session=Session(
      activityId:widget.activityId, 
      start:_sessionStart!, 
      end: DateTime.now(), 
      durationSecs: _seconds
    );
    await SessionDao().insert(session);
  }

  void _reset(){
    _timer?.cancel();
    setState(() {
      _seconds=0;
      _running=false;
      _sessionStart=null;
    });
  }

  String _formaTime (int seconds){
    final minutes=seconds ~/ 60;
    final secs= seconds % 60;

    return '${minutes.toString().padLeft(2,'0')}:${secs.toString().padLeft(2,'0')}';
  }

  @override
   void dispose(){
    if(_running && _sessionStart!=null && _seconds >0){
      final session=Session(
        activityId: widget.activityId,
        start: _sessionStart!,
        end:DateTime.now(),
        durationSecs: _seconds
      );
      SessionDao().insert(session);
    }
    _timer?.cancel();
    super.dispose();
   }
   Widget build (BuildContext context){
    final objetiveSeconds= widget.objetiveMinutes*60;
    final diference=_seconds-objetiveSeconds;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_formaTime(_seconds),style: const TextStyle(fontSize:48),),
        const SizedBox(height: 8),
        Text(
          diference>=0
            ? 'Tiempo extra: ${_formaTime(diference)}'
            : 'Faltan: ${_formaTime(-diference)}'
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _running ? null: _start,
              child: const Text('Start')
            ),
            ElevatedButton(
              onPressed: _running ? _pause: null,
              child: Text('Pause')
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _reset, 
              child: const Text('Reset')
            ),
          ],
        ),
      ],
    );
   }
}