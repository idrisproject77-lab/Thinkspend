import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/goal_model.dart';
import '../services/financial_analyzer.dart';
import '../services/privacy_service.dart';
import '../services/theme_service.dart';
import '../utils/currency_formatter.dart';

/// Halaman asisten keuangan cerdas berbasis AI ThinkSpend.
///
/// Menyediakan antarmuka chat interaktif dengan chip rekomendasi pertanyaan
/// dan engine rule-based contextual analyzer ([FinancialAnalyzer]) untuk memberikan
/// konsultasi kondisi finansial, evaluasi pengeluaran, simulasi target tabungan, dan tips keuangan.
class AiPage extends StatefulWidget {
  final int userId;
  final String userName;
  final bool isActive;

  const AiPage({
    super.key,
    required this.userId,
    required this.userName,
    this.isActive = true,
  });

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with WidgetsBindingObserver {
  FinancialSummary? summary;
  bool isLoading = true;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<_ChatMessage> messages = [];
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFinancialData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadFinancialData();
    }
  }

  @override
  void didUpdateWidget(covariant AiPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sinkronisasi data saat user berpindah kembali ke tab AI atau userId berganti
    if (widget.userId != oldWidget.userId ||
        (!oldWidget.isActive && widget.isActive)) {
      _loadFinancialData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA USER (LIVE DATA REFRESH)
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
  // HELPER TARGET & SAVING RULES
  // ============================================================

  GoalModel? _getNearestGoal(List<GoalModel> goals) {
    if (goals.isEmpty) return null;

    GoalModel? selectedGoal;

    for (final goal in goals) {
      if (goal.targetAmount <= goal.currentAmount) {
        continue;
      }

      if (selectedGoal == null) {
        selectedGoal = goal;
        continue;
      }

      if (goal.priority == 'High' && selectedGoal.priority != 'High') {
        selectedGoal = goal;
        continue;
      }

      if (goal.deadline != null && selectedGoal.deadline != null) {
        if (goal.deadline!.compareTo(selectedGoal.deadline!) < 0) {
          selectedGoal = goal;
        }
      }
    }

    return selectedGoal ?? goals.first;
  }

  int _calculateRemainingMonths(String? deadline) {
    if (deadline == null || deadline.trim().isEmpty) {
      return 0;
    }

    final parsedDate = DateTime.tryParse(deadline.trim());
    if (parsedDate == null) {
      return 0;
    }

    final now = DateTime.now();
    if (parsedDate.isBefore(now)) {
      return 0;
    }

    int months =
        (parsedDate.year - now.year) * 12 + parsedDate.month - now.month;

    if (parsedDate.day > now.day) {
      months++;
    }

    if (months <= 0) {
      return 1;
    }

    return months;
  }

  double _calculateRequiredMonthlySaving(GoalModel goal) {
    final remaining = (goal.targetAmount - goal.currentAmount) > 0
        ? (goal.targetAmount - goal.currentAmount)
        : 0.0;

    if (remaining <= 0) {
      return 0;
    }

    if (goal.deadline == null || goal.deadline!.trim().isEmpty) {
      return 0;
    }

    final months = _calculateRemainingMonths(goal.deadline);
    if (months <= 0) {
      return remaining;
    }

    return remaining / months;
  }

  // ============================================================
  // ASK AI — RULE-BASED SIMULATION
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

    // Selalu ambil data keuangan terbaru secara asinkron sebelum menghasilkan jawaban AI
    // agar AI membaca transaksi dan target terbaru tanpa perlu restart aplikasi.
    try {
      final freshSummary = await FinancialAnalyzer.analyze(widget.userId);
      if (mounted) {
        setState(() {
          summary = freshSummary;
        });
      }
    } catch (e) {
      debugPrint('Error updating summary in askAi: $e');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final response = _generateResponse(text);

    setState(() {
      messages.add(
        _ChatMessage(text: response, isUser: false, originalQuestion: text),
      );
      isTyping = false;
    });

    _scrollToBottom();
  }

  // ============================================================
  // RESPONSE BERDASARKAN DATA ASLI (RULE MATCHING)
  // ============================================================

  String _generateResponse(String question) {
    final data = summary;

    if (data == null) {
      return '''
Aku belum bisa membaca data keuanganmu saat ini.

Coba buka kembali halaman ThinkSpend AI beberapa saat lagi setelah data tersinkronisasi.
''';
    }

    final lower = question.toLowerCase();

    // ==========================================================
    // 1. KONDISI KEUANGAN
    // ==========================================================
    if (lower.contains('kondisi') ||
        lower.contains('keuangan') ||
        lower.contains('finansial') ||
        lower.contains('sehat') ||
        lower.contains('keadaanku') ||
        lower.contains('kondisiku')) {
      // 1. Jika belum ada data transaksi sama sekali
      if (data.income <= 0 && data.expense <= 0 && data.transactionCount == 0) {
        return '''
Belum ada data transaksi yang tercatat di akunmu.

Mulai catat transaksi pemasukan dan pengeluaran agar ThinkSpend AI dapat mengevaluasi dan memberikan analisis kesehatan finansialmu.
''';
      }

      if (data.income <= 0) {
        return '''
Belum ada pemasukan yang tercatat di akunmu.

• Pengeluaran: ${formatRupiah(data.expense)}
• Sisa saldo: ${formatRupiah(data.balance)}

Catat pemasukanmu agar ThinkSpend AI dapat mengevaluasi kesehatan finansialmu secara komprehensif.
''';
      }

      final status = FinancialAnalyzer.financialStatus(data);
      final scoreText = data.healthScore != null ? ' dengan skor ${data.healthScore!.toInt()}/100' : '';
      final disclaimer = data.dataDays < 3
          ? '\n\nCatatan: pencatatan transaksi masih tergolong baru (${data.dataDays > 0 ? '${data.dataDays} hari' : 'awal'}), sehingga konsistensi pencatatan perlu ditingkatkan agar analisis pola keuangan jangka panjang semakin akurat.'
          : '';

      if (status == 'Berisiko' || status == 'Perlu Perbaikan') {
        return '''
Kondisi keuanganmu saat ini tergolong Perlu Perbaikan$scoreText.

Pemasukanmu sekitar ${formatRupiah(data.income)}, sedangkan total pengeluaran telah mencapai ${formatRupiah(data.expense)}. Sisa saldo yang tersedia saat ini sekitar ${formatRupiah(data.balance)}.

Pengeluaranmu sangat tinggi atau melebihi pemasukan. Cobalah mengevaluasi kategori pengeluaran terbesar (${data.topExpenseCategory ?? 'pengeluaran harian'}) dan tunda belanja non-prioritas agar arus kasmu kembali positif.$disclaimer
''';
      }

      if (status == 'Perlu diperhatikan' || status == 'Perlu Perhatian') {
        return '''
Kondisi keuanganmu saat ini tergolong Perlu Perhatian$scoreText.

Pemasukanmu sekitar ${formatRupiah(data.income)}, sedangkan pengeluaran sekitar ${formatRupiah(data.expense)}. Sisa saldo yang tersedia sekitar ${formatRupiah(data.balance)}.

Pengeluaranmu mulai mendekati batas pemasukan. Sebaiknya pantau dan batasi pos pengeluaran sekunder agar tetap memiliki ruang yang cukup untuk menabung.$disclaimer
''';
      }

      if (status == 'Keuangan Sehat' || status == 'Sangat Sehat') {
        return '''
Kondisi keuanganmu saat ini tergolong Keuangan Sehat$scoreText.

Pemasukanmu ${formatRupiah(data.income)} dan pengeluaran ${formatRupiah(data.expense)}, sehingga masih terdapat sisa saldo ${formatRupiah(data.balance)}. Arus kasmu positif dan pengeluaran masih terkendali.$disclaimer
''';
      }

      // Cukup sehat
      return '''
Kondisi keuanganmu saat ini tergolong Cukup Sehat$scoreText.

Pemasukanmu sekitar ${formatRupiah(data.income)}, sedangkan pengeluaran sekitar ${formatRupiah(data.expense)}. Dengan kondisi tersebut, sisa saldo yang tersedia saat ini sekitar ${formatRupiah(data.balance)}.

Pengeluaranmu masih berada dalam batas yang relatif terkendali. Pertahankan kebiasaan ini dan sisihkan sebagian dana untuk target tabunganmu.$disclaimer
''';
    }

    // ==========================================================
    // 2. BOROS / PENGELUARAN
    // ==========================================================
    if (lower.contains('boros') ||
        lower.contains('banyak belanja') ||
        lower.contains('kebanyakan belanja') ||
        lower.contains('pengeluaranku') ||
        lower.contains('pola pengeluaran')) {
      final projectedExpense = data.projectedMonthlyExpense;
      final hasProjection =
          data.dataDays >= 3 && projectedExpense > 0 && data.income > 0;

      if (data.income <= 0) {
        return '''
Aku belum bisa menentukan apakah kamu sedang boros karena belum ada catatan pemasukan sebagai pembanding.

Coba catat pemasukanmu terlebih dahulu agar aku bisa membandingkan rasio pengeluaranmu secara objektif.
''';
      }

      if (!hasProjection) {
        final actualPercentage = (data.expense / data.income) * 100;
        return '''
Dari data yang tercatat saat ini, kamu belum bisa langsung dinilai boros. 👌

• Pemasukan: ${formatRupiah(data.income)}
• Pengeluaran: ${formatRupiah(data.expense)} (${actualPercentage.toStringAsFixed(1)}%)

Namun, data aktif baru tercatat ${data.dataDays} hari sehingga belum membentuk proyeksi 30 hari. Terus catat transaksimu agar analisis pola pengeluaran semakin akurat.
''';
      }

      final projectedPercentage = (projectedExpense / data.income) * 100;
      final projectedBalance = data.income - projectedExpense;

      if (projectedPercentage > 100) {
        return '''
Pola pengeluaranmu saat ini tergolong boros dan berisiko.

Rata-rata pengeluaranmu adalah ${formatRupiah(data.averageDailyExpense)}/hari. Jika pola ini terus berlanjut, proyeksi pengeluaran bulananmu bisa mencapai ${formatRupiah(projectedExpense)}, melebihi pemasukanmu (${formatRupiah(data.income)}).

Pengeluaran terbesarmu saat ini ada pada kategori ${data.topExpenseCategory ?? 'Umum'} (${formatRupiah(data.topExpenseAmount)}). Mulailah mengurangi pos pengeluaran tersebut agar tidak terjadi defisit saldo.
''';
      }

      if (projectedPercentage >= 80) {
        return '''
Pola pengeluaranmu saat ini cenderung tinggi dan perlu diwaspadai.

Proyeksi pengeluaran 30 hari diperkirakan mencapai ${formatRupiah(projectedExpense)} (${projectedPercentage.toStringAsFixed(1)}% dari pemasukan). Perkiraan sisa saldo bulananmu hanya sekitar ${formatRupiah(projectedBalance)}.

Sebaiknya prioritaskan pos kebutuhan pokok dan rem pengeluaran di kategori ${data.topExpenseCategory ?? 'Umum'} sebelum akhir bulan.
''';
      }

      if (projectedPercentage >= 60) {
        return '''
Pengeluaranmu saat ini masih relatif terkendali, namun tetap perlu dipantau.

Proyeksi pengeluaran bulananmu sekitar ${formatRupiah(projectedExpense)} (${projectedPercentage.toStringAsFixed(1)}% dari pemasukan) dengan estimasi sisa ${formatRupiah(projectedBalance)}.

Jaga ritme pengeluaran ini agar tidak melonjak di minggu-minggu berikutnya.
''';
      }

      // < 60%
      return '''
Pola pengeluaranmu saat ini sangat sehat dan tidak boros! 👌

Proyeksi pengeluaran bulananmu hanya sekitar ${formatRupiah(projectedExpense)} (${projectedPercentage.toStringAsFixed(1)}% dari pemasukan). Perkiraan sisa saldo mencapai ${formatRupiah(projectedBalance)}.

Pertahankan kebiasaan hemat ini dan manfaatkan kelebihan dana untuk mempercepat pencapaian target tabungan.
''';
    }

    // ==========================================================
    // 3. TARGET KEUANGAN
    // ==========================================================
    if (lower.contains('target') ||
        lower.contains('tabungan') ||
        lower.contains('tercapai') ||
        lower.contains('impian') ||
        lower.contains('goals') ||
        lower.contains('goal')) {
      if (data.goals.isEmpty) {
        return '''
Saat ini kamu belum memiliki target tabungan yang aktif.

Buat target tabungan pertamamu di menu Target agar aku bisa membantu menghitung kebutuhan menabung dan peluang pencapaiannya.
''';
      }

      final goal = _getNearestGoal(data.goals)!;
      final remaining = (goal.targetAmount - goal.currentAmount) > 0
          ? (goal.targetAmount - goal.currentAmount)
          : 0.0;
      final progressPercent = goal.targetAmount > 0
          ? ((goal.currentAmount / goal.targetAmount) * 100).clamp(0, 100)
          : 0.0;

      final availableMoney =
          (data.income - data.expense) > 0 ? (data.income - data.expense) : 0.0;
      final recommendedSaving = availableMoney * 0.40;
      final hasDeadline =
          goal.deadline != null && goal.deadline!.trim().isNotEmpty;
      final requiredMonthly =
          hasDeadline ? _calculateRequiredMonthlySaving(goal) : 0.0;

      if (remaining <= 0) {
        return '''
Target "${goal.name}" sudah berstatus Target Tercapai! 🎉

Kamu telah berhasil mengumpulkan ${formatRupiah(goal.currentAmount)} dari target ${formatRupiah(goal.targetAmount)} (100%).

Selamat atas pencapaian ini! Kamu bisa mulai merencanakan target tabungan berikutnya.
''';
      }

      if (hasDeadline) {
        final months = _calculateRemainingMonths(goal.deadline);
        if (months <= 0) {
          return '''
Target "${goal.name}" berstatus Deadline Terlewat.

• Terkumpul: ${formatRupiah(goal.currentAmount)} dari ${formatRupiah(goal.targetAmount)} (${progressPercent.toStringAsFixed(1)}%)
• Sisa target: ${formatRupiah(remaining)}
• Deadline: ${goal.deadline}

Deadline target ini sudah terlewati. Agar perencanaan tetap terarah, perbarui tanggal deadline target di menu Target.
''';
        }

        if (recommendedSaving >= requiredMonthly && recommendedSaving > 0) {
          return '''
Target "${goal.name}" saat ini berstatus Target Terjangkau.

• Terkumpul: ${formatRupiah(goal.currentAmount)} dari ${formatRupiah(goal.targetAmount)} (${progressPercent.toStringAsFixed(1)}%)
• Sisa target: ${formatRupiah(remaining)}
• Perlu ditabung: ${formatRupiah(requiredMonthly)}/bulan
• Estimasi kemampuan: ${formatRupiah(recommendedSaving)}/bulan

Dengan konsistensi menabung saat ini, target ini sangat realistis untuk dicapai sebelum deadline (${goal.deadline}).
''';
        }

        final shortfall = (requiredMonthly - recommendedSaving) > 0
            ? (requiredMonthly - recommendedSaving)
            : 0.0;

        return '''
Target "${goal.name}" saat ini berstatus Perlu Penyesuaian.

• Sisa target: ${formatRupiah(remaining)}
• Perlu ditabung: ${formatRupiah(requiredMonthly)}/bulan
• Estimasi kemampuan: ${formatRupiah(recommendedSaving)}/bulan
• Selisih kebutuhan: ${formatRupiah(shortfall)}/bulan

Agar target lebih realistis, kamu bisa memperpanjang tanggal deadline atau menyesuaikan nominal target sesuai kemampuan.
''';
      }

      // Target tanpa deadline
      if (recommendedSaving > 0) {
        return '''
Target "${goal.name}" berstatus Target Terjangkau (tanpa deadline).

• Terkumpul: ${formatRupiah(goal.currentAmount)} dari ${formatRupiah(goal.targetAmount)} (${progressPercent.toStringAsFixed(1)}%)
• Sisa target: ${formatRupiah(remaining)}
• Kemampuan menabung: ${formatRupiah(recommendedSaving)}/bulan

Target ini dapat dicapai secara bertahap sesuai kemampuan keuanganmu.
''';
      }

      return '''
Target "${goal.name}" berstatus Perlu Penyesuaian.

Sisa target: ${formatRupiah(remaining)}. Saat ini belum ada estimasi kemampuan menabung yang cukup.

Evaluasi pengeluaranmu terlebih dahulu untuk membuka ruang tabungan.
''';
    }

    // ==========================================================
    // 4. PENGELUARAN TERBESAR
    // ==========================================================
    if (lower.contains('terbesar') ||
        lower.contains('paling banyak') ||
        lower.contains('kategori') ||
        lower.contains('banyak keluar') ||
        lower.contains('keluar di mana') ||
        lower.contains('paling boros')) {
      if (data.expense <= 0 || data.topExpenseCategory == null) {
        return '''
Belum ada catatan pengeluaran di akunmu.

Catat pengeluaran harianmu terlebih dahulu agar aku bisa menganalisis kategori apa yang paling dominan.
''';
      }

      final percentage =
          data.expense > 0 ? (data.topExpenseAmount / data.expense) * 100 : 0.0;

      return '''
Pengeluaran terbesarmu saat ini berasal dari kategori ${data.topExpenseCategory}.

Total pengeluaran di kategori ini mencapai ${formatRupiah(data.topExpenseAmount)}, atau menyumbang sekitar ${percentage.toStringAsFixed(1)}% dari total seluruh pengeluaranmu (${formatRupiah(data.expense)}).

Jika kamu ingin meningkatkan ruang menabung bulanan, mengevaluasi dan mengatur batas pengeluaran pada kategori ini bisa menjadi langkah awal yang paling efektif.
''';
    }

    // ==========================================================
    // 5. KEMAMPUAN MENABUNG
    // ==========================================================
    if (lower.contains('bisa nabung') ||
        lower.contains('kemampuan nabung') ||
        lower.contains('bisa menabung') ||
        lower.contains('tabung berapa') ||
        lower.contains('nabung berapa') ||
        lower.contains('kemampuan menabung')) {
      final availableMoney =
          (data.income - data.expense) > 0 ? (data.income - data.expense) : 0.0;
      final recommendedSaving = availableMoney * 0.40;

      if (data.income <= 0) {
        return '''
Aku belum bisa menghitung kemampuan menabungmu karena belum ada data pemasukan yang tercatat.

Silakan tambahkan data pemasukan terlebih dahulu di menu Transaksi.
''';
      }

      if (availableMoney <= 0) {
        return '''
Saat ini total pengeluaranmu (${formatRupiah(data.expense)}) sudah menyamai atau melebihi pemasukan (${formatRupiah(data.income)}), sehingga belum ada uang tersedia untuk ditabung.

Fokuslah menekan pengeluaran rutin terlebih dahulu agar arus kasmu kembali positif.
''';
      }

      return '''
Berdasarkan kondisi keuanganmu saat ini, estimasi kemampuan menabungmu adalah sekitar ${formatRupiah(recommendedSaving)}/bulan.

Nilai ini dihitung dari estimasi rekomendasi 40% alokasi uang tersedia (${formatRupiah(availableMoney)} dari pemasukan ${formatRupiah(data.income)} dikurangi pengeluaran ${formatRupiah(data.expense)}).

Kamu bisa mengalokasikan nominal ini ke target tabungan prioritasmu secara konsisten setiap bulannya.
''';
    }

    // ==========================================================
    // 6. KEPUTUSAN BELANJA
    // ==========================================================
    if (lower.contains('beli') ||
        lower.contains('belanja') ||
        lower.contains('aman kalau belanja') ||
        lower.contains('boleh beli') ||
        lower.contains('mau beli')) {
      final status = FinancialAnalyzer.financialStatus(data);
      return '''
Sebelum memutuskan untuk membeli barang baru, berikut gambaran kondisi keuanganmu saat ini:

• Sisa Saldo: ${formatRupiah(data.balance)}
• Status Finansial: $status

Jika pembelian ini bersifat sekunder atau impulsif, pastikan tidak mengorbankan pos kebutuhan pokok dan rencana tabungan rutinmu.

💡 Catatan: Pada pengembangan ThinkSpend AI berikutnya, kamu akan dapat memasukkan harga barang secara spesifik untuk dihitung dampak langsungnya ke saldo dan targetmu.
''';
    }

    // ==========================================================
    // 7. FALLBACK QUESTION
    // ==========================================================
    return '''
Aku saat ini dapat membantu menganalisis beberapa topik keuangan seperti:

• Kondisi Keuangan (misal: "Bagaimana kondisi keuanganku?")
• Pola Pengeluaran & Boros (misal: "Apakah aku sedang boros?")
• Target Tabungan (misal: "Apakah targetku bisa tercapai?")
• Pengeluaran Terbesar (misal: "Pengeluaran terbesarku apa?")
• Kemampuan Menabung (misal: "Aku bisa menabung berapa?")
• Keputusan Belanja (misal: "Boleh beli barang ini?")

Coba tanyakan salah satu topik di atas!
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeService.instance,
        PrivacyService.instance,
      ]),
      builder: (context, _) {
        final background = AppColors.background(context);
        final textPrimary = AppColors.textPrimary(context);
        final textSecondary = AppColors.textSecondary(context);
        const blue = AppColors.primaryBlue;

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
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: textPrimary,
                    ),
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
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Personal Financial Coach (Simulated)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Segarkan Data',
                onPressed: _loadFinancialData,
              ),
            ],
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
      },
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryBlue),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return RefreshIndicator(
      onRefresh: _loadFinancialData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hai, ${widget.userName} 👋',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aku bantu kamu memahami dan\nmengelola keuanganmu.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.5,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _buildFinancialSnapshot(),
          const SizedBox(height: 24),
          Text(
            'Apa yang ingin kamu ketahui?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textPrimary,
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

    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final subtleBg = AppColors.subtleBg(context);
    const blue = AppColors.primaryBlue;

    final hasProjection =
        data.dataDays >= 3 && data.projectedMonthlyExpense > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Financial Snapshot',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pemasukan & Pengeluaran
          Row(
            children: [
              Expanded(
                child: _snapshotItem(
                  label: 'Pemasukan',
                  value: formatRupiah(data.income),
                  valueColor: AppColors.green,
                ),
              ),
              Expanded(
                child: _snapshotItem(
                  label: 'Pengeluaran',
                  value: formatRupiah(data.expense),
                  valueColor: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sisa & Transaksi
          Row(
            children: [
              Expanded(
                child: _snapshotItem(
                  label: 'Sisa',
                  value: formatRupiah(data.balance),
                  valueColor: blue,
                ),
              ),
              Expanded(
                child: _snapshotItem(
                  label: 'Transaksi',
                  value: '${data.transactionCount} transaksi',
                  valueColor: textPrimary,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: border),
          ),

          // Data Analysis
          Text(
            'Analisis pola pengeluaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _snapshotItem(
                  label: 'Data tersedia',
                  value: '${data.dataDays} hari',
                  valueColor: textPrimary,
                ),
              ),
              Expanded(
                child: _snapshotItem(
                  label: 'Rata-rata / hari',
                  value: data.dataDays > 0
                      ? formatRupiah(data.averageDailyExpense)
                      : 'Belum tersedia',
                  valueColor: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Proyeksi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasProjection ? blue.withValues(alpha: 0.06) : subtleBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(
                  hasProjection
                      ? Icons.trending_up_rounded
                      : Icons.hourglass_empty_rounded,
                  color: hasProjection ? blue : AppColors.muted(context),
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
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasProjection
                            ? formatRupiah(data.projectedMonthlyExpense)
                            : 'Belum tersedia',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Top Category
          Text(
            'Pengeluaran terbesar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: textSecondary,
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
                    fontSize: 13,
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                formatRupiah(data.topExpenseAmount),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Health Status
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
                    const Icon(Icons.verified_outlined, color: blue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Kondisi: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: textSecondary,
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
                    fontSize: 11,
                    height: 1.45,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SNAPSHOT ITEM
  // ============================================================

  Widget _snapshotItem({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final textSecondary = AppColors.textSecondary(context);
    final textPrimary = AppColors.textPrimary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: valueColor ?? textPrimary,
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
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textSecondary = AppColors.textSecondary(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(
        'Data keuangan belum dapat dibaca.',
        style: TextStyle(color: textSecondary),
      ),
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
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final mutedText = AppColors.muted(context);
    const blue = AppColors.primaryBlue;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: mutedText,
                size: 13,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    const blue = AppColors.primaryBlue;

    // Dynamically re-evaluate AI response if originalQuestion is present so privacy toggles update instantly!
    final displayText =
        (!message.isUser && message.originalQuestion != null)
            ? _generateResponse(message.originalQuestion!)
            : message.text;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? blue : surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser ? null : Border.all(color: border),
        ),
        child: Text(
          displayText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.5,
            color: message.isUser ? Colors.white : textPrimary,
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
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textSecondary = AppColors.textSecondary(context);
    const blue = AppColors.primaryBlue;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: blue,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ThinkSpend AI sedang menganalisis...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: textSecondary,
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
    final background = AppColors.background(context);
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final mutedText = AppColors.muted(context);
    const blue = AppColors.primaryBlue;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: background,
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
                  color: textPrimary,
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
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: blue, width: 1.4),
                  ),
                ),
                onSubmitted: (value) {
                  askAi(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isTyping
                  ? null
                  : () {
                      askAi(messageController.text);
                    },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isTyping ? mutedText : blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
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
  final String? originalQuestion;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.originalQuestion,
  });
}
