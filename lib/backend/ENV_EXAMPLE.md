Create a .env file in lib/backend/ with the following variables:

PORT=3000
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_REDIRECT_URI=http://localhost:3000/api/oauth/callback
ENCRYPTION_KEY=your_32_byte_hex_encryption_key

# Optional: email summaries via any OpenAI-compatible chat API.
# Defaults target Groq's free tier with Llama 3.1 8B.
LLM_API_KEY=your_groq_api_key
LLM_BASE_URL=https://api.groq.com/openai/v1
LLM_MODEL=llama-3.1-8b-instant

To generate ENCRYPTION_KEY, run:
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"