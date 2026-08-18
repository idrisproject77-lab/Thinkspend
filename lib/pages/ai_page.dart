import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/financial_analyzer.dart';

class AiPage extends StatefulWidget {
  final int userId;
  final String userName;

  const AiPage({super.key, required this.userId, required this.userName});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  static const Color navy = Color(0xFF0F172A);
  static const Color blue = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color mutedText = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);

  FinancialSummary? summary;

  bool isLoading = true;

  final TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  final List<_ChatMessage> messages = [];

  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA USER
  // ============================================================

  Future<void> _loadFinancialData() async {
    try {
      final result = await FinancialAnalyzer.analyze(widget.userId);

      if (!mounted) return;

      setState(() {
        summary = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal membaca data finansial: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String _formatRupiah(double value) {
    final rounded = value.round().abs().toString();

    final buffer = StringBuffer();

    for (int i = 0; i < rounded.length; i++) {
      final position = rounded.length - i;

      buffer.write(rounded[i]);

      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }

    final result = 'Rp ${buffer.toString()}';

    if (value < 0) {
      return '-$result';
    }

    return result;
  }

  // ============================================================
  // ASK AI — SEMENTARA MOCK
  // ============================================================

  Future<void> askAi(String question) async {
    final text = question.trim();

    if (text.isEmpty || isTyping) {
      return;
    }

    setState(() {
      messages.add(_ChatMessage(text: text, isUser: true));

      isTyping = true;
    });

    messageController.clear();

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final response = _generateResponse(text);

    setState(() {
      messages.add(_ChatMessage(text: response, isUser: false));

      isTyping = false;
    });

    _scrollToBottom();
  }

  // ============================================================
  // RESPONSE BERDASARKAN DATA ASLI
  // ============================================================

  String _generateResponse(String question) {
    final data = summary;

    if (data == null) {
      return '''
Aku belum bisa membaca data keuanganmu saat ini.

Coba buka kembali halaman ThinkSpend AI beberapa saat lagi.
''';
    }

    final lower = question.toLowerCase();

    // ==========================================================
    // BOROS
    // ==========================================================

    if (lower.contains('boros')) {
      final projectedExpense = data.projectedMonthlyExpense;

      final hasProjection =
          data.dataDays >= 3 && projectedExpense > 0 && data.income > 0;

      // ==========================================================
      // BELUM ADA DATA PEMASUKAN
      // ==========================================================

      if (data.income <= 0) {
        return '''
Aku belum bisa menentukan apakah kamu sedang boros karena belum ada pemasukan yang bisa dijadikan pembanding.

Coba catat pemasukanmu terlebih dahulu. Setelah itu aku bisa membandingkan pola pengeluaranmu dengan kondisi keuanganmu.
''';
      }

      // ==========================================================
      // DATA BELUM CUKUP
      // ==========================================================

      if (!hasProjection) {
        final actualPercentage = (data.expense / data.income) * 100;

        return '''
Dari data yang sudah tercatat, kamu belum bisa langsung dibilang boros. 👌

Pemasukanmu:
${_formatRupiah(data.income)}

Pengeluaranmu:
${_formatRupiah(data.expense)}

Saat ini sekitar ${actualPercentage.toStringAsFixed(1)}% dari pemasukanmu sudah digunakan.

Namun, aku belum bisa menilai pola pengeluaran bulananmu karena data yang tersedia belum mencapai 3 hari.

💡 Tambahkan transaksi dari beberapa hari berikutnya agar aku bisa melihat apakah pola pengeluaranmu cenderung meningkat atau tetap terkendali.
''';
      }

      // ==========================================================
      // ADA PROYEKSI
      // ==========================================================

      final projectedPercentage = (projectedExpense / data.income) * 100;

      final projectedBalance = data.income - projectedExpense;

      // ==========================================================
      // PROYEKSI > PEMASUKAN
      // ==========================================================

      if (projectedPercentage > 100) {
        return '''
⚠️ Pola pengeluaranmu perlu segera diperhatikan.

Pengeluaran yang sudah tercatat:
${_formatRupiah(data.expense)}

Namun berdasarkan ${data.dataDays} hari data, rata-rata pengeluaranmu adalah:
${_formatRupiah(data.averageDailyExpense)} per hari.

Jika pola ini terus berlangsung, pengeluaranmu diproyeksikan mencapai:
${_formatRupiah(projectedExpense)} per bulan.

Itu lebih besar daripada pemasukanmu:
${_formatRupiah(data.income)}

Artinya, pengeluaran berpotensi melebihi pemasukan.

💡 Coba evaluasi kategori pengeluaran terbesar:
${data.topExpenseCategory ?? 'Belum tersedia'} sebesar ${_formatRupiah(data.topExpenseAmount)}.
''';
      }

      // ==========================================================
      // PROYEKSI 80–100%
      // ==========================================================

      if (projectedPercentage >= 80) {
        return '''
Kamu belum bisa langsung dibilang boros dari pengeluaran yang sudah tercatat, tetapi pola pengeluaranmu perlu diperhatikan. ⚠️

Saat ini kamu sudah mengeluarkan:
${_formatRupiah(data.expense)}

dari pemasukan:
${_formatRupiah(data.income)}.

Namun berdasarkan ${data.dataDays} hari data, rata-rata pengeluaranmu adalah:
${_formatRupiah(data.averageDailyExpense)} per hari.

Jika pola ini berlanjut selama 30 hari, pengeluaranmu diproyeksikan mencapai:
${_formatRupiah(projectedExpense)}.

Itu sekitar ${projectedPercentage.toStringAsFixed(1)}% dari pemasukanmu.

Perkiraan sisa pemasukan:
${_formatRupiah(projectedBalance)}.

Pengeluaran terbesar saat ini adalah:
${data.topExpenseCategory ?? 'Belum tersedia'} sebesar ${_formatRupiah(data.topExpenseAmount)}.

💡 Jadi yang perlu diperhatikan bukan hanya pengeluaranmu hari ini, tetapi apakah pola tersebut terus berlanjut.
''';
      }

      // ==========================================================
      // PROYEKSI 60–80%
      // ==========================================================

      if (projectedPercentage >= 60) {
        return '''
Pengeluaranmu masih relatif terkendali, tetapi tetap perlu dipantau. 👍

Berdasarkan ${data.dataDays} hari data:

Rata-rata pengeluaran:
${_formatRupiah(data.averageDailyExpense)} per hari.

Proyeksi pengeluaran 30 hari:
${_formatRupiah(projectedExpense)}.

Itu sekitar ${projectedPercentage.toStringAsFixed(1)}% dari pemasukanmu.

Perkiraan sisa:
${_formatRupiah(projectedBalance)}.

💡 Selama pola ini tidak meningkat terlalu jauh, kondisi keuanganmu masih cukup terkendali.
''';
      }

      // ==========================================================
      // PROYEKSI < 60%
      // ==========================================================

      return '''
Dari pola pengeluaranmu saat ini, kamu belum terlihat boros. 👌

Berdasarkan ${data.dataDays} hari data, pengeluaranmu diproyeksikan sekitar:
${_formatRupiah(projectedExpense)} per bulan.

Itu sekitar ${projectedPercentage.toStringAsFixed(1)}% dari pemasukanmu.

Perkiraan sisa pemasukan:
${_formatRupiah(projectedBalance)}.

Pengeluaran terbesar:
${data.topExpenseCategory ?? 'Belum tersedia'} sebesar ${_formatRupiah(data.topExpenseAmount)}.

💡 Pola pengeluaranmu masih relatif terkendali. Tetap pantau agar tidak meningkat tanpa disadari.
''';
    }

    // ==========================================================
    // TARGET
    // ==========================================================

    if (lower.contains('target')) {
      if (data.goals.isEmpty) {
        return '''
Saat ini kamu belum memiliki target keuangan.

Coba buat satu target terlebih dahulu. Setelah itu aku bisa membantu mengevaluasi progress dan kebutuhan tabunganmu.
''';
      }

      final goal = data.goals.first;

      final progress = FinancialAnalyzer.goalProgress(goal);

      final percentage = (progress * 100).toStringAsFixed(1);

      return '''
Target teratasmu saat ini adalah "${goal.name}".

Progress:
$percentage%

Terkumpul:
${_formatRupiah(goal.currentAmount)}

Target:
${_formatRupiah(goal.targetAmount)}

Sisa:
${_formatRupiah(goal.targetAmount - goal.currentAmount)}

Aku bisa membantu membuat strategi pencapaiannya setelah analisis bulanan kita sudah lengkap.
''';
    }

    // ==========================================================
    // BELI / BELANJA
    // ==========================================================

    if (lower.contains('beli') || lower.contains('belanja')) {
      return '''
Sebelum membeli sesuatu, aku akan melihat kemampuan keuanganmu terlebih dahulu.

Saat ini:

Pemasukan:
${_formatRupiah(data.income)}

Pengeluaran:
${_formatRupiah(data.expense)}

Sisa:
${_formatRupiah(data.balance)}

Jangan hanya melihat apakah saldo cukup. Pertimbangkan juga target dan kebutuhan rutinmu.
''';
    }

    // ==========================================================
    // DEFAULT
    // ==========================================================

    return '''
Berikut gambaran kondisi keuanganmu saat ini:

Pemasukan:
${_formatRupiah(data.income)}

Pengeluaran:
${_formatRupiah(data.expense)}

Sisa:
${_formatRupiah(data.balance)}

Jumlah transaksi:
${data.transactionCount} transaksi

Kategori terbesar:
${data.topExpenseCategory ?? 'Belum tersedia'}

Kondisi:
${FinancialAnalyzer.financialStatus(data)}

Semakin banyak transaksi dan target yang kamu catat, semakin baik analisis yang bisa diberikan.
''';
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,

        leading: messages.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    messages.clear();
                    isTyping = false;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, color: navy),
              )
            : null,

        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,

              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Icon(
                Icons.auto_awesome_rounded,
                color: blue,
                size: 21,
              ),
            ),

            const SizedBox(width: 11),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ThinkSpend AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),

                Text(
                  'Personal Financial Coach',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? _buildLoading()
                : messages.isEmpty
                ? _buildEmptyState()
                : _buildChat(),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: blue));
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          Text(
            'Hai, ${widget.userName} 👋',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: navy,
              letterSpacing: -0.7,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Aku bantu kamu memahami dan\n'
            'mengelola keuanganmu.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.55,
              color: secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          _buildFinancialSnapshot(),

          const SizedBox(height: 26),

          Text(
            'Apa yang ingin kamu ketahui?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),

          const SizedBox(height: 12),

          _buildQuestionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Apakah aku sedang boros?',
            subtitle: 'Analisis pola pengeluaranmu',
            onTap: () {
              askAi('Apakah aku sedang boros?');
            },
          ),

          const SizedBox(height: 10),

          _buildQuestionCard(
            icon: Icons.flag_outlined,
            title: 'Apakah targetku bisa tercapai?',
            subtitle: 'Evaluasi target dan tabunganmu',
            onTap: () {
              askAi('Apakah targetku bisa tercapai?');
            },
          ),

          const SizedBox(height: 10),

          _buildQuestionCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Boleh beli barang ini?',
            subtitle: 'Cek dampaknya terhadap keuanganmu',
            onTap: () {
              askAi('Boleh beli barang ini?');
            },
          ),

          const SizedBox(height: 10),

          _buildQuestionCard(
            icon: Icons.analytics_outlined,
            title: 'Bagaimana kondisi keuanganku?',
            subtitle: 'Lihat ringkasan kondisi finansialmu',
            onTap: () {
              askAi('Bagaimana kondisi keuanganku?');
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FINANCIAL SNAPSHOT
  // ============================================================

  Widget _buildFinancialSnapshot() {
    final data = summary;

    if (data == null) {
      return _buildDataError();
    }

    final hasProjection =
        data.dataDays >= 3 && data.projectedMonthlyExpense > 0;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: borderColor),

        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // HEADER
          // ======================================================
          Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFF59E0B),
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Text(
                'Financial Snapshot',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ======================================================
          // PEMASUKAN & PENGELUARAN
          // ======================================================
          Row(
            children: [
              Expanded(
                child: _snapshotItem(
                  label: 'Pemasukan',
                  value: _formatRupiah(data.income),
                ),
              ),

              Expanded(
                child: _snapshotItem(
                  label: 'Pengeluaran',
                  value: _formatRupiah(data.expense),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          // ======================================================
          // SISA & TRANSAKSI
          // ======================================================
          Row(
            children: [
              Expanded(
                child: _snapshotItem(
                  label: 'Sisa',
                  value: _formatRupiah(data.balance),
                ),
              ),

              Expanded(
                child: _snapshotItem(
                  label: 'Transaksi',
                  value: '${data.transactionCount} transaksi',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(height: 1, color: borderColor),

          const SizedBox(height: 15),

          // ======================================================
          // DATA ANALYSIS
          // ======================================================
          Text(
            'Analisis pola pengeluaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _snapshotItem(
                  label: 'Data tersedia',
                  value: '${data.dataDays} hari',
                ),
              ),

              Expanded(
                child: _snapshotItem(
                  label: 'Rata-rata / hari',
                  value: data.dataDays > 0
                      ? _formatRupiah(data.averageDailyExpense)
                      : 'Belum tersedia',
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ======================================================
          // PROJECTION
          // ======================================================
          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: hasProjection
                  ? blue.withValues(alpha: 0.05)
                  : const Color(0xFFF8FAFC),

              borderRadius: BorderRadius.circular(13),

              border: Border.all(color: borderColor),
            ),

            child: Row(
              children: [
                Icon(
                  hasProjection
                      ? Icons.trending_up_rounded
                      : Icons.hourglass_empty_rounded,

                  color: hasProjection ? blue : mutedText,

                  size: 19,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Proyeksi pengeluaran 30 hari',

                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        hasProjection
                            ? _formatRupiah(data.projectedMonthlyExpense)
                            : 'Belum tersedia',

                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // PROYEKSI TAMBAHAN
          // ======================================================
          if (hasProjection) ...[
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _snapshotItem(
                    label: 'Sisa proyeksi',
                    value: _formatRupiah(
                      data.income - data.projectedMonthlyExpense,
                    ),
                  ),
                ),

                Expanded(
                  child: _snapshotItem(
                    label: 'Proyeksi / pemasukan',
                    value: data.income > 0
                        ? '${((data.projectedMonthlyExpense / data.income) * 100).toStringAsFixed(1)}%'
                        : '-',
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 17),

          // ======================================================
          // TOP CATEGORY
          // ======================================================
          Text(
            'Pengeluaran terbesar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              Expanded(
                child: Text(
                  data.topExpenseCategory ?? 'Belum tersedia',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Text(
                _formatRupiah(data.topExpenseAmount),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // HEALTH STATUS
          // ======================================================
          Container(
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.06),

              borderRadius: BorderRadius.circular(12),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: blue, size: 17),

                    const SizedBox(width: 7),

                    Text(
                      'Kondisi: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    Expanded(
                      child: Text(
                        FinancialAnalyzer.financialStatus(data),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  FinancialAnalyzer.healthExplanation(data),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    height: 1.45,
                    color: secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // WARNING DATA BELUM CUKUP
          // ======================================================
        ],
      ),
    );
  }

  // ============================================================
  // SNAPSHOT ITEM
  // ============================================================

  Widget _snapshotItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            color: secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATA ERROR
  // ============================================================

  Widget _buildDataError() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: borderColor),
      ),

      child: const Text('Data keuangan belum dapat dibaca.'),
    );
  }

  // ============================================================
  // QUESTION CARD
  // ============================================================

  Widget _buildQuestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,

      borderRadius: BorderRadius.circular(17),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(17),

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),

            border: Border.all(color: borderColor),
          ),

          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.08),

                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(icon, color: blue, size: 21),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: mutedText,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHAT
  // ============================================================

  Widget _buildChat() {
    return ListView.builder(
      controller: scrollController,

      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),

      itemCount: messages.length + (isTyping ? 1 : 0),

      itemBuilder: (context, index) {
        if (index >= messages.length) {
          return _buildTypingIndicator();
        }

        return _buildMessage(messages[index]);
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  Widget _buildMessage(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,

      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),

        margin: const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),

        decoration: BoxDecoration(
          color: message.isUser ? blue : Colors.white,

          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(message.isUser ? 17 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 17),
          ),

          border: message.isUser ? null : Border.all(color: borderColor),
        ),

        child: Text(
          message.text,

          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.5,
            color: message.isUser ? Colors.white : navy,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TYPING
  // ============================================================

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(17),

          border: Border.all(color: borderColor),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            const SizedBox(
              width: 16,
              height: 16,

              child: CircularProgressIndicator(strokeWidth: 2, color: blue),
            ),

            const SizedBox(width: 10),

            Text(
              'ThinkSpend AI sedang berpikir...',

              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),

      decoration: BoxDecoration(
        color: background,

        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,

          children: [
            Expanded(
              child: TextField(
                controller: messageController,

                minLines: 1,
                maxLines: 4,

                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: navy,
                  fontWeight: FontWeight.w500,
                ),

                decoration: InputDecoration(
                  hintText: 'Tanya ThinkSpend AI...',

                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: mutedText,
                    fontWeight: FontWeight.w500,
                  ),

                  filled: true,

                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: borderColor),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: borderColor),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: blue, width: 1.4),
                  ),
                ),

                onSubmitted: (value) {
                  askAi(value);
                },
              ),
            ),

            const SizedBox(width: 9),

            GestureDetector(
              onTap: isTyping
                  ? null
                  : () {
                      askAi(messageController.text);
                    },

              child: Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: isTyping ? mutedText : blue,

                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CHAT MODEL
// ================================================================

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}
