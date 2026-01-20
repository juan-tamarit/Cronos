import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_screen.dart';
import '../db/activity_dao.dart';
import 'activities_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen ({super.key});
  @override
  State<HomeScreen> createState()=> _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen>{
  List<Activity> _todayActivities=[];
  bool _loading=true;
  
  Future <void> _loadTodayActivities() async{
    final allActiveActivities= await ActivityDao().getActive();
    final today= DateTime.now().weekday-1;

    final filtered=allActiveActivities.where((a){return a.daysWeek.contains(today);}).toList();
    setState(() {
      _todayActivities=filtered;
      _loading=false;
    });
  }
  @override
  void initState() {
    super.initState();
    _loadTodayActivities();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text ('Hoy'),
        actions: [
          IconButton(
            onPressed: ()async{
              await Navigator.push(context, MaterialPageRoute(builder: (_)=> const ActivitiesListScreen()));
              _loadTodayActivities();
            }, 
            icon: Icon(Icons.list)
          )
        ],
      ),
      body: _loading
      ? const Center(child:CircularProgressIndicator())
      :_todayActivities.isEmpty
        ? const Center(child: Text('No hay actividades para hoy'))
        : ListView.builder(
            itemCount: _todayActivities.length,
            itemBuilder: (_,i){
              final a= _todayActivities[i];
              return ListTile(
                title: Text(a.name),
                subtitle: Text('${a.objetiveMinutes} min'),
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (_)=>ActivityScreen(activity: a)));
                }
              );
            }
            )
    );
  }
}