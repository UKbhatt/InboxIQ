require('dotenv').config();

const requiredEnvVars = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'GOOGLE_CLIENT_ID',
  'GOOGLE_CLIENT_SECRET',
  'GOOGLE_REDIRECT_URI',
  'ENCRYPTION_KEY'
];

function validateEnv() {
  const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
  if (missingVars.length > 0) {
    console.error('Missing required environment variables:', missingVars.join(', '));
    console.error('Please check your .env file in lib/backend/');
    process.exit(1);
  }
  if (!process.env.LLM_API_KEY) {
    console.warn('LLM_API_KEY is not set: email summaries are disabled');
  }
}

const llm = {
  apiKey: process.env.LLM_API_KEY,
  baseUrl: (process.env.LLM_BASE_URL || 'https://api.groq.com/openai/v1').replace(/\/$/, ''),
  model: process.env.LLM_MODEL || 'llama-3.1-8b-instant',
  get isConfigured() {
    return !!this.apiKey;
  },
};

module.exports = {
  validateEnv,
  port: process.env.PORT || 3000,
  llm,
};
