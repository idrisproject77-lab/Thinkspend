import { geminiService } from '../services/gemini.service.js';

/**
 * Mengubah string status kesehatan menjadi format snake_case standar
 */
function normalizeStatus(healthStatus) {
  if (!healthStatus || typeof healthStatus !== 'string') {
    return 'belum_cukup_data';
  }

  const clean = healthStatus.trim().toLowerCase();
  if (clean.includes('perlu') || clean.includes('perhatikan')) return 'perlu_diperhatikan';
  if (clean.includes('sehat') || clean.includes('cukup')) return 'cukup_sehat';
  if (clean.includes('risiko') || clean.includes('berisiko')) return 'berisiko';
  return 'belum_cukup_data';
}

/**
 * Controller untuk menangani endpoint POST /api/ai/chat
 */
export async function chatWithAi(req, res) {
  try {
    const { question, financialData, goals = [] } = req.body || {};

    // 1. Validasi question
    if (!question || typeof question !== 'string' || question.trim() === '') {
      return res.status(400).json({
        success: false,
        answer: 'Maaf, pertanyaan tidak boleh kosong.',
        error: 'Field "question" wajib diisi dengan teks yang valid.',
      });
    }

    // 2. Validasi financialData
    if (!financialData || typeof financialData !== 'object' || Array.isArray(financialData)) {
      return res.status(400).json({
        success: false,
        answer: 'Maaf, data finansial pengguna tidak ditemukan.',
        error: 'Field "financialData" wajib berupa objek data finansial.',
      });
    }

    // 3. Sanitasi & validasi tipe data dasar
    const sanitizedData = {
      income: Number(financialData.income) || 0,
      expense: Number(financialData.expense) || 0,
      balance: Number(financialData.balance) || 0,
      transactionCount: parseInt(financialData.transactionCount, 10) || 0,
      dataDays: parseInt(financialData.dataDays, 10) || 0,
      averageDailyExpense: Number(financialData.averageDailyExpense) || 0,
      projectedMonthlyExpense: Number(financialData.projectedMonthlyExpense) || 0,
      projectedRatio: Number(financialData.projectedRatio) || 0,
      topExpenseCategory: typeof financialData.topExpenseCategory === 'string' ? financialData.topExpenseCategory : 'Belum tersedia',
      topExpenseAmount: Number(financialData.topExpenseAmount) || 0,
      healthStatus: typeof financialData.healthStatus === 'string' ? financialData.healthStatus : 'Belum cukup data',
      monthlyBudget: Number(financialData.monthlyBudget) || 0,
    };

    const sanitizedGoals = Array.isArray(goals) ? goals : [];
    const normalizedStatus = normalizeStatus(sanitizedData.healthStatus);

    // 4. Kirim konteks ke Gemini Service
    const aiAnswer = await geminiService.generateFinancialAdvice(
      question.trim(),
      sanitizedData,
      sanitizedGoals
    );

    // 5. Response terstruktur untuk client
    return res.status(200).json({
      success: true,
      answer: aiAnswer,
      status: normalizedStatus,
    });
  } catch (error) {
    // Log error secara aman tanpa mencetak credential
    console.error(`[AI Controller Error]: ${error.message}`);

    const isApiKeyError = error.message.includes('GEMINI_API_KEY');
    const isTimeout = error.message.includes('batas waktu');

    return res.status(isApiKeyError ? 500 : isTimeout ? 504 : 500).json({
      success: false,
      answer: 'Maaf, ThinkSpend AI sedang mengalami kendala saat memproses jawaban.',
      error: error.message,
    });
  }
}

/**
 * Controller untuk health check backend
 */
export function healthCheck(req, res) {
  return res.status(200).json({
    status: 'ok',
    service: 'thinkspend-backend',
    timestamp: new Date().toISOString(),
  });
}
