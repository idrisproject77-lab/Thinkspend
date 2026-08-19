import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/pages/transaction_detail_page.dart';
import 'add_transaction_page.dart';
import 'package:thinkspend/services/theme_service.dart';
import 'package:thinkspend/utils/currency_formatter.dart';
import 'package:thinkspend/widgets/transaction_card.dart';

class TransactionsPage extends StatefulWidget {
  final UserModel user;

  const TransactionsPage({super.key, required this.user});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  // ============================================================
  // RIWAYAT TRANSAKSI STATE
  // ============================================================
  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];

  double totalIncome = 0;
  double totalExpense = 0;

  String filterType = 'all';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();
  DateTime selectedMonth = DateTime.now();

  // ============================================================
  // STATISTIK STATE
  // ============================================================
  List<TransactionModel> statsTransactions = [];
  double statsIncome = 0;
  double statsExpense = 0;
  final Map<String, double> categoryTotals = {};
  String selectedPeriod = 'Semua Waktu';

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
  // LOAD TRANSACTIONS & UPDATE BOTH TABS
  // ============================================================

  Future<void> loadTransactions() async {
    final data = await DatabaseHelper.instance.getTransactions(widget.user.id!);

    if (!mounted) return;

    setState(() {
      allTransactions = data;

      _updateMonthlySummary();
      _applyFilter();
      _updateStatistics();
    });
  }

  // ============================================================
  // MONTHLY SUMMARY (TAB RIWAYAT)
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
  // FILTER TRANSACTIONS (TAB RIWAYAT)
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
  // STATISTIK CALCULATION (TAB STATISTIK)
  // ============================================================

  void _updateStatistics() {
    final now = DateTime.now();
    List<TransactionModel> filteredData = [];

    for (final transaction in allTransactions) {
      try {
        final date = DateTime.parse(transaction.date);
        bool include = false;

        if (selectedPeriod == 'Semua Waktu') {
          include = true;
        } else if (selectedPeriod == 'Bulan Ini') {
          include = date.year == now.year && date.month == now.month;
        } else if (selectedPeriod == 'Bulan Lalu') {
          final lastMonth = DateTime(now.year, now.month - 1);
          include =
              date.year == lastMonth.year && date.month == lastMonth.month;
        }

        if (include) {
          filteredData.add(transaction);
        }
      } catch (_) {
        // Abaikan tanggal transaksi yang tidak valid.
      }
    }

    double income = 0;
    double expense = 0;
    final Map<String, double> categories = {};

    for (final transaction in filteredData) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      }

      if (transaction.type == 'expense') {
        expense += transaction.amount;
        categories[transaction.category] =
            (categories[transaction.category] ?? 0) + transaction.amount;
      }
    }

    statsTransactions = filteredData;
    statsIncome = income;
    statsExpense = expense;
    categoryTotals
      ..clear()
      ..addAll(categories);
  }

  // ============================================================
  // CHANGE MONTH (TAB RIWAYAT)
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
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final mutedText = AppColors.muted(context);
    const primaryBlue = AppColors.primaryBlue;
    const incomeGreen = AppColors.green;
    const expenseRed = AppColors.red;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Transaksi'),
          bottom: TabBar(
            indicatorColor: primaryBlue,
            labelColor: primaryBlue,
            unselectedLabelColor: textSecondary,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 18),
                    SizedBox(width: 6),
                    Text('Riwayat', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_outlined, size: 18),
                    SizedBox(width: 6),
                    Text('Statistik', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ==================================================
            // TAB 1: RIWAYAT TRANSAKSI
            // ==================================================
            RefreshIndicator(
              onRefresh: loadTransactions,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ----------------------------------------------
                  // MONTH SELECTOR
                  // ----------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => changeMonth(-1),
                              icon: Icon(Icons.chevron_left, size: 20, color: textSecondary),
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              '${getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => changeMonth(1),
                              icon: Icon(Icons.chevron_right, size: 20, color: textSecondary),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ----------------------------------------------
                  // UNIFIED FINANCIAL SUMMARY CARD
                  // ----------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.arrow_downward,
                                            size: 14,
                                            color: incomeGreen,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pemasukan',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatRupiah(totalIncome),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: incomeGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 28,
                                  width: 1,
                                  color: border,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.arrow_upward,
                                            size: 14,
                                            color: expenseRed,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pengeluaran',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatRupiah(totalExpense),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: expenseRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: border),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sisa dari transaksi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  formatRupiah(remaining),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: remaining >= 0
                                        ? incomeGreen
                                        : expenseRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ----------------------------------------------
                  // SEARCH
                  // ----------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Cari transaksi...',
                          hintStyle: TextStyle(color: mutedText, fontSize: 14),
                          prefixIcon: Icon(Icons.search, size: 20, color: textSecondary),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18, color: textSecondary),
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
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
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

                  // ----------------------------------------------
                  // FILTER TYPE
                  // ----------------------------------------------
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Semua'),
                              selected: filterType == 'all',
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              selectedColor: primaryBlue.withValues(alpha: 0.12),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: filterType == 'all' ? primaryBlue : textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: filterType == 'all'
                                      ? primaryBlue
                                      : border,
                                ),
                              ),
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
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              selectedColor: incomeGreen.withValues(alpha: 0.12),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: filterType == 'income' ? incomeGreen : textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: filterType == 'income'
                                      ? incomeGreen
                                      : border,
                                ),
                              ),
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
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              selectedColor: expenseRed.withValues(alpha: 0.12),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: filterType == 'expense' ? expenseRed : textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: filterType == 'expense'
                                      ? expenseRed
                                      : border,
                                ),
                              ),
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

                  const SliverToBoxAdapter(child: SizedBox(height: 4)),

                  // ----------------------------------------------
                  // TRANSACTION LIST
                  // ----------------------------------------------
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
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: mutedText,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada transaksi.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final transaction = filteredTransactions[index];

                          return TransactionCard(
                            transaction: transaction,
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
                          );
                        }, childCount: filteredTransactions.length),
                      ),
                    ),
                ],
              ),
            ),

            // ==================================================
            // TAB 2: STATISTIK
            // ==================================================
            RefreshIndicator(
              onRefresh: loadTransactions,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------
                    // JUDUL & SUBTITLE
                    // ------------------------------------------
                    Text(
                      'Ringkasan Keuangan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kondisi keuangan berdasarkan transaksi yang tercatat.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // ------------------------------------------
                    // FILTER PERIODE
                    // ------------------------------------------
                    DropdownButtonFormField<String>(
                      initialValue: selectedPeriod,
                      dropdownColor: surface,
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Periode',
                        prefixIcon: Icon(Icons.calendar_month_outlined, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Semua Waktu',
                          child: Text('Semua Waktu'),
                        ),
                        DropdownMenuItem(
                          value: 'Bulan Ini',
                          child: Text('Bulan Ini'),
                        ),
                        DropdownMenuItem(
                          value: 'Bulan Lalu',
                          child: Text('Bulan Lalu'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedPeriod = value;
                          _updateStatistics();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // ------------------------------------------
                    // PEMASUKAN & PENGELUARAN
                    // ------------------------------------------
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Pemasukan',
                            value: formatRupiah(statsIncome),
                            icon: Icons.arrow_downward,
                            isIncome: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Pengeluaran',
                            value: formatRupiah(statsExpense),
                            icon: Icons.arrow_upward,
                            isIncome: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ------------------------------------------
                    // PENGELUARAN PER KATEGORI
                    // ------------------------------------------
                    Text(
                      'Pengeluaran per Kategori',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (sortedCategories.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada data pengeluaran pada periode ini.',
                            style: TextStyle(color: mutedText, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < sortedCategories.length; i++) ...[
                              _CategoryTile(
                                rank: i + 1,
                                category: sortedCategories[i].key,
                                amount: sortedCategories[i].value,
                                totalExpense: statsExpense,
                                formatRupiah: formatRupiah,
                              ),
                              if (i < sortedCategories.length - 1)
                                Divider(height: 1, color: border),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ------------------------------------------
                    // GRAFIK PENGELUARAN
                    // ------------------------------------------
                    Text(
                      'Grafik Pengeluaran',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (sortedCategories.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada data untuk ditampilkan.',
                            style: TextStyle(color: mutedText, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            for (final category in sortedCategories)
                              _CategoryBar(
                                category: category.key,
                                amount: category.value,
                                maxAmount: sortedCategories.first.value,
                                formatRupiah: formatRupiah,
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // ------------------------------------------
                    // TOTAL TRANSAKSI
                    // ------------------------------------------
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryBlue.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                            color: primaryBlue,
                          ),
                        ),
                        title: Text(
                          'Total Transaksi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${statsTransactions.length} transaksi tercatat',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ======================================================
        // ADD TRANSACTION FAB
        // ======================================================
        floatingActionButton: FloatingActionButton(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD WIDGET
// ============================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isIncome;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isIncome ? AppColors.green : AppColors.red;
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textSecondary = AppColors.textSecondary(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accentColor.withValues(alpha: 0.12),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CATEGORY TILE WIDGET
// ============================================================

class _CategoryTile extends StatelessWidget {
  final int rank;
  final String category;
  final double amount;
  final double totalExpense;
  final String Function(double) formatRupiah;

  const _CategoryTile({
    required this.rank,
    required this.category,
    required this.amount,
    required this.totalExpense,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0;
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final subtleBg = AppColors.subtleBg(context);

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: subtleBg,
        child: Text(
          '$rank',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
        ),
      ),
      title: Text(
        category,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textPrimary,
        ),
      ),
      subtitle: Text(
        '${percentage.toStringAsFixed(1).replaceAll('.', ',')}% dari total pengeluaran',
        style: TextStyle(fontSize: 11, color: textSecondary),
      ),
      trailing: Text(
        formatRupiah(amount),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: textPrimary,
        ),
      ),
    );
  }
}

// ============================================================
// CATEGORY BAR WIDGET
// ============================================================

class _CategoryBar extends StatelessWidget {
  final String category;
  final double amount;
  final double maxAmount;
  final String Function(double) formatRupiah;

  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.maxAmount,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxAmount > 0 ? amount / maxAmount : 0.0;
    final textPrimary = AppColors.textPrimary(context);
    final subtleBg = AppColors.subtleBg(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatRupiah(amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage.toDouble(),
              minHeight: 6,
              backgroundColor: subtleBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}
