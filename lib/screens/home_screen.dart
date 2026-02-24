import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'activity_screen.dart';
import '../db/activity_dao.dart';
import '../services/stat_service.dart';
import 'activities_list_screen.dart';

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
                ),
              );
              _loadTodayActivities();
            },
            icon: const Icon(Icons.list, color: Colors.black),
          )
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
                      future: _statService.getTodayStats(
                          activity.id!, activity.objetiveMinutes),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return ListTile(
                            title: Text(activity.name, style: const TextStyle(color: Colors.black)),
                            subtitle: const LinearProgressIndicator(
                              color: Colors.blue,
                              backgroundColor: Colors.grey,
                              minHeight: 8,
                            ),
                          );
                        }

                        final stats = snapshot.data!;
                        final todaySeconds = stats['todaySeconds'] as int;
                        final completed = stats['completed'] as bool;
                        final streak = stats['streak'] as int;
                        final progress = stats['progress'] as double;

                        // checkbox estilo unicode
                        final checkbox = completed ? '☑' : '☐';

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          child: ListTile(
                            title: Text(
                              activity.name,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hoy: ${todaySeconds ~/ 60} min de ${activity.objetiveMinutes} min • Racha: $streak días',
                                  style: const TextStyle(fontSize: 12, color: Colors.black),
                                ),
                                Text(
                                  checkbox,
                                  style: const TextStyle(fontSize: 18, color: Colors.black),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ActivityScreen(activity: activity)));
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}