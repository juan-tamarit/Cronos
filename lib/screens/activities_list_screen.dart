import 'package:cronos/models/activity.dart';
import 'package:cronos/screens/activity_screen.dart';
import 'package:flutter/material.dart';
import '../db/activity_dao.dart';
import 'activity_form_screen.dart';

class ActivitiesListScreen extends StatefulWidget{
  const ActivitiesListScreen({super.key});

  @override
  State<ActivitiesListScreen> createState()=>_ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen>{
  final _dao=ActivityDao();
  List<Activity> _activities=[];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadActivites();
  }

  Future <void> _loadActivites() async{
    final list= await _dao.getAll();
    setState(() {
      _activities=list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actividades')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_)=> const ActivityFormScreen())
          );
          _loadActivites();
        },
        child:const Icon(Icons.add)
      ),
      body: ListView.builder(
        itemCount: _activities.length,
        itemBuilder: (_, i){
          final a = _activities[i];
          return ListTile(
            title: Text (a.name),
            subtitle: Text ('${a.objetiveMinutes} min'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children:[
                IconButton(onPressed:()=> _toggleActive(a) , icon: Icon(a.active?Icons.check_circle:Icons.pause_circle),color: a.active?Colors.green:Colors.red,),
                IconButton(onPressed:()=> _deleteActivity(a), icon: Icon(Icons.delete, color: Colors.red))
              ]
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_)=> ActivityScreen(activity: a))
              );
            },
            onLongPress: () async{
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_)=> ActivityFormScreen(activity: a))
              );
              _loadActivites();
            }
          );
        },
      )
    );
  }

  Future <void> _toggleActive(Activity a) async{
    final updated= a.copyWith(active: !a.active);
    await _dao.update(updated);
    _loadActivites();
  }

  Future<void> _deleteActivity(Activity a) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Eliminar actividad'),
      content: Text('¿Seguro que quieres eliminar "${a.name}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await _dao.delete(a.id!);
    _loadActivites();
  }
}
}