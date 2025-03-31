import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'global.dart';

class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  State<Analytics> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  @override
  Widget build(BuildContext context) {
    final barGroups = Global.getBarChartGroups();
    List<String> months = [];
    for (var tx in transactions) {
      DateTime date = DateTime.parse(tx['date']);
      int month = date.month;
      int year = date.year;
      String label = '$month-$year';
      if (!months.contains(label)) {
        months.add('${Global.getMonthName(month)}');
      }
    }
    final double maxY =
        barGroups.isNotEmpty
            ? barGroups
                    .map((group) => group.barRods.first.toY)
                    .reduce((a, b) => a > b ? a : b) *
                1.2
            : 0.0;
    return Column(
      children: [
        Row(
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 1, 12, 22),
              ),
              onPressed: () {
                setState(() {
                  graphplot(maxY, barGroups, months, "Monthly Expense");
                });
              },
              child: const Text('Month'),
            ),
          ],
        ),
      ],
    );
  }

  Container graphplot(
    double maxY,
    List<BarChartGroupData> barGroups,
    List<String> months,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barGroups: barGroups,
                backgroundColor: Colors.grey[200],
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize:
                          40, // Increased reserved size for more space
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= months.length)
                          return Container();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            months[index],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: true),
                alignment: BarChartAlignment.spaceAround,
              ),
              swapAnimationDuration: const Duration(milliseconds: 250),
            ),
          ),
          // ...existing code or additional widgets...
        ],
      ),
    );
  }
}
