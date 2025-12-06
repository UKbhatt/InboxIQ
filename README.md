# InboxIQ V1 - Intelligent Email Access Platform

A Flutter application with Node.js backend for intelligent email access using Gmail API.

## Tech Stack

- **Frontend**: Flutter with Riverpod for state management
- **Backend**: Node.js with Express
- **Database**: Supabase (PostgreSQL + Auth)
- **OAuth**: Google OAuth 2.0
- **Email API**: Gmail API

## Architecture

The project follows clean architecture principles:

- **Domain Layer**: Entities, repository interfaces, use cases
- **Data Layer**: Repository implementations, data sources, models
- **Presentation Layer**: UI screens, providers, widgets

## Setup Instructions

### Prerequisites

- Flutter SDK (3.8.1+)
- Node.js (18+)
- Supabase account
- Google Cloud Console project with Gmail API enabled

### 1. Supabase Setup

1. Create a new Supabase project
2. Run the SQL schema from `supabase/schema.sql` in the Supabase SQL editor
3. Note your Supabase URL and anon key

### 2. Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Gmail API
4. Create OAuth 2.0 credentials (Web application)
5. Add authorized redirect URI: `http://localhost:3000/api/oauth/callback`
6. Note your Client ID and Client Secret

### 3. Backend Setup

1. Navigate to `lib/backend/`
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create `.env` file (see `lib/backend/ENV_EXAMPLE.md`):
   ```env
   PORT=3000
   SUPABASE_URL=your_supabase_url
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
   GOOGLE_CLIENT_ID=your_google_client_id
   GOOGLE_CLIENT_SECRET=your_google_client_secret
   GOOGLE_REDIRECT_URI=http://localhost:3000/api/oauth/callback
   ENCRYPTION_KEY=your_32_byte_hex_encryption_key
   ```
4. Generate encryption key:
   ```bash
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```
5. Start the server:
   ```bash
   npm start
   ```

### 4. Flutter Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Create `.env` file in project root (or use compile-time constants):
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   API_BASE_URL=http://localhost:3000
   ```
3. Update `lib/main.dart` with your Supabase credentials or use environment variables
4. Run the app:
   ```bash
   flutter run
   ```

## Features

- **Hybrid Authentication**: Supabase email/password sign-up and sign-in
- **Google OAuth Integration**: Secure Gmail connection with read-only access
- **Email Retrieval**: Fetch and display emails from Gmail inbox
- **Token Management**: Automatic token refresh and encryption
- **Clean Architecture**: Separation of concerns with domain, data, and presentation layers

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── di/
│   ├── errors/
│   └── utils/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    └── screens/

lib/backend/
├── index.js
├── package.json
└── .env

supabase/
└── schema.sql
```

## Security

- OAuth tokens are encrypted using AES-256-CBC before storage
- Row-level security (RLS) policies enforce user data isolation
- Access tokens are automatically refreshed when expired
- Limited Gmail API scopes (read-only access)

## License

ISC
