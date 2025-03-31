import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

List<Map<int, DateTime>> ts = [];
List<Map<String, dynamic>> transactions = [];

class Global {
  // Returns monthly expense bar groups
  static List<BarChartGroupData> getBarChartGroups() {
    List<BarChartGroupData> barGroups = [];
    List<double> expenses = [];
    List<String> months = [];
    transactions.forEach((tx) {
      DateTime date = DateTime.parse(tx['date']);
      int month = date.month;
      int year = date.year;
      double amount = tx['amount'];
      int index = months.indexOf('$month-$year');
      if (index == -1) {
        months.add('$month-$year');
        expenses.add(amount);
      } else {
        expenses[index] += amount;
      }
    });
    for (int i = 0; i < months.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: expenses[i], color: Colors.blue)],
        ),
      );
      print("barGroups: $barGroups");
    }
    return barGroups;
  }

  // Returns a list of expenses grouped by category
  static List<CategoryExpense> getCategoryExpenses() {
    Map<String, double> dataMap = {};
    transactions.forEach((tx) {
      final String category = tx['category'] ?? 'Unknown';
      final double amount =
          (tx['amount'] is num) ? tx['amount'].toDouble() : 0.0;
      dataMap[category] = (dataMap[category] ?? 0) + amount;
    });
    return dataMap.entries.map((e) => CategoryExpense(e.key, e.value)).toList();
  }

  static String getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month - 1];
  }
}

class CategoryExpense {
  final String category;
  final double amount;
  CategoryExpense(this.category, this.amount);
}
