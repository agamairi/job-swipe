import 'dart:async';
import 'package:job_swipe/models/user_model.dart';
import 'package:job_swipe/models/job_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'userprofile.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await _createUserProfileTable(db);
    await _createJobsTable(db);
    await _createSearchHistoryTable(db);
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createJobsTable(db);
      await _createSearchHistoryTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE jobs ADD COLUMN searchQuery TEXT');
      await db.execute('ALTER TABLE jobs ADD COLUMN locationFilter TEXT');
      await db.execute('ALTER TABLE jobs ADD COLUMN dateFilter TEXT');
    }
  }

  Future<void> _createUserProfileTable(Database db) async {
    await db.execute('''
      CREATE TABLE userProfile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        education TEXT,
        workExperience TEXT,
        resumePath TEXT
      )
    ''');
  }

  Future<void> _createJobsTable(Database db) async {
    await db.execute('''
      CREATE TABLE jobs (
        id TEXT PRIMARY KEY,
        title TEXT,
        company TEXT,
        logoUrl TEXT,
        description TEXT,
        location TEXT,
        salary TEXT,
        datePosted TEXT,
        source TEXT,
        applyLink TEXT,
        status TEXT,
        searchQuery TEXT,
        locationFilter TEXT,
        dateFilter TEXT
      )
    ''');
  }

  Future<void> _createSearchHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT,
        locationFilter TEXT,
        dateFilter TEXT,
        nextPageUrl TEXT,
        timestamp INTEGER
      )
    ''');
  }

  // --- User Profile ---

  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert('userProfile', profile.toMap());
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.update(
      'userProfile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('userProfile', limit: 1);
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  // --- Jobs ---

  Future<void> insertCachedJobs(List<Job> jobs, String query, String locationFilter, String dateFilter) async {
    final db = await database;
    final batch = db.batch();
    for (var job in jobs) {
      final data = job.toJson();
      data['status'] = 'cached';
      data['searchQuery'] = query;
      data['locationFilter'] = locationFilter;
      data['dateFilter'] = dateFilter;
      // Use insert with conflict algorithm ignore to not override user's saved/applied/discarded jobs
      batch.insert('jobs', data, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Job>> getCachedJobs(String query, String locationFilter, String dateFilter) async {
    final db = await database;
    final maps = await db.query(
      'jobs',
      where: 'status = ? AND searchQuery = ? AND locationFilter = ? AND dateFilter = ?',
      whereArgs: ['cached', query, locationFilter, dateFilter],
    );
    return maps.map((e) => Job.fromJson(e)).toList();
  }

  Future<List<Job>> getJobsByStatus(String status) async {
    final db = await database;
    final maps = await db.query('jobs', where: 'status = ?', whereArgs: [status]);
    return maps.map((e) => Job.fromJson(e)).toList();
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    final db = await database;
    await db.update(
      'jobs',
      {'status': status},
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }

  Future<void> clearCachedJobs({String? query, String? locationFilter, String? dateFilter}) async {
    final db = await database;
    if (query != null && locationFilter != null && dateFilter != null) {
      await db.delete(
        'jobs',
        where: 'status = ? AND searchQuery = ? AND locationFilter = ? AND dateFilter = ?',
        whereArgs: ['cached', query, locationFilter, dateFilter],
      );
    } else {
      await db.delete('jobs', where: 'status = ?', whereArgs: ['cached']);
    }
  }

  Future<void> clearJobsByStatus(String status) async {
    final db = await database;
    await db.delete('jobs', where: 'status = ?', whereArgs: [status]);
  }

  Future<void> deleteJob(String jobId) async {
    final db = await database;
    await db.delete('jobs', where: 'id = ?', whereArgs: [jobId]);
  }

  Future<void> restoreJob(Job job, String status) async {
    final db = await database;
    final data = job.toJson();
    data['status'] = status;
    await db.insert('jobs', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Search History ---

  Future<void> saveSearchHistory(String query, String locationFilter, String dateFilter, String? nextPageUrl) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Clear old history for the same query just in case, or we can just append
    await db.delete('search_history', where: 'query = ? AND locationFilter = ? AND dateFilter = ?', whereArgs: [query, locationFilter, dateFilter]);

    await db.insert('search_history', {
      'query': query,
      'locationFilter': locationFilter,
      'dateFilter': dateFilter,
      'nextPageUrl': nextPageUrl,
      'timestamp': timestamp,
    });
  }

  Future<Map<String, dynamic>?> getRecentSearchHistory(String query, String locationFilter, String dateFilter) async {
    final db = await database;
    final maps = await db.query(
      'search_history',
      where: 'query = ? AND locationFilter = ? AND dateFilter = ?',
      whereArgs: [query, locationFilter, dateFilter],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final data = maps.first;
      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      // If within 24 hours (86400000 ms)
      if (now - timestamp < 86400000) {
        return data;
      }
    }
    return null;
  }
}
