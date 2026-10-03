import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/account_statement_model.dart';
import '../models/expense_model.dart';
import '../models/financial_transaction_model.dart';
import '../models/owner_model.dart';

class FinancialRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- EXPENSES ---
  Future<List<ExpenseModel>> getAllExpenses({String? category}) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (category != null && category.isNotEmpty && category != 'all') {
      whereClause = 'category = ?';
      whereArgs = [category];
    }

    final res = await db.query(
      DatabaseTables.tableExpenses,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'expense_date DESC, id DESC',
    );
    return res.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final expenseId = await txn.insert(DatabaseTables.tableExpenses, expense.toMap());

      // Create linked financial transaction
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'expense',
        'category': expense.category,
        'owner_id': null,
        'pet_id': null,
        'reference_id': expenseId,
        'reference_type': 'expense',
        'amount': expense.amount,
        'paid_amount': expense.amount,
        'remaining_amount': 0.0,
        'payment_method': 'cash',
        'transaction_date': expense.expenseDate,
        'notes': expense.notes ?? expense.title,
      });

      return expenseId;
    });
  }

  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      await txn.delete(
        DatabaseTables.tableTransactions,
        where: 'reference_id = ? AND reference_type = ?',
        whereArgs: [id, 'expense'],
      );
      return await txn.delete(
        DatabaseTables.tableExpenses,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // --- TRANSACTIONS ---
  Future<List<FinancialTransactionModel>> getAllTransactions({
    int? ownerId,
    String? type,
    int limit = 100,
  }) async {
    final db = await _dbHelper.database;

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (ownerId != null) {
      whereConditions.add('t.owner_id = ?');
      whereArgs.add(ownerId);
    }

    if (type != null && type.isNotEmpty && type != 'all') {
      whereConditions.add('t.transaction_type = ?');
      whereArgs.add(type);
    }

    final whereStr = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(" AND ")}'
        : '';

    final sql = '''
      SELECT 
        t.*,
        o.full_name AS owner_name,
        o.phone_primary AS owner_phone,
        p.name AS pet_name
      FROM ${DatabaseTables.tableTransactions} t
      LEFT JOIN ${DatabaseTables.tableOwners} o ON t.owner_id = o.id
      LEFT JOIN ${DatabaseTables.tablePets} p ON t.pet_id = p.id
      $whereStr
      ORDER BY t.transaction_date DESC, t.id DESC
      LIMIT ?
    ''';

    whereArgs.add(limit);
    final res = await db.rawQuery(sql, whereArgs);
    return res.map((m) => FinancialTransactionModel.fromMap(m)).toList();
  }

  Future<int> insertTransaction(FinancialTransactionModel tx) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseTables.tableTransactions, tx.toMap());
  }

  /// Records a cash/transfer payment voucher (سند قبض) from an owner
  Future<int> recordClientPayment({
    required int ownerId,
    required double amount,
    int? petId,
    String paymentMethod = 'cash',
    String? notes,
    DateTime? date,
  }) async {
    final db = await _dbHelper.database;
    final now = date ?? DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return await db.insert(DatabaseTables.tableTransactions, {
      'transaction_type': 'payment',
      'category': 'direct_payment',
      'owner_id': ownerId,
      'pet_id': petId,
      'reference_id': null,
      'reference_type': 'voucher',
      'amount': amount,
      'paid_amount': amount,
      'remaining_amount': 0.0,
      'payment_method': paymentMethod,
      'transaction_date': dateStr,
      'notes': notes ?? 'سند قبض وتحصيل دفعة نقدية لحساب العميل',
    });
  }

  // --- FINANCIAL SUMMARY & KPIS ---
  Future<Map<String, dynamic>> getFinancialSummary() async {
    final db = await _dbHelper.database;

    // 1. Total income from transactions (paid amounts for income + payment)
    final incomeRes = await db.rawQuery('''
      SELECT 
        SUM(paid_amount) AS total_income,
        SUM(remaining_amount) AS total_uncollected
      FROM ${DatabaseTables.tableTransactions}
      WHERE transaction_type IN ('income', 'payment')
    ''');
    final totalIncome = (incomeRes.first['total_income'] as num?)?.toDouble() ?? 0.0;
    final totalDebtsFromTx = (incomeRes.first['total_uncollected'] as num?)?.toDouble() ?? 0.0;

    // 2. Total expenses
    final expenseRes = await db.rawQuery('''
      SELECT SUM(amount) AS total_expense FROM ${DatabaseTables.tableExpenses}
    ''');
    final totalExpenses = (expenseRes.first['total_expense'] as num?)?.toDouble() ?? 0.0;

    // 3. Consultations count & revenue
    final consultRes = await db.rawQuery('''
      SELECT COUNT(*) AS total_count, SUM(visit_cost) AS total_amount FROM ${DatabaseTables.tableConsultations}
    ''');
    final consultCount = Sqflite.firstIntValue(consultRes) ?? 0;
    final consultTotal = (consultRes.first['total_amount'] as num?)?.toDouble() ?? 0.0;

    // 4. Surgeries count & revenue
    final surgRes = await db.rawQuery('''
      SELECT COUNT(*) AS total_count, SUM(estimated_cost) AS total_amount FROM ${DatabaseTables.tableSurgeries}
      WHERE status = 'completed'
    ''');
    final surgCount = Sqflite.firstIntValue(surgRes) ?? 0;
    final surgTotal = (surgRes.first['total_amount'] as num?)?.toDouble() ?? 0.0;

    // Net profit
    final netProfit = totalIncome - totalExpenses;

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'totalDebts': totalDebtsFromTx,
      'consultCount': consultCount,
      'consultTotal': consultTotal,
      'surgCount': surgCount,
      'surgTotal': surgTotal,
    };
  }

  // --- OWNER ACCOUNT STATEMENT & LEDGER ---
  Future<OwnerAccountSummary?> getOwnerAccountSummary(int ownerId) async {
    final db = await _dbHelper.database;

    // 1. Get Owner
    final ownerRes = await db.query(
      DatabaseTables.tableOwners,
      where: 'id = ?',
      whereArgs: [ownerId],
      limit: 1,
    );
    if (ownerRes.isEmpty) return null;
    final owner = OwnerModel.fromMap(ownerRes.first);

    // 2. Query all transactions linked directly to this owner
    final txList = await getAllTransactions(ownerId: ownerId, limit: 500);

    // 3. Also check if there are consultations or surgeries that need inclusion
    // If transactions already exist for this owner, use them.
    // If not, synthesize from consultations and surgeries
    final items = <AccountStatementItem>[];

    if (txList.isNotEmpty) {
      // Sort oldest to newest for chronological balance calculation
      final sortedTx = List<FinancialTransactionModel>.from(txList)
        ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

      double runningBalance = 0.0;

      for (final tx in sortedTx) {
        double debit = 0.0;
        double credit = 0.0;

        if (tx.transactionType == 'payment') {
          // Client payment -> Credit (reduces debt)
          credit = tx.paidAmount > 0 ? tx.paidAmount : tx.amount;
        } else if (tx.transactionType == 'income') {
          // Billed service -> Debit (client owes full amount)
          debit = tx.amount;
          // If they also paid part of it at the same time:
          credit = tx.paidAmount;
        }

        runningBalance += (debit - credit);

        String desc = tx.categoryDisplayArabic;
        if (tx.notes != null && tx.notes!.isNotEmpty) {
          desc = '$desc: ${tx.notes}';
        }

        items.add(AccountStatementItem(
          id: tx.id,
          date: tx.transactionDate.length >= 10 ? tx.transactionDate.substring(0, 10) : tx.transactionDate,
          type: tx.transactionType,
          description: desc,
          petName: tx.petName,
          debit: debit,
          credit: credit,
          balance: runningBalance,
          notes: tx.notes,
        ));
      }
    } else {
      // Fallback: Query owner's pets' consultations and surgeries directly
      final consultsRes = await db.rawQuery('''
        SELECT c.*, p.name AS pet_name 
        FROM ${DatabaseTables.tableConsultations} c
        JOIN ${DatabaseTables.tablePets} p ON c.pet_id = p.id
        WHERE p.owner_id = ?
        ORDER BY c.visit_date ASC
      ''', [ownerId]);

      final surgeriesRes = await db.rawQuery('''
        SELECT s.*, p.name AS pet_name 
        FROM ${DatabaseTables.tableSurgeries} s
        JOIN ${DatabaseTables.tablePets} p ON s.pet_id = p.id
        WHERE p.owner_id = ?
        ORDER BY s.scheduled_date ASC
      ''', [ownerId]);

      double runningBalance = 0.0;

      for (final c in consultsRes) {
        final cost = (c['visit_cost'] as num?)?.toDouble() ?? 0.0;
        final petName = c['pet_name'] as String?;
        final date = (c['visit_date'] as String? ?? '').split(' ').first;
        final diag = c['diagnosis'] as String? ?? 'فحص';

        // Assume paid if not specified
        final debit = cost;
        final credit = cost;
        runningBalance += (debit - credit);

        items.add(AccountStatementItem(
          id: c['id'] as int?,
          date: date,
          type: 'consultation',
          description: 'كشف سريري - $diag',
          petName: petName,
          debit: debit,
          credit: credit,
          balance: runningBalance,
          notes: c['treatment_plan'] as String?,
        ));
      }

      for (final s in surgeriesRes) {
        final cost = (s['estimated_cost'] as num?)?.toDouble() ?? 0.0;
        final petName = s['pet_name'] as String?;
        final date = (s['scheduled_date'] as String? ?? '').split(' ').first;
        final name = s['surgery_name'] as String? ?? 'عملية جراحية';

        final debit = cost;
        final credit = cost;
        runningBalance += (debit - credit);

        items.add(AccountStatementItem(
          id: s['id'] as int?,
          date: date,
          type: 'surgery',
          description: 'عملية جراحية - $name',
          petName: petName,
          debit: debit,
          credit: credit,
          balance: runningBalance,
        ));
      }
    }

    final totalBilled = items.fold<double>(0.0, (acc, item) => acc + item.debit);
    final totalPaid = items.fold<double>(0.0, (acc, item) => acc + item.credit);
    final balanceDue = totalBilled - totalPaid;

    return OwnerAccountSummary(
      ownerId: owner.id!,
      ownerName: owner.fullName,
      phonePrimary: owner.phonePrimary,
      phoneSecondary: owner.phoneSecondary,
      address: owner.address,
      totalBilled: totalBilled,
      totalPaid: totalPaid,
      balanceDue: balanceDue,
      statementItems: items,
    );
  }

  /// Returns all owners with their account balances (debts/credits)
  Future<List<OwnerAccountSummary>> getAllOwnersBalances() async {
    final db = await _dbHelper.database;
    final ownersRes = await db.query(DatabaseTables.tableOwners, orderBy: 'full_name ASC');

    final List<OwnerAccountSummary> list = [];
    for (final oMap in ownersRes) {
      final ownerId = oMap['id'] as int;
      final summary = await getOwnerAccountSummary(ownerId);
      if (summary != null) {
        list.add(summary);
      }
    }
    return list;
  }
}
