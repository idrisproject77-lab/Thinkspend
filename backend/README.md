# ThinkSpend AI Backend Service

Backend API terpisah untuk fitur **ThinkSpend AI Personal Financial Coach** menggunakan **Node.js + Express** dan SDK resmi Google Gemini (`@google/genai`).

---

## 📁 Struktur Direktori

```text
backend/
├── src/
│   ├── server.js               # Entry point Express, CORS, router
│   ├── routes/
│   │   └── ai.routes.js        # Route /api/ai/chat & /api/health
│   ├── controllers/
│   │   └── ai.controller.js    # Validasi payload input, sanitasi, error handling
│   ├── services/
│   │   └── gemini.service.js   # Integrasi resmi @google/genai SDK & Timeout
│   └── prompts/
│       └── thinkspend.prompt.js # System Instruction & Financial Context Builder
├── .env                        # Konfigurasi lokal rahasia (TIDAK di-commit ke Git)
├── .env.example                # Template variabel lingkungan
├── .gitignore                  # Mengabaikan node_modules dan .env
├── package.json
└── README.md
```

---

## 🚀 Cara Menjalankan Backend

### 1. Konfigurasi Environment
Salin template `.env.example` ke `.env` dan masukkan API Key Gemini Anda:
```bash
GEMINI_API_KEY=AIzaSy...
PORT=3000
GEMINI_MODEL=gemini-2.5-flash
GEMINI_TIMEOUT_MS=15000
```

### 2. Jalankan Server
```bash
# Masuk ke folder backend
cd backend

# Production mode
npm start

# Development mode (auto-reload)
npm run dev
```

---

## 📡 Endpoint API

### 1. `GET /api/health`
Mengecek status ketersediaan backend.

**Response (200 OK)**:
```json
{
  "status": "ok",
  "service": "thinkspend-backend",
  "timestamp": "2026-08-18T06:30:00.000Z"
}
```

---

### 2. `POST /api/ai/chat`
Mengirimkan pertanyaan pengguna beserta snapshot konteks data keuangan dari `FinancialAnalyzer`.

**Request Body**:
```json
{
  "question": "Apakah aku sedang boros?",
  "financialData": {
    "income": 3000000,
    "expense": 230000,
    "balance": 2770000,
    "transactionCount": 4,
    "dataDays": 3,
    "averageDailyExpense": 76667,
    "projectedMonthlyExpense": 2300000,
    "projectedRatio": 76.7,
    "topExpenseCategory": "Food",
    "topExpenseAmount": 230000,
    "healthStatus": "Perlu diperhatikan",
    "monthlyBudget": 0
  },
  "goals": []
}
```

**Response Sukses (200 OK)**:
```json
{
  "success": true,
  "answer": "Pola pengeluaranmu saat ini perlu diperhatikan...",
  "status": "perlu_diperhatikan"
}
```

**Response Error (400 / 500 / 504)**:
```json
{
  "success": false,
  "answer": "Maaf, ThinkSpend AI sedang mengalami kendala saat memproses jawaban.",
  "error": "Pesan deskripsi error teknis"
}
```
