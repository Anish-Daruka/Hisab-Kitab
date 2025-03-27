import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

List<Map<int, DateTime>> ts = [];
List<Map<String, dynamic>> transactions = [];

class Global {
  static Map<String, double> getExpensesByCategory() {
    Map<String, double> dataMap = {};
    for (var tx in transactions) {
      final String category = tx['category'] ?? 'Unknown';
      final double amount =
          (tx['amount'] is num) ? tx['amount'].toDouble() : 0.0;
      dataMap[category] = (dataMap[category] ?? 0) + amount;
    }
    return dataMap;
  }

  static List<CategoryExpense> getCategoryExpenses() {
    final dataMap = getExpensesByCategory();
    return dataMap.entries.map((e) => CategoryExpense(e.key, e.value)).toList();
  }

  static List<BarChartGroupData> getBarChartGroups() {
    final chartData = getCategoryExpenses();
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < chartData.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: chartData[i].amount,
              color: Colors.blue,
              width: 22,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }
    return groups;
  }
}

class CategoryExpense {
  final String category;
  final double amount;
  CategoryExpense(this.category, this.amount);
}
