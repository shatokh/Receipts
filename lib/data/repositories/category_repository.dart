import 'package:receipts/data/database.dart';
import 'package:receipts/domain/category_definitions.dart';
import 'package:receipts/domain/models/category.dart';
import 'package:receipts/domain/models/monthly_total.dart';

class CategoryRepository {
  Future<List<Category>> getAllCategories() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('categories', orderBy: 'name');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategory(String id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<List<CategoryMonthTotal>> getTopCategoriesForMonth(int year, int month,
      {int limit = 5}) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'category_month_totals',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'total DESC',
      limit: limit,
    );
    return maps.map((map) => CategoryMonthTotal.fromMap(map)).toList();
  }

  Future<double> getTotalForMonth(int year, int month) async {
    final db = await DatabaseHelper.database;
    final result = await db.query(
      'monthly_totals',
      columns: ['total'],
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );

    if (result.isEmpty) return 0.0;
    return result.first['total'] as double;
  }

  Future<int> getReceiptCountForMonth(int year, int month) async {
    final db = await DatabaseHelper.database;
    final startOfMonth = DateTime(year, month).millisecondsSinceEpoch;
    final startOfNextMonth = DateTime(year, month + 1).millisecondsSinceEpoch;

    final result = await db.query(
      'receipts',
      columns: ['COUNT(*) as count'],
      where: 'purchase_ts >= ? AND purchase_ts < ?',
      whereArgs: [startOfMonth, startOfNextMonth],
    );

    return result.first['count'] as int;
  }

  Future<String> categorizeName(String itemName) async {
    return categorizeItemName(itemName);
  }
}
