import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""
    Create table notes(
      id integer primary key autoincrement not null,
      title text,
      description,
      createAt Timestamp not null default current_timestamp
      )
    """);
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase('notesdb.db', version: 1,
        onCreate: (sql.Database database, int version) async {
      await createTables(database);
    });
  }

  //create new note
  static Future<int> createItem(String title, String description) async {
    final db = await SQLHelper.db();
    final data = {'title': title, 'description': description};
    final id = await db.insert('notes', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  //read all items (note)
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SQLHelper.db();
    return db.query('notes', orderBy: "id");
  }

  //read a single item by id
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('notes', where: "id = ?", whereArgs: [id], limit: 1);
  }

  //search by title
  static Future<List<Map<String, dynamic>>> searchItem(String data) async {
    final db = await SQLHelper.db();
    return db.query('notes', where: "title like ?", whereArgs: ['%$data%']);
  }

  //Update an item by id
  static Future<int> updateItem(
      int id, String title, String description) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'description': description,
      'createAt': DateTime.now().toString()
    };

    final result =
        await db.update('notes', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  //Delete
  static Future<void> deleteItem(int id) async {
    final db = await SQLHelper.db();

    try {
      await db.delete('notes', where: "id = ?", whereArgs: [id]);
    } catch (e) {
      debugPrint("Something went wrong when deleting an item: $e");
    }
  }
}
