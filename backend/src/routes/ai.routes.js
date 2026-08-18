import { Router } from 'express';
import { chatWithAi, healthCheck } from '../controllers/ai.controller.js';

const router = Router();

// Health check endpoint
router.get('/health', healthCheck);

// Chat & Financial Analysis AI endpoint
router.post('/ai/chat', chatWithAi);

export default router;
