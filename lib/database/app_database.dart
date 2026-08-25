import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/shopping_item.dart';
import '../models/user_profile.dart';
import '../models/member.dart';
import '../models/custom_category.dart';
import '../models/category_item.dart';

/// SQLite local database — extensible schema.
/// To add a new table, increment [_dbVersion] and add a case in [_onUpgrade].
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'shopping_app.db';

  /// Version history:
  ///   1 → initial schema
  ///   2 → add feedback table
  ///   3 → relax email NOT NULL, add phone_number, subscription_tier, auth_methods
  ///   4 → add input_method to shopping_items
  ///   5 → add categories column to shopping_items (multi-category, paid feature)
  ///   6 → add invitations table for email-invite flow
  ///   7 → add gender column to users table
  ///   8 → add custom_categories and category_items tables
  static const int _dbVersion = 8;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (kIsWeb) {
      // sqflite_common_ffi_web must be initialised before use on web.
      // This is handled in main.dart via databaseFactory override.
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ─── Schema creation ────────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    // ── Users: email and phone are both nullable to support multiple auth
    //          methods (Google, Phone OTP) on the same account.
    await db.execute('''
      CREATE TABLE users (
        id                TEXT PRIMARY KEY,
        email             TEXT,
        phone_number      TEXT,
        display_name      TEXT,
        photo_url         TEXT,
        list_id           TEXT,
        gender            TEXT,
        created_at        INTEGER,
        last_seen         INTEGER,
        subscription_tier TEXT
      )
    ''');

    // ── Auth methods: tracks HOW each user can sign in.
    //   provider     = 'google' | 'phone'
    //   provider_id  = Google sub/UID  OR  E.164 phone number (+91XXXXXXXXXX)
    //   Populated now so phone login can be added later without DB migration.
    await db.execute('''
      CREATE TABLE auth_methods (
        id          TEXT PRIMARY KEY,
        user_id     TEXT NOT NULL,
        provider    TEXT NOT NULL,
        provider_id TEXT NOT NULL,
        linked_at   INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_items (
        id                TEXT PRIMARY KEY,
        list_id           TEXT NOT NULL,
        name              TEXT NOT NULL,
        category          TEXT,
        categories        TEXT,
        added_by          TEXT,
        added_by_name     TEXT,
        added_at          INTEGER,
        completed         INTEGER DEFAULT 0,
        completed_at      INTEGER,
        completed_by_name TEXT,
        notes             TEXT,
        quantity          INTEGER,
        unit              TEXT,
        input_method      TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE members (
        id               TEXT PRIMARY KEY,
        list_id          TEXT,
        user_id          TEXT,
        email            TEXT,
        display_name     TEXT,
        photo_url        TEXT,
        invited_at       INTEGER,
        status           TEXT DEFAULT 'pending',
        invited_by       TEXT,
        invited_by_name  TEXT
      )
    ''');

    /// General key-value settings table.
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE feedback (
        id           TEXT PRIMARY KEY,
        user_id      TEXT NOT NULL,
        user_email   TEXT,
        message      TEXT NOT NULL,
        submitted_at INTEGER NOT NULL,
        synced       INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE invitations (
        id               TEXT PRIMARY KEY,
        list_id          TEXT NOT NULL,
        list_name        TEXT,
        invited_by_name  TEXT,
        recipient_email  TEXT NOT NULL,
        status           TEXT NOT NULL DEFAULT 'pending',
        created_at       INTEGER,
        expires_at       INTEGER
      )
    ''');
  }

  // ─── Migrations ─────────────────────────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: add feedback table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS feedback (
          id           TEXT PRIMARY KEY,
          user_id      TEXT NOT NULL,
          user_email   TEXT,
          message      TEXT NOT NULL,
          submitted_at INTEGER NOT NULL,
          synced       INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      // v2 → v3: relax email constraint, add phone_number & subscription_tier,
      //          add auth_methods table.
      // SQLite cannot drop NOT NULL in-place, so recreate users table.
      await db.execute('ALTER TABLE users RENAME TO users_old');
      await db.execute('''
        CREATE TABLE users (
          id                TEXT PRIMARY KEY,
          email             TEXT,
          phone_number      TEXT,
          display_name      TEXT,
          photo_url         TEXT,
          list_id           TEXT,
          created_at        INTEGER,
          last_seen         INTEGER,
          subscription_tier TEXT
        )
      ''');
      await db.execute('''
        INSERT INTO users (id, email, display_name, photo_url, list_id,
                           created_at, last_seen)
        SELECT id, email, display_name, photo_url, list_id,
               created_at, last_seen
        FROM users_old
      ''');
      await db.execute('DROP TABLE users_old');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS auth_methods (
          id          TEXT PRIMARY KEY,
          user_id     TEXT NOT NULL,
          provider    TEXT NOT NULL,
          provider_id TEXT NOT NULL,
          linked_at   INTEGER,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');
    }
    if (oldVersion < 4) {
      // v3 → v4: add input_method to shopping_items for voice vs manual tracking
      await db.execute(
        'ALTER TABLE shopping_items ADD COLUMN input_method TEXT',
      );
    }
    if (oldVersion < 5) {
      // v4 → v5: add categories column to shopping_items.
      // Stores a comma-separated list of category names, e.g. "Grocery,Health & Beauty".
      // This enables multi-category support (paid feature).
      // The legacy `category` column is kept intact for backward compatibility.
      // On read, if `categories` is populated it takes precedence over `category`.
      await db.execute(
        'ALTER TABLE shopping_items ADD COLUMN categories TEXT',
      );
    }
    if (oldVersion < 6) {
      // v5 → v6: add invitations table for email-invite flow.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS invitations (
          id               TEXT PRIMARY KEY,
          list_id          TEXT NOT NULL,
          list_name        TEXT,
          invited_by_name  TEXT,
          recipient_email  TEXT NOT NULL,
          status           TEXT NOT NULL DEFAULT 'pending',
          created_at       INTEGER,
          expires_at       INTEGER
        )
      ''');
    }
    if (oldVersion < 7) {
      // v6 → v7: add gender column to users table.
      // SQLite ALTER TABLE ADD COLUMN supports nullable columns with no default.
      await db.execute(
        'ALTER TABLE users ADD COLUMN gender TEXT',
      );
    }
    if (oldVersion < 8) {
      // v7 → v8: add custom_categories and category_items tables for template management.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_categories (
          id           TEXT PRIMARY KEY,
          user_id      TEXT NOT NULL,
          name         TEXT NOT NULL,
          emoji        TEXT NOT NULL,
          color_hex    TEXT NOT NULL,
          created_at   INTEGER NOT NULL,
          updated_at   INTEGER,
          item_count   INTEGER DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_custom_categories_user
        ON custom_categories(user_id)
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS category_items (
          id           TEXT PRIMARY KEY,
          category_id  TEXT NOT NULL,
          user_id      TEXT NOT NULL,
          name         TEXT NOT NULL,
          notes        TEXT,
          quantity     INTEGER,
          unit         TEXT,
          created_at   INTEGER NOT NULL,
          FOREIGN KEY (category_id) REFERENCES custom_categories(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_category_items_category
        ON category_items(category_id)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_category_items_user
        ON category_items(user_id)
      ''');
    }
  }

  // ─── User operations ────────────────────────────────────────────────────────

  Future<void> upsertUser(UserProfile user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfile?> getUser(String id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
    await db.delete('auth_methods', where: 'user_id = ?', whereArgs: [id]);
  }

  // ─── Auth method operations ──────────────────────────────────────────────────

  Future<void> upsertAuthMethod({
    required String id,
    required String userId,
    required String provider,
    required String providerId,
  }) async {
    final db = await database;
    await db.insert(
      'auth_methods',
      {
        'id': id,
        'user_id': userId,
        'provider': provider,
        'provider_id': providerId,
        'linked_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAuthMethodsForUser(
      String userId) async {
    final db = await database;
    return db.query('auth_methods',
        where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> deleteAuthMethodsForUser(String userId) async {
    final db = await database;
    await db.delete('auth_methods', where: 'user_id = ?', whereArgs: [userId]);
  }

  // ─── Shopping item operations ────────────────────────────────────────────────

  Future<void> upsertItem(ShoppingItem item) async {
    final db = await database;
    await db.insert(
      'shopping_items',
      item.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ShoppingItem>> getItemsForList(String listId) async {
    final db = await database;
    final rows = await db.query(
      'shopping_items',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'added_at DESC',
    );
    return rows.map(ShoppingItem.fromMap).toList();
  }

  Future<void> updateItemCompletion(
    String itemId, {
    required bool completed,
    DateTime? completedAt,
    String? completedByName,
  }) async {
    final db = await database;
    await db.update(
      'shopping_items',
      {
        'completed': completed ? 1 : 0,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'completed_by_name': completedByName,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> deleteItem(String itemId) async {
    final db = await database;
    await db.delete('shopping_items', where: 'id = ?', whereArgs: [itemId]);
  }

  Future<void> deleteAllItemsForList(String listId) async {
    final db = await database;
    await db.delete('shopping_items', where: 'list_id = ?', whereArgs: [listId]);
  }

  // ─── Member operations ────────────────────────────────────────────────────

  Future<void> upsertMember(Member member) async {
    final db = await database;
    await db.insert(
      'members',
      member.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Member>> getMembersForList(String listId) async {
    final db = await database;
    final rows = await db.query(
      'members',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'invited_at ASC',
    );
    return rows.map(Member.fromMap).toList();
  }

  Future<void> deleteMember(String memberId) async {
    final db = await database;
    await db.delete('members', where: 'id = ?', whereArgs: [memberId]);
  }

  Future<void> deleteMembersForList(String listId) async {
    final db = await database;
    await db.delete('members', where: 'list_id = ?', whereArgs: [listId]);
  }

  // ─── Settings operations ─────────────────────────────────────────────────

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  // ─── Feedback operations ─────────────────────────────────────────────────

  Future<void> insertFeedback({
    required String id,
    required String userId,
    String? userEmail,
    required String message,
    required DateTime submittedAt,
  }) async {
    final db = await database;
    await db.insert(
      'feedback',
      {
        'id': id,
        'user_id': userId,
        'user_email': userEmail,
        'message': message,
        'submitted_at': submittedAt.millisecondsSinceEpoch,
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsynedFeedback() async {
    final db = await database;
    return db.query('feedback', where: 'synced = 0', orderBy: 'submitted_at DESC');
  }

  Future<void> markFeedbackSynced(String id) async {
    final db = await database;
    await db.update('feedback', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ─── Invitation operations ────────────────────────────────────────────────

  Future<void> upsertInvitation(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'invitations',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteInvitation(String id) async {
    final db = await database;
    await db.delete('invitations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteInvitationsForList(String listId) async {
    final db = await database;
    await db.delete('invitations', where: 'list_id = ?', whereArgs: [listId]);
  }

  Future<List<Map<String, dynamic>>> getPendingInvitations(
      String recipientEmail) async {
    final db = await database;
    return db.query(
      'invitations',
      where: 'recipient_email = ? AND status = ?',
      whereArgs: [recipientEmail.toLowerCase(), 'pending'],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> clearInvitations() async {
    final db = await database;
    await db.delete('invitations');
  }

  // ─── Utility ─────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('shopping_items');
    await db.delete('members');
    await db.delete('settings');
    await db.delete('invitations');
    await db.delete('category_items');
    await db.delete('custom_categories');
  }

  // ─── Custom category operations ──────────────────────────────────────────

  Future<void> upsertCustomCategory(CustomCategory category) async {
    final db = await database;
    await db.insert(
      'custom_categories',
      category.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CustomCategory>> getCustomCategoriesForUser(String userId) async {
    final db = await database;
    final rows = await db.query(
      'custom_categories',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(CustomCategory.fromMap).toList();
  }

  Future<CustomCategory?> getCustomCategory(String categoryId) async {
    final db = await database;
    final rows = await db.query(
      'custom_categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    if (rows.isEmpty) return null;
    return CustomCategory.fromMap(rows.first);
  }

  Future<void> deleteCustomCategory(String categoryId) async {
    final db = await database;
    // Cascade delete is handled by foreign key constraint
    await db.delete('custom_categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  Future<void> updateCustomCategoryItemCount(String categoryId, int count) async {
    final db = await database;
    await db.update(
      'custom_categories',
      {'item_count': count, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  // ─── Category item operations ────────────────────────────────────────────

  Future<void> upsertCategoryItem(CategoryItem item) async {
    final db = await database;
    await db.insert(
      'category_items',
      item.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CategoryItem>> getCategoryItems(String categoryId) async {
    final db = await database;
    final rows = await db.query(
      'category_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'created_at DESC',
    );
    return rows.map(CategoryItem.fromMap).toList();
  }

  Future<void> deleteCategoryItem(String itemId) async {
    final db = await database;
    await db.delete('category_items', where: 'id = ?', whereArgs: [itemId]);
  }

  Future<void> deleteAllCategoryItems(String categoryId) async {
    final db = await database;
    await db.delete('category_items', where: 'category_id = ?', whereArgs: [categoryId]);
  }

  Future<int> getCategoryItemCount(String categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM category_items WHERE category_id = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}