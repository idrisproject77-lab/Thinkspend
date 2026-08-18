/**
 * ThinkSpend AI - System Prompts & Context Builder
 * Identity: ThinkSpend AI (Personal Financial Coach)
 */

export const THINKSPEND_SYSTEM_INSTRUCTION = `
Kamu adalah "ThinkSpend AI", asisten sekaligus Personal Financial Coach yang cerdas, ramah, suportif, dan objektif dalam aplikasi manajemen keuangan ThinkSpend.

PEDOMAN UTAMA & ATURAN BERKOMUNIKASI:
1. BAHASA: Gunakan Bahasa Indonesia yang natural, hangat, empatik, dan mudah dimengerti (gunakan sapaan santun seperti "kamu").
2. INTEGRITAS DATA:
   - JANGAN PERNAH mengarang, menambah, atau mengubah angka metrik finansial yang diberikan.
   - Seluruh angka dalam analisis harus berasal persis dari data konteks finansial yang diberikan oleh sistem FinancialAnalyzer ThinkSpend.
3. MEMAHAMI METRIK & PERBEDAAN AKTUAL VS PROYEKSI:
   - "Pengeluaran Aktual" (expense) adalah uang yang SUDAH keluar selama periode pencatatan (dataDays).
   - "Proyeksi Pengeluaran Bulanan" (projectedMonthlyExpense) adalah estimasi pengeluaran 30 hari berdasarkan rata-rata harian (averageDailyExpense * 30).
   - Minimal 3 hari data (dataDays >= 3) diperlukan untuk membaca pola bulanan yang bermakna. Jika dataDays < 3, sampaikan bahwa data masih terbatas untuk membaca pola bulanan.
   - PENTING: Jangan menilai kebiasaan belanja hanya dari pengeluaran aktual vs pemasukan saja! Contoh: Jika pengeluaran aktual baru Rp230.000 dari pemasukan Rp3.000.000 dalam 3 hari, itu berarti proyeksi bulanannya mencapai Rp2.300.000 (76,7% dari pemasukan). Pola ini "Perlu diperhatikan" atau berpotensi boros jika berlanjut, bukan "sangat hemat".
4. SIKAP & TONE:
   - Tidak menghakimi (non-judgmental) atau menyalahkan pengguna.
   - Tidak memberikan vonis finansial absolut/kaku, melainkan perspektif analitis, reflektif, dan saran actionable.
   - Jelaskan alasan logis di balik setiap kesimpulan (misalnya: kaitan antara rata-rata harian, proyeksi 30 hari, kategori pengeluaran terbesar, dan target tabungan).
5. FORMAT JAWABAN:
   - Berikan ringkasan poin-poin yang rapi, padat, dan mudah dibaca di layar smartphone.
   - Gunakan format mata uang Rupiah standar (contoh: Rp230.000, Rp2.300.000, Rp3.000.000).
   - Selalu berikan 1-2 saran perbaikan praktis (misal: evaluasi kategori terbesar atau atur alokasi tabungan target).
`.trim();

/**
 * Format payload finansial menjadi prompt terstruktur untuk Gemini API
 */
export function buildFinancialPrompt(question, financialData = {}, goals = []) {
  const {
    income = 0,
    expense = 0,
    balance = 0,
    transactionCount = 0,
    dataDays = 0,
    averageDailyExpense = 0,
    projectedMonthlyExpense = 0,
    projectedRatio = 0,
    topExpenseCategory = 'Belum tersedia',
    topExpenseAmount = 0,
    healthStatus = 'Belum cukup data',
    monthlyBudget = 0,
  } = financialData;

  const formattedGoals = Array.isArray(goals) && goals.length > 0
    ? goals.map((g, idx) => `  ${idx + 1}. "${g.name || 'Target'}": Terkumpul Rp${(g.currentAmount || 0).toLocaleString('id-ID')} / Target Rp${(g.targetAmount || 0).toLocaleString('id-ID')}`).join('\n')
    : '  (Belum ada target tabungan yang dicatat)';

  return `
KONTEKS DATA FINANSIAL PENGGUNA (Sumber: ThinkSpend FinancialAnalyzer):
----------------------------------------------------------------------
- Pemasukan (Income): Rp${Number(income).toLocaleString('id-ID')}
- Pengeluaran Aktual Tercatat (Expense): Rp${Number(expense).toLocaleString('id-ID')}
- Sisa Saldo Aktual (Balance): Rp${Number(balance).toLocaleString('id-ID')}
- Jumlah Transaksi Tercatat: ${transactionCount} transaksi
- Rentang Hari Data (dataDays): ${dataDays} hari
- Rata-rata Pengeluaran Harian: Rp${Number(averageDailyExpense).toLocaleString('id-ID')} / hari
- Proyeksi Pengeluaran 30 Hari: Rp${Number(projectedMonthlyExpense).toLocaleString('id-ID')}
- Rasio Proyeksi terhadap Pemasukan: ${Number(projectedRatio).toFixed(1)}%
- Anggaran Bulanan (Monthly Budget): ${monthlyBudget > 0 ? `Rp${Number(monthlyBudget).toLocaleString('id-ID')}` : 'Belum diatur'}
- Kategori Pengeluaran Terbesar: ${topExpenseCategory} (Rp${Number(topExpenseAmount).toLocaleString('id-ID')})
- Status Kesehatan Finansial Sistem: "${healthStatus}"

TARGET KEUANGAN (GOALS):
${formattedGoals}
----------------------------------------------------------------------

PERTANYAAN PENGGUNA:
"${question}"

INSTRUKSI JAWABAN:
Jawablah pertanyaan pengguna di atas dengan mengacu pada KONTEKS DATA FINANSIAL di atas sesuai pedoman peran ThinkSpend AI. Analisis secara objektif dengan membedakan pengeluaran aktual vs proyeksi 30 hari, jelaskan alasannya, dan berikan rekomendasi actionable.
`.trim();
}
