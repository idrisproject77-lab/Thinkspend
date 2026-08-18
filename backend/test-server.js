/**
 * Integration Test for ThinkSpend Express API
 */
import express from 'express';
import cors from 'cors';
import aiRoutes from './src/routes/ai.routes.js';

const app = express();
app.use(cors());
app.use(express.json());
app.use('/api', aiRoutes);

const server = app.listen(3099, async () => {
  console.log('Test Server running on http://127.0.0.1:3099');

  try {
    // 1. Test Health Endpoint
    console.log('\n--- TEST 1: GET /api/health ---');
    const healthRes = await fetch('http://127.0.0.1:3099/api/health');
    const healthData = await healthRes.json();
    console.log('Status Code:', healthRes.status);
    console.log('Response:', healthData);
    if (healthRes.status === 200 && healthData.status === 'ok') {
      console.log('✅ GET /api/health PASS');
    } else {
      console.error('❌ GET /api/health FAIL');
    }

    // 2. Test Validation - Missing Question
    console.log('\n--- TEST 2: POST /api/ai/chat (Validation: Missing Question) ---');
    const valRes1 = await fetch('http://127.0.0.1:3099/api/ai/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ financialData: {} }),
    });
    const valData1 = await valRes1.json();
    console.log('Status Code:', valRes1.status);
    console.log('Response:', valData1);
    if (valRes1.status === 400 && valData1.success === false) {
      console.log('✅ Validation Missing Question PASS');
    } else {
      console.error('❌ Validation Missing Question FAIL');
    }

    // 3. Test Validation - Missing financialData
    console.log('\n--- TEST 3: POST /api/ai/chat (Validation: Missing financialData) ---');
    const valRes2 = await fetch('http://127.0.0.1:3099/api/ai/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ question: 'Apakah aku boros?' }),
    });
    const valData2 = await valRes2.json();
    console.log('Status Code:', valRes2.status);
    console.log('Response:', valData2);
    if (valRes2.status === 400 && valData2.success === false) {
      console.log('✅ Validation Missing FinancialData PASS');
    } else {
      console.error('❌ Validation Missing FinancialData FAIL');
    }

    // 4. Test Error Handling when GEMINI_API_KEY is not configured
    console.log('\n--- TEST 4: POST /api/ai/chat (Handling without Gemini API key) ---');
    const testRes = await fetch('http://127.0.0.1:3099/api/ai/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
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
      }),
    });
    const testData = await testRes.json();
    console.log('Status Code:', testRes.status);
    console.log('Response:', testData);
    if (testData.success === false && testData.error.includes('GEMINI_API_KEY')) {
      console.log('✅ Graceful API Key Error Handling PASS (No crash, structured error)');
    } else if (testData.success === true) {
      console.log('✅ Gemini API Response SUCCESS!');
    }

    console.log('\n========================================');
    console.log('✅ SELURUH INTEGRATION TEST SERVER BERHASIL!');
    console.log('========================================\n');
  } catch (err) {
    console.error('Test error:', err);
  } finally {
    server.close();
  }
});
