import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_screen.dart';
import '../db/activity_dao.dart';
import '../services/stat_service.dart';
import 'activities_list_screen.dart';
import 'insight_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StatService _statService = StatService();

  List<Activity> _todayActivities = [];
  bool _loading = true;

  Future<void> _loadTodayActivities() async {
    final allActiveActivities = await ActivityDao().getActive();
    final today = DateTime.now().weekday - 1;

    final filtered = allActiveActivities
        .where((a) => a.daysWeek.contains(today))
        .toList();

    setState(() {
      _todayActivities = filtered;
      _loading = false;
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
      backgroundColor: Colors.white, // fondo blanco
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Hoy',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActivitiesListScreen(),
                )
              );
              _loadTodayActivities();
            },
            icon: const Icon(Icons.list, color: Colors.black),
          ),
          IconButton(
            onPressed: () async{
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_)=>const InsightScreen(),
                )
              );
            _loadTodayActivities();
            },
            icon: const Icon(Icons.bar_chart, color: Colors.black))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _todayActivities.isEmpty
              ? const Center(
                  child: Text(
                    'No hay actividades para hoy',
                    style: TextStyle(color: Colors.black),
                  ),
                )
              : ListView.builder(
                  itemCount: _todayActivities.length,
                  itemBuilder: (_, i) {
                    final activity = _todayActivities[i];

                    return FutureBuilder<Map<String, dynamic>>(
                      future: _statService.getTodayStats(activity.id!, activity.objetiveMinutes),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final stats = snapshot.data!;
                        final todaySeconds = stats['todaySeconds'] as int;
                        final completed = stats['completed'] as bool;
                        final streak = stats['streak'] as int;
                        final progress = stats['progress'] as double;

                        return InkWell(
                          onTap: () async{
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActivityScreen(activity: activity),
                              ),
                            );
                            _loadTodayActivities();
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Info de actividad (nombre, barra y racha)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activity.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: progress,
                                          color: Colors.blue,
                                          backgroundColor: Colors.grey[300],
                                          minHeight: 8,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Hoy: ${todaySeconds ~/ 60} min de ${activity.objetiveMinutes} min • Racha: $streak días',
                                          style: const TextStyle(color: Colors.black, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Checkbox a la derecha
                                  Transform.scale(
                                    scale: 1.5,
                                    child: Checkbox(
                                      value: completed,
                                      onChanged: null, // deshabilitado, solo indicador
                                      fillColor: MaterialStateProperty.resolveWith<Color?>(
                                        (states) {
                                          if (completed) return Colors.blue;
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}