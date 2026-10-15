import 'package:sqflite/sqflite.dart';
import '../../core/services/data_sync_service.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/account_statement_model.dart';
import '../models/customer_payment_model.dart';
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
    final expenseId = await db.transaction((txn) async {
      final id = await txn.insert(DatabaseTables.tableExpenses, expense.toMap());

      // Create linked financial transaction
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'expense',
        'category': expense.category,
        'owner_id': null,
        'pet_id': null,
        'reference_id': id,
        'reference_type': 'expense',
        'amount': expense.amount,
        'paid_amount': expense.amount,
        'remaining_amount': 0.0,
        'payment_method': 'cash',
        'transaction_date': expense.expenseDate,
        'notes': expense.notes ?? expense.title,
      });

      return id;
    });

    DataSyncService.notifyAllChanged();
    return expenseId;
  }

  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    final res = await db.transaction((txn) async {
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

    DataSyncService.notifyAllChanged();
    return res;
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
    final res = await db.insert(DatabaseTables.tableTransactions, tx.toMap());
    DataSyncService.notifyAllChanged();
    return res;
  }

  /// Records a cash/transfer payment voucher (سند قبض / دفعة) from an owner
  Future<int> recordClientPayment({
    required int ownerId,
    required double amount,
    int? transactionId,
    int? petId,
    String paymentMethod = 'نقدا',
    String? notes,
    DateTime? date,
    String? receiptNumber,
  }) async {
    final db = await _dbHelper.database;
    final now = date ?? DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final receipt = receiptNumber ?? 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final paymentId = await db.transaction((txn) async {
      // 1. Insert into customer_payments ledger
      final id = await txn.insert(DatabaseTables.tableCustomerPayments, {
        'owner_id': ownerId,
        'transaction_id': transactionId,
        'amount': amount,
        'payment_method': paymentMethod,
        'payment_date': dateStr,
        'receipt_number': receipt,
        'notes': notes ?? 'سند قبض وتحصيل دفعة لحساب العميل',
      });

      // 2. Insert into financial_transactions for general accounting
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'payment',
        'category': 'direct_payment',
        'owner_id': ownerId,
        'pet_id': petId,
        'reference_id': id,
        'reference_type': 'customer_payment',
        'amount': amount,
        'paid_amount': amount,
        'remaining_amount': 0.0,
        'payment_method': paymentMethod,
        'transaction_date': dateStr,
        'notes': (notes != null && notes.isNotEmpty)
            ? '$notes (سند رقم: $receipt)'
            : 'سند قبض وتحصيل دفعة نقدية لحساب العميل (سند رقم: $receipt)',
      });

      // 3. If tied to a specific transaction, update remaining amount on it
      if (transactionId != null) {
        final txRows = await txn.query(
          DatabaseTables.tableTransactions,
          where: 'id = ?',
          whereArgs: [transactionId],
          limit: 1,
        );
        if (txRows.isNotEmpty) {
          final tx = txRows.first;
          final currentPaid = (tx['paid_amount'] as num?)?.toDouble() ?? 0.0;
          final totalAmount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final newPaid = currentPaid + amount;
          final newRemaining = (totalAmount - newPaid).clamp(0.0, double.infinity);
          await txn.update(
            DatabaseTables.tableTransactions,
            {
              'paid_amount': newPaid,
              'remaining_amount': newRemaining,
            },
            where: 'id = ?',
            whereArgs: [transactionId],
          );
        }
      }

      return id;
    });

    DataSyncService.notifyAllChanged();
    return paymentId;
  }

  /// Retrieves all customer payments recorded for an owner
  Future<List<CustomerPaymentModel>> getCustomerPayments(int ownerId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT cp.*, o.full_name AS owner_name, o.phone_primary AS owner_phone
      FROM ${DatabaseTables.tableCustomerPayments} cp
      LEFT JOIN ${DatabaseTables.tableOwners} o ON cp.owner_id = o.id
      WHERE cp.owner_id = ?
      ORDER BY cp.payment_date DESC, cp.id DESC
    ''', [ownerId]);
    return res.map((m) => CustomerPaymentModel.fromMap(m)).toList();
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
  Future<OwnerAccountSummary?> getOwnerAccountSummary(
    int ownerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

    // 2. Query all customer payments recorded for this owner
    final paymentLedger = await getCustomerPayments(ownerId);

    // 3. Query all transactions linked directly to this owner
    final txList = await getAllTransactions(ownerId: ownerId, limit: 500);

    // Internal helper for monetary rounding to prevent floating-point inaccuracies
    double roundCurrency(double val) => (val * 100).roundToDouble() / 100.0;

    // Raw entries that will be sorted and balance-computed
    final rawEntries = <_RawStatementEntry>[];

    if (txList.isNotEmpty) {
      final hasCustomerPayments = paymentLedger.isNotEmpty;

      for (final tx in txList) {
        if (tx.transactionType == 'income') {
          String desc = tx.categoryDisplayArabic;
          if (tx.notes != null && tx.notes!.isNotEmpty) {
            desc = '$desc: ${tx.notes}';
          }
          final dateStr = tx.transactionDate.length >= 10
              ? tx.transactionDate.substring(0, 10)
              : tx.transactionDate;

          final debit = tx.amount;
          final credit = hasCustomerPayments ? 0.0 : tx.paidAmount;

          rawEntries.add(_RawStatementEntry(
            id: tx.id,
            date: dateStr,
            type: tx.category ?? 'service',
            description: desc,
            petName: tx.petName,
            debit: debit,
            credit: credit,
            paymentMethod: tx.paymentMethod,
            notes: tx.notes,
          ));
        } else if (tx.transactionType == 'payment') {
          final alreadyInLedger = paymentLedger.any((p) =>
              p.amount == tx.amount &&
              p.paymentDate.startsWith(tx.transactionDate.substring(0, 10)));

          if (!alreadyInLedger) {
            final dateStr = tx.transactionDate.length >= 10
                ? tx.transactionDate.substring(0, 10)
                : tx.transactionDate;

            rawEntries.add(_RawStatementEntry(
              id: tx.id,
              date: dateStr,
              type: 'payment',
              description: tx.notes ?? 'سند قبض / دفعة مسددة',
              petName: tx.petName,
              debit: 0.0,
              credit: tx.paidAmount > 0 ? tx.paidAmount : tx.amount,
              paymentMethod: tx.paymentMethod,
              notes: tx.notes,
            ));
          }
        }
      }

      if (hasCustomerPayments) {
        for (final p in paymentLedger) {
          final dateStr = p.paymentDate.length >= 10
              ? p.paymentDate.substring(0, 10)
              : p.paymentDate;

          String desc = 'سند قبض (${p.paymentMethodDisplayArabic})';
          if (p.receiptNumber != null && p.receiptNumber!.isNotEmpty) {
            desc = '$desc - ${p.receiptNumber}';
          }

          rawEntries.add(_RawStatementEntry(
            id: p.id,
            date: dateStr,
            type: 'payment',
            description: desc,
            petName: null,
            debit: 0.0,
            credit: p.amount,
            paymentMethod: p.paymentMethod,
            notes: p.notes,
          ));
        }
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

      for (final c in consultsRes) {
        final cost = (c['visit_cost'] as num?)?.toDouble() ?? 0.0;
        final paid = (c['paid_amount'] as num?)?.toDouble() ?? cost;
        final petName = c['pet_name'] as String?;
        final date = (c['visit_date'] as String? ?? '').split(' ').first;
        final diag = c['diagnosis'] as String? ?? 'فحص';

        rawEntries.add(_RawStatementEntry(
          id: c['id'] as int?,
          date: date,
          type: 'consultation',
          description: 'كشف سريري - $diag',
          petName: petName,
          debit: cost,
          credit: paid,
          notes: c['treatment_plan'] as String?,
        ));
      }

      for (final s in surgeriesRes) {
        final cost = (s['estimated_cost'] as num?)?.toDouble() ?? 0.0;
        final petName = s['pet_name'] as String?;
        final date = (s['scheduled_date'] as String? ?? '').split(' ').first;
        final name = s['surgery_name'] as String? ?? 'عملية جراحية';

        rawEntries.add(_RawStatementEntry(
          id: s['id'] as int?,
          date: date,
          type: 'surgery',
          description: 'عملية جراحية - $name',
          petName: petName,
          debit: cost,
          credit: cost,
        ));
      }

      for (final p in paymentLedger) {
        final dateStr = p.paymentDate.length >= 10
            ? p.paymentDate.substring(0, 10)
            : p.paymentDate;

        String desc = 'سند قبض (${p.paymentMethodDisplayArabic})';
        if (p.receiptNumber != null && p.receiptNumber!.isNotEmpty) {
          desc = '$desc - ${p.receiptNumber}';
        }

        rawEntries.add(_RawStatementEntry(
          id: p.id,
          date: dateStr,
          type: 'payment',
          description: desc,
          petName: null,
          debit: 0.0,
          credit: p.amount,
          paymentMethod: p.paymentMethod,
          notes: p.notes,
        ));
      }
    }

    // Sort chronologically (oldest first)
    rawEntries.sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0.0;
    double openingBalance = 0.0;
    final statementItems = <AccountStatementItem>[];

    final startStr = startDate != null
        ? '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'
        : null;
    final endStr = endDate != null
        ? '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}'
        : null;

    for (final entry in rawEntries) {
      runningBalance = roundCurrency(runningBalance + (entry.debit - entry.credit));

      if (startStr != null && entry.date.compareTo(startStr) < 0) {
        openingBalance = runningBalance;
        continue;
      }

      if (endStr != null && entry.date.compareTo(endStr) > 0) {
        continue;
      }

      statementItems.add(AccountStatementItem(
        id: entry.id,
        date: entry.date,
        type: entry.type,
        description: entry.description,
        petName: entry.petName,
        debit: roundCurrency(entry.debit),
        credit: roundCurrency(entry.credit),
        balance: roundCurrency(runningBalance),
        paymentMethod: entry.paymentMethod,
        notes: entry.notes,
      ));
    }

    if (startStr != null && openingBalance.abs() > 0.001) {
      statementItems.insert(
        0,
        AccountStatementItem(
          date: startStr,
          type: 'opening_balance',
          description: 'رصيد سابق منقول للفترة المحددة',
          debit: openingBalance > 0 ? openingBalance : 0.0,
          credit: openingBalance < 0 ? -openingBalance : 0.0,
          balance: openingBalance,
        ),
      );
    }

    final totalBilled = roundCurrency(rawEntries.fold<double>(0.0, (acc, item) => acc + item.debit));
    final totalPaid = roundCurrency(rawEntries.fold<double>(0.0, (acc, item) => acc + item.credit));
    final balanceDue = roundCurrency(totalBilled - totalPaid);

    return OwnerAccountSummary(
      ownerId: owner.id!,
      ownerName: owner.fullName,
      phonePrimary: owner.phonePrimary,
      address: owner.address,
      totalBilled: totalBilled,
      totalPaid: totalPaid,
      balanceDue: balanceDue,
      statementItems: statementItems,
      paymentLedger: paymentLedger,
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

class _RawStatementEntry {
  final int? id;
  final String date;
  final String type;
  final String description;
  final String? petName;
  final double debit;
  final double credit;
  final String? paymentMethod;
  final String? notes;

  _RawStatementEntry({
    this.id,
    required this.date,
    required this.type,
    required this.description,
    this.petName,
    required this.debit,
    required this.credit,
    this.paymentMethod,
    this.notes,
  });
}
