import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/activity.dart';
import '../models/period_type.dart';
import '../services/stat_service.dart';
import '../db/activity_dao.dart';
import 'insight_activity_screen.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final StatService _statService = StatService();
  final ActivityDao _activityDao = ActivityDao();

  PeriodType _selectedPeriod = PeriodType.week;

  List<Activity> _activities = [];
  List<int> _globalTotals = [];

  Map<int, int> _currentWeekTotals = {};
  Map<int, int> _previousWeekTotals = {};
  Map<int, int> _streaks = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final activities = await _activityDao.getAll();
    final totals =
        await _statService.getGlobalTotalsForPeriod(_selectedPeriod);

    Map<int, int> currentWeek = {};
    Map<int, int> previousWeek = {};
    Map<int, int> streaks = {};

    for (final activity in activities) {
      final id = activity.id!;
      currentWeek[id] = await _statService.getCurrentWeekTotal(id);
      previousWeek[id] = await _statService.getPreviousWeekTotal(id);
      streaks[id] =
          await _statService.getCurrentStreak(id, activity.objetiveMinutes);
    }

    setState(() {
      _activities = activities;
      _globalTotals = totals;
      _currentWeekTotals = currentWeek;
      _previousWeekTotals = previousWeek;
      _streaks = streaks;
      _isLoading = false;
    });
  }

  Color _getComparisonColor(int current, int previous) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Insights",
          style: TextStyle(color: Colors.black),
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
                  _buildActivitiesList(),
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
    if (_globalTotals.isEmpty) {
      return const SizedBox(height: 200);
    }

    final rawMax = _globalTotals.reduce((a, b) => a > b ? a : b) / 60;
    final interval = (rawMax / 4).ceilToDouble();
    final maxY = interval * 4;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 10 : maxY,
          barGroups: List.generate(_globalTotals.length, (index) {
            final minutes = _globalTotals[index] / 60;
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
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.black),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildActivitiesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Actividades",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ..._activities.map((activity) {
          final id = activity.id!;
          final current = _currentWeekTotals[id] ?? 0;
          final previous = _previousWeekTotals[id] ?? 0;
          final streak = _streaks[id] ?? 0;

          final minutes = (current / 60).round();
          final color = _getComparisonColor(current, previous);

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            child: ListTile(
              title: Text(
                activity.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                "Racha: $streak días",
                style: const TextStyle(color: Colors.black, fontSize: 12),
              ),
              trailing: Text(
                "$minutes min",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InsightActivityScreen(activity: activity),
                  ),
                ).then((_) => _loadData());
              },
            ),
          );
        }),
      ],
    );
  }
}