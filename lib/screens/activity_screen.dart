import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../widgets/cronometro_widget.dart';

class ActivityScreen extends StatelessWidget{
  final Activity activity;
  
  const ActivityScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text(activity.name),),
      body:Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Text(activity.description,style: Theme.of(context).textTheme.bodyLarge,),
            const SizedBox(height:16),
            Text('Objetivo diario: ${activity.objetiveMinutes} minutos'),
            const SizedBox(height: 32),
            Center(
              child: CronometroWidget(objetiveMinutes: activity.objetiveMinutes,activityId: activity.id!,),
            ),
          ],
        ),
      ),
    );
  }
}