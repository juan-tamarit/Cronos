import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../widgets/cronometro_widget.dart';
import '../services/stat_service.dart';

class ActivityScreen extends StatelessWidget {
  final Activity activity;
  final StatService _statService = StatService();

  ActivityScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          activity.name,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.description,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Objetivo diario: ${activity.objetiveMinutes} minutos',
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 32),

              // 🔵 CRONÓMETRO
              Center(
                child: CronometroWidget(
                  objetiveMinutes: activity.objetiveMinutes,
                  activityId: activity.id!,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Resumen de la semana',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              FutureBuilder(
                future: Future.wait([
                  _statService.getCurrentWeekTotal(activity.id!),
                  _statService.getCurrentWeekDailyTotals(activity.id!)
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final totalWeekSeconds = snapshot.data![0] as int;
                  final dailyTotals = snapshot.data![1] as List<int>;

                  final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

                  final objectiveSeconds = activity.objetiveMinutes * 60;
                  final maxDaySeconds =
                      dailyTotals.reduce((a, b) => a > b ? a : b);

                  final maxScale =
                      maxDaySeconds > objectiveSeconds
                          ? maxDaySeconds
                          : objectiveSeconds;

                  final todayIndex = DateTime.now().weekday - 1;

                  final weeklyObjective = objectiveSeconds * 7;
                  final weeklyPercentage =
                      weeklyObjective == 0
                          ? 0
                          : (totalWeekSeconds / weeklyObjective) * 100;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiempo total esta semana: ${totalWeekSeconds ~/ 60} min',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cumplimiento semanal: ${weeklyPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Column(
                        children: List.generate(7, (index) {
                          final seconds = dailyTotals[index];
                          final minutes = seconds ~/ 60;
                          final progress =
                              maxScale == 0 ? 0.0 : seconds / maxScale;

                          final isToday = index == todayIndex;
                          final exceeded = seconds >= objectiveSeconds;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 25,
                                  child: Text(
                                    days[index],
                                    style: TextStyle(
                                      color: isToday ? Colors.blue : Colors.black,
                                      fontWeight:
                                          isToday ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      // Línea objetivo
                                      if (maxScale > objectiveSeconds)
                                        Positioned(
                                          left: (objectiveSeconds / maxScale) *
                                              MediaQuery.of(context).size.width *
                                              0.6,
                                          child: Container(
                                            width: 2,
                                            height: 14,
                                            color: Colors.black26,
                                          ),
                                        ),

                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: progress.clamp(0.0, 1.0),
                                          minHeight: isToday ? 14 : 10,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            exceeded
                                                ? Colors.green
                                                : Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    '$minutes m',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}