import 'dart:async';
import 'package:cronos/models/session.dart';
import 'package:flutter/material.dart';
import '../db/session_dao.dart';

class CronometroWidget extends StatefulWidget{
  final int objetiveMinutes;
  final int activityId;

  const CronometroWidget({
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
  int _baseSeconds = 0;
  bool _running=false;
  int get _seconds{
    if (!_running || _sessionStart == null) {
      return _baseSeconds;
    }
    final now = DateTime.now();
    final elapsed = now.difference(_sessionStart!).inSeconds;
    return _baseSeconds + elapsed;
  }
  @override
  void initState() {
    super.initState();
    _loadAccumulatedTime();
  }

  Future<void> _loadAccumulatedTime() async {
    final dao = SessionDao();
    final lastSession = await dao.getLastSession(widget.activityId);

    if (lastSession == null) {
      setState(() {
        _baseSeconds = 0;
      });
      return;
    }

    final now = DateTime.now();
    final lastDay = DateTime(
      lastSession.end.year,
      lastSession.end.month,
      lastSession.end.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    if (lastDay != today) {
      // Día nuevo → empezamos de cero
      setState(() {
        _baseSeconds = 0;
      });
    } else {
    // Mismo día → usamos acumulado persistido
      setState(() {
        _baseSeconds = lastSession.accumulatedSecs;
      });
    }
  }

  void _start(){
    if (_running) return;
    setState(() {
      _sessionStart ??= DateTime.now();
      _running = true;
    });
    
    _timer= Timer.periodic(const Duration(seconds:1),(timer){
      setState(() {});
    });

  }

  void _pause() async{
    if (!_running|| _sessionStart==null) return;
    _timer?.cancel();
    final now = DateTime.now();
    final sessionSeconds =now.difference(_sessionStart!).inSeconds;
    final accumulated = _baseSeconds + sessionSeconds;
    setState(() {
      _running=false;
      _baseSeconds = accumulated;
      _sessionStart = null;
      });
    final session=Session(
      activityId:widget.activityId, 
      start:now.subtract(Duration(seconds: sessionSeconds)), 
      end: now, 
      durationSecs: sessionSeconds,
      accumulatedSecs: accumulated
    );
    await SessionDao().insert(session);
  }

  void _reset() async{
    _timer?.cancel();

    if (_baseSeconds == 0) return;

    final now = DateTime.now();

    final resetSession = Session(
      activityId: widget.activityId,
      start: now,
      end: now,
      durationSecs: -_baseSeconds,
      accumulatedSecs: 0,
    );

    await SessionDao().insert(resetSession);

    setState(() {
      _baseSeconds = 0;
      _running = false;
      _sessionStart = null;
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
      final now=DateTime.now();
      final sessionSeconds =now.difference(_sessionStart!).inSeconds;
      final accumulated = _baseSeconds + sessionSeconds;
      final session=Session(
        activityId: widget.activityId,
        start: _sessionStart!,
        end:DateTime.now(),
        durationSecs: sessionSeconds,
        accumulatedSecs: accumulated
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
        SizedBox(height: 10),
        ElevatedButton(onPressed: ()=>showAddTimeDialog(context), child: const Text ("Añadir tiempo"))
      ],
    );
   }
   
  Future<void> showAddTimeDialog(BuildContext context) async{
    final controller= TextEditingController();
    final result= await showDialog<int>(
      context: context,
      builder: (context)=> AlertDialog(
        title: const Text("Añadir tiempo"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutos'
          )
        ),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text ("Cancelar")),
          ElevatedButton(onPressed: (){
            final minutes = int.tryParse(controller.text);
            if (minutes!=null && minutes>0){
              Navigator.pop(context,minutes);
            }
          },
          child: const Text("Añadir")
          )
        ],
      )
    );
    if (result!=null){
      await addManualSession(result);
    }
  }

  Future<void> addManualSession(int minutes) async {
    final now = DateTime.now();
    final added = minutes * 60;
    final accumulated = _baseSeconds + added;

    final session = Session(
      activityId: widget.activityId,
      start: now,
      end: now,
      durationSecs: added,
      accumulatedSecs: accumulated,
    );

    await SessionDao().insert(session);

    setState(() {
      _baseSeconds = accumulated;
    });// refresca totales
  }
}