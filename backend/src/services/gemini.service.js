import { GoogleGenAI } from '@google/genai';
import { THINKSPEND_SYSTEM_INSTRUCTION, buildFinancialPrompt } from '../prompts/thinkspend.prompt.js';

class GeminiService {
  constructor() {
    this._client = null;
  }

  /**
   * Mengambil instance client GoogleGenAI secara lazy.
   * API key dibaca dari environment variable (tidak pernah di-hardcode).
   */
  getClient() {
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey || apiKey.trim() === '' || apiKey === 'your_gemini_api_key_here') {
      throw new Error('GEMINI_API_KEY belum dikonfigurasi di file backend/.env');
    }

    if (!this._client) {
      this._client = new GoogleGenAI({ apiKey });
    }

    return this._client;
  }

  /**
   * Menghasilkan jawaban AI berdasarkan pertanyaan dan data finansial ThinkSpend.
   * 
   * @param {string} question Pertanyaan dari user
   * @param {object} financialData Metrik dari FinancialAnalyzer
   * @param {Array} goals Daftar target finansial
   * @returns {Promise<string>} Jawaban teks yang sudah diformat
   */
  async generateFinancialAdvice(question, financialData, goals = []) {
    const ai = this.getClient();
    const model = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
    const timeoutMs = parseInt(process.env.GEMINI_TIMEOUT_MS, 10) || 15000;

    const userPrompt = buildFinancialPrompt(question, financialData, goals);

    // Timeout wrapper dengan Promise.race
    const apiPromise = ai.models.generateContent({
      model,
      contents: userPrompt,
      config: {
        systemInstruction: THINKSPEND_SYSTEM_INSTRUCTION,
        temperature: 0.3,
        maxOutputTokens: 1024,
      },
    });

    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => {
        reject(new Error(`Permintaan ke Gemini API melebihi batas waktu (${timeoutMs / 1000} detik)`));
      }, timeoutMs);
    });

    const response = await Promise.race([apiPromise, timeoutPromise]);

    if (!response || !response.text) {
      throw new Error('Tidak ada respon teks yang diterima dari Gemini API');
    }

    return response.text.trim();
  }
}

export const geminiService = new GeminiService();
