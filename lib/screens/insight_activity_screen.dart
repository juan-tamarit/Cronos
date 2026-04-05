import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/activity.dart';
import '../models/period_type.dart';
import '../services/stat_service.dart';

class InsightActivityScreen extends StatefulWidget {
  final Activity activity;

  const InsightActivityScreen({super.key, required this.activity});

  @override
  State<InsightActivityScreen> createState() => _InsightActivityScreenState();
}

class _InsightActivityScreenState extends State<InsightActivityScreen> {
  final StatService _statService = StatService();

  PeriodType _selectedPeriod = PeriodType.week;

  List<int> _periodTotals = [];
  int _totalSeconds = 0;
  int _previousPeriodSeconds = 0;
  int _streak = 0;
  bool _completedToday = false;
  double _progress = 0.0;

  int _sessionsCount = 0;
  double _averageSessionDuration = 0;
  double _averageSessionsPerDay = 0;
  Map<int, int> _timeByWeekDay = {};
  double _weeklyProgress = 0.0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final activityId = widget.activity.id!;
    final objectiveMinutes = widget.activity.objetiveMinutes;

    List<int> totals;
    int totalSec = 0;
    int prevSec = 0;

    switch (_selectedPeriod) {
      case PeriodType.week:
        totals = await _statService.getCurrentWeekDailyTotals(activityId);
        totalSec = await _statService.getCurrentWeekTotal(activityId);
        prevSec = await _statService.getPreviousWeekTotal(activityId);
        break;
      case PeriodType.month:
        totals = await _statService.getCurrentMonthWeeklyTotals(activityId);
        totalSec = await _statService.getCurrentMonthTotal(activityId);
        prevSec = await _statService.getPreviousMonthTotal(activityId);
        break;
      case PeriodType.threeMonths:
        totals = await _statService.getLastNMonthsTotals(activityId, 3);
        totalSec = totals.reduce((a, b) => a + b);
        prevSec = 0;
        break;
      case PeriodType.sixMonths:
        totals = await _statService.getLastNMonthsTotals(activityId, 6);
        totalSec = totals.reduce((a, b) => a + b);
        prevSec = 0;
        break;
      case PeriodType.year:
        totals = await _statService.getLastNMonthsTotals(activityId, 12);
        totalSec = totals.reduce((a, b) => a + b);
        prevSec = 0;
        break;
    }

    final streak = await _statService.getCurrentStreak(activityId, objectiveMinutes);
    final todayStats = await _statService.getTodayStats(activityId, objectiveMinutes);
    final currentWeekSeconds = await _statService.getCurrentWeekTotal(activityId);
    final weeklyObjectiveSeconds = objectiveMinutes * 7 * 60;

    final sessionsCount = await _statService.getSessionsCount(activityId);
    final avgSessionDuration = await _statService.getAverageSessionDuration(activityId);
    final avgSessionsPerDay = await _statService.getAverageSessionPerDay(activityId);
    final timeByWeekDay = await _statService.getTimeByWeekDay(activityId);

    setState(() {
      _periodTotals = totals;
      _totalSeconds = totalSec;
      _previousPeriodSeconds = prevSec;
      _streak = streak;
      _completedToday = todayStats['completed'] as bool;
      _progress = todayStats['progress'] as double;
      _weeklyProgress = weeklyObjectiveSeconds == 0
          ? 0.0
          : (currentWeekSeconds / weeklyObjectiveSeconds).clamp(0.0, 1.0);
      _sessionsCount = sessionsCount;
      _averageSessionDuration = avgSessionDuration;
      _averageSessionsPerDay = avgSessionsPerDay;
      _timeByWeekDay = timeByWeekDay;
      _isLoading = false;
    });
  }

  Color _getComparisonColor(int current, int previous) {
    if (previous == 0) return Colors.blue;
    if (current > previous) return Colors.green;
    if (current < previous) return Colors.red;
    return Colors.blue;
  }

  String _periodLabel(PeriodType type) {
    switch (type) {
      case PeriodType.week:
        return "Semana";
      case PeriodType.month:
        return "Mes";
      case PeriodType.threeMonths:
        return "3M";
      case PeriodType.sixMonths:
        return "6M";
      case PeriodType.year:
        return "Año";
    }
  }

  List<String> _chartLabels() {
    switch (_selectedPeriod) {
      case PeriodType.week:
        return const ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
      case PeriodType.month:
        return const ['S1', 'S2', 'S3', 'S4'];
      case PeriodType.threeMonths:
        return const ['1', '2', '3'];
      case PeriodType.sixMonths:
        return const ['1', '2', '3', '4', '5', '6'];
      case PeriodType.year:
        return const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          widget.activity.name,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),
                  _buildChart(),
                  const SizedBox(height: 32),
                  _buildStats(),
                  const SizedBox(height: 32),
                  _buildAdvancedStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PeriodType.values.map((period) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _periodLabel(period),
                style: const TextStyle(color: Colors.black),
              ),
              selectedColor: Colors.blue,
              selected: period == _selectedPeriod,
              onSelected: (_) async {
                setState(() => _selectedPeriod = period);
                await _loadData();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    if (_periodTotals.isEmpty) {
      return const SizedBox(height: 220);
    }

    final labels = _chartLabels();
    final maxMinutes = _periodTotals.map((e) => e / 60).reduce((a, b) => a > b ? a : b);
    final maxY = maxMinutes <= 0 ? 10.0 : (maxMinutes * 1.2).ceilToDouble();
    final interval = (maxY / 5).ceilToDouble().clamp(1, double.infinity).toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 10 : maxY,
          barGroups: List.generate(_periodTotals.length, (index) {
            final minutes = _periodTotals[index] / 60;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: minutes,
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.blue,
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final color = _getComparisonColor(_totalSeconds, _previousPeriodSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Estadísticas",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text("Racha actual: $_streak días", style: const TextStyle(color: Colors.black)),
        const SizedBox(height: 8),
        Text(
          "Tiempo total: ${(_totalSeconds / 60).round()} min",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _weeklyProgress,
          color: Colors.blue,
          backgroundColor: Colors.blue.withOpacity(0.2),
        ),
        const SizedBox(height: 8),
        Text(
          "Completado hoy: ${_completedToday ? 'Sí' : 'No'}",
          style: const TextStyle(color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildAdvancedStats() {
    final weeklyMinutes =
        List.generate(7, (i) => (_timeByWeekDay[i + 1] ?? 0) / 60);
    final maxWeeklyMinutes = weeklyMinutes.reduce((a, b) => a > b ? a : b);
    const maxBarHeight = 64.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detalles avanzados",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text("Sesiones totales: $_sessionsCount", style: const TextStyle(color: Colors.black)),
        const SizedBox(height: 4),
        Text("Duración media sesión: ${_averageSessionDuration.round()} min",
            style: const TextStyle(color: Colors.black)),
        const SizedBox(height: 4),
        Text("Media sesiones/día: ${_averageSessionsPerDay.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.black)),
        const SizedBox(height: 12),
        const Text("Distribución semanal:", style: TextStyle(color: Colors.black)),
        SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final minutes = weeklyMinutes[i];
              final normalizedHeight = maxWeeklyMinutes <= 0
                  ? 4.0
                  : ((minutes / maxWeeklyMinutes) * maxBarHeight).clamp(
                      4.0,
                      maxBarHeight,
                    );
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 20,
                    height: maxBarHeight,
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Container(
                      width: 20,
                      height: normalizedHeight,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ["L","M","X","J","V","S","D"][i],
                    style: const TextStyle(fontSize: 10, color: Colors.black),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
