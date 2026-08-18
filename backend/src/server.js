import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import aiRoutes from './routes/ai.routes.js';

// Setup __dirname untuk ES Modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Muat variabel lingkungan dari file .env di root backend
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const app = express();
const PORT = process.env.PORT || 3000;

// ================================================================
// MIDDLEWARES
// ================================================================

// 1. Cross-Origin Resource Sharing (CORS)
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// 2. Request body JSON parser
app.use(express.json({ limit: '1mb' }));

// 3. Request Logger sederhana (tanpa membocorkan isi data/key sensitif)
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// ================================================================
// ROUTES
// ================================================================

app.use('/api', aiRoutes);

// Root greeting
app.get('/', (req, res) => {
  res.json({
    name: 'ThinkSpend AI Backend Service',
    version: '1.0.0',
    endpoints: {
      health: 'GET /api/health',
      chat: 'POST /api/ai/chat',
    },
  });
});

// 404 Route Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: `Route ${req.method} ${req.originalUrl} tidak ditemukan.`,
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[Unhandled Server Error]:', err.message);
  res.status(500).json({
    success: false,
    answer: 'Maaf, terjadi kesalahan internal pada server ThinkSpend.',
    error: err.message || 'Internal Server Error',
  });
});

// ================================================================
// START SERVER
// ================================================================

app.listen(PORT, '0.0.0.0', () => {
  console.log('====================================================');
  console.log(`🚀 ThinkSpend AI Backend aktif di port: ${PORT}`);
  console.log(`📡 URL Health Check: http://localhost:${PORT}/api/health`);
  console.log(`🤖 URL Chat AI Endpoint: http://localhost:${PORT}/api/ai/chat`);
  console.log(`🔑 Model Gemini: ${process.env.GEMINI_MODEL || 'gemini-2.5-flash'}`);
  console.log('====================================================');
});

export default app;
