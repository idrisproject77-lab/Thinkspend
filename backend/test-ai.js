/**
 * Standalone Test Script for ThinkSpend Backend
 */
import { buildFinancialPrompt } from './src/prompts/thinkspend.prompt.js';

console.log('--- TEST 1: Memverifikasi Konstruksi Prompt Finansial ---');

const testPayload = {
  question: 'Apakah aku sedang boros?',
  financialData: {
    income: 3000000,
    expense: 230000,
    balance: 2770000,
    transactionCount: 4,
    dataDays: 3,
    averageDailyExpense: 76667,
    projectedMonthlyExpense: 2300000,
    projectedRatio: 76.7,
    topExpenseCategory: 'Food',
    topExpenseAmount: 230000,
    healthStatus: 'Perlu diperhatikan',
  },
  goals: [],
};

const generatedPrompt = buildFinancialPrompt(
  testPayload.question,
  testPayload.financialData,
  testPayload.goals
);

console.log('Hasil Konstruksi Prompt:');
console.log(generatedPrompt);

// Validasi logika prompt
const checks = [
  { name: 'Contains Income Rp3.000.000', pass: generatedPrompt.includes('3.000.000') },
  { name: 'Contains Expense Rp230.000', pass: generatedPrompt.includes('230.000') },
  { name: 'Contains Projected Expense Rp2.300.000', pass: generatedPrompt.includes('2.300.000') },
  { name: 'Contains Ratio 76.7%', pass: generatedPrompt.includes('76.7%') },
  { name: 'Contains Data Days 3 hari', pass: generatedPrompt.includes('3 hari') },
  { name: 'Contains Category Food', pass: generatedPrompt.includes('Food') },
  { name: 'Contains Health Status Perlu diperhatikan', pass: generatedPrompt.includes('Perlu diperhatikan') },
  { name: 'Contains Question', pass: generatedPrompt.includes('Apakah aku sedang boros?') },
];

let allPassed = true;
checks.forEach((c) => {
  console.log(`[${c.pass ? 'PASS' : 'FAIL'}] ${c.name}`);
  if (!c.pass) allPassed = false;
});

if (allPassed) {
  console.log('\n✅ SEMUA VALIDASI PROMPT BERHASIL 100%!');
} else {
  console.error('\n❌ ADA VALIDASI PROMPT YANG GAGAL!');
  process.exit(1);
}
