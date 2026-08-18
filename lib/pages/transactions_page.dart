import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/pages/transaction_detail_page.dart';
import 'add_transaction_page.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

class TransactionsPage extends StatefulWidget {
  final UserModel user;

  const TransactionsPage({super.key, required this.user});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];

  double totalIncome = 0;
  double totalExpense = 0;

  String filterType = 'all';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  DateTime selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD TRANSACTIONS
  // ============================================================

  Future<void> loadTransactions() async {
    final data = await DatabaseHelper.instance.getTransactions(widget.user.id!);

    if (!mounted) return;

    setState(() {
      allTransactions = data;

      _updateMonthlySummary();
      _applyFilter();
    });
  }

  // ============================================================
  // MONTHLY SUMMARY
  // ============================================================

  void _updateMonthlySummary() {
    double income = 0;
    double expense = 0;

    for (final transaction in allTransactions) {
      final date = DateTime.tryParse(transaction.date);

      if (date == null) continue;

      if (date.year == selectedMonth.year &&
          date.month == selectedMonth.month) {
        if (transaction.type == 'income') {
          income += transaction.amount;
        } else if (transaction.type == 'expense') {
          expense += transaction.amount;
        }
      }
    }

    totalIncome = income;
    totalExpense = expense;
  }

  // ============================================================
  // FILTER TRANSACTIONS
  // ============================================================

  void _applyFilter() {
    List<TransactionModel> list = allTransactions.where((transaction) {
      final date = DateTime.tryParse(transaction.date);

      if (date == null) {
        return false;
      }

      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();

    // Transaksi terbaru di atas
    list = list.reversed.toList();

    // Filter tipe
    if (filterType != 'all') {
      list = list
          .where((transaction) => transaction.type == filterType)
          .toList();
    }

    // Search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();

      list = list.where((transaction) {
        final title = transaction.title.toLowerCase();

        final category = transaction.category.toLowerCase();

        final notes = (transaction.notes ?? '').toLowerCase();

        return title.contains(query) ||
            category.contains(query) ||
            notes.contains(query);
      }).toList();
    }

    filteredTransactions = list;
  }

  // ============================================================
  // CHANGE MONTH
  // ============================================================

  void changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + offset,
      );

      _updateMonthlySummary();
      _applyFilter();
    });
  }

  // ============================================================
  // MONTH NAME
  // ============================================================

  String getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[month - 1];
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(String date) {
    if (date.length >= 10) {
      return date.substring(0, 10);
    }

    return date;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final remaining = totalIncome - totalExpense;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(title: const Text('Transaksi')),

      body: RefreshIndicator(
        onRefresh: loadTransactions,

        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ==================================================
            // MONTH SELECTOR
            // ==================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        changeMonth(-1);
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),

                    Column(
                      children: [
                        const Text(
                          'Ringkasan',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          '${getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    IconButton(
                      onPressed: () {
                        changeMonth(1);
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // SUMMARY
            // ==================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.green.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pemasukan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                formatRupiah(totalIncome),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Card(
                        color: Colors.red.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                formatRupiah(totalExpense),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==================================================
            // REMAINING
            // ==================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sisa dari transaksi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),

                        Text(
                          formatRupiah(remaining),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: remaining >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ==================================================
            // SEARCH
            // ==================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();

                              setState(() {
                                searchQuery = '';
                                _applyFilter();
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.trim();
                      _applyFilter();
                    });
                  },
                ),
              ),
            ),

            // ==================================================
            // FILTER TYPE
            // ==================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua'),
                        selected: filterType == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              filterType = 'all';
                              _applyFilter();
                            });
                          }
                        },
                      ),

                      const SizedBox(width: 8),

                      FilterChip(
                        label: const Text('Pemasukan'),
                        selected: filterType == 'income',
                        selectedColor: Colors.green.withValues(alpha: 0.2),
                        checkmarkColor: Colors.green,
                        onSelected: (selected) {
                          setState(() {
                            filterType = selected ? 'income' : 'all';
                            _applyFilter();
                          });
                        },
                      ),

                      const SizedBox(width: 8),

                      FilterChip(
                        label: const Text('Pengeluaran'),
                        selected: filterType == 'expense',
                        selectedColor: Colors.red.withValues(alpha: 0.2),
                        checkmarkColor: Colors.red,
                        onSelected: (selected) {
                          setState(() {
                            filterType = selected ? 'expense' : 'all';
                            _applyFilter();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ==================================================
            // TRANSACTION LIST
            // ==================================================
            if (filteredTransactions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          searchQuery.isNotEmpty
                              ? 'Tidak ada transaksi yang cocok'
                              : 'Belum ada transaksi.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final transaction = filteredTransactions[index];

                    final isIncome = transaction.type == 'income';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailPage(
                                transaction: transaction,
                              ),
                            ),
                          );

                          if (result == true) {
                            await loadTransactions();
                          }
                        },

                        leading: CircleAvatar(
                          backgroundColor: isIncome
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),

                        title: Text(
                          transaction.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        subtitle: Text(
                          '${transaction.category} • '
                          '${formatDate(transaction.date)}',
                        ),

                        trailing: Text(
                          '${isIncome ? '+' : '-'} '
                          '${formatRupiah(transaction.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  }, childCount: filteredTransactions.length),
                ),
              ),
          ],
        ),
      ),

      // ========================================================
      // ADD TRANSACTION
      // ========================================================
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,

            MaterialPageRoute(
              builder: (context) => AddTransactionPage(user: widget.user),
            ),
          );

          if (result == true) {
            await loadTransactions();
          }
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}
