import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cronómetros'),),
      body: ListView.builder(
        itemCount: fakeActivities.length,
        itemBuilder: (context, index){
          final activity=fakeActivities[index];
          return ListTile(
            title: Text(activity.name),
            subtitle: Text('Objetivo: ${activity.objetiveMinutes} min'),
            trailing: const Icon(Icons.chevron_right),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (_)=>ActivityScreen(activity:activity),),);
            },
          );
        },
      ),
    );
  }
}


//Aún no tenemos datos guardados, creamos la lista para poder ver la representación
final List<Activity> fakeActivities =[
  Activity(
    id:1,
    name:'Leer',
    description: 'Tiempo dedicado a leer libros',
    objetiveMinutes: 30,
    daysWeek: [1,2,3,4,5,6,7]
  ),
  Activity(
    id:2,
    name:'Deporte',
    description:'Tiempo dedicado a correr o ir al gimnasio',
    objetiveMinutes:60,
    daysWeek:[1,2,3,4,5,7]
  )
];