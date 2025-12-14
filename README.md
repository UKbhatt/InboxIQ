# 📧 InboxIQ - Intelligent Email Access Platform

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-%23339933.svg?style=for-the-badge&logo=Node.js&logoColor=white)
![Express.js](https://img.shields.io/badge/Express.js-%23000000.svg?style=for-the-badge&logo=Express&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-%233ECF8E.svg?style=for-the-badge&logo=Supabase&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white)
![JWT](https://img.shields.io/badge/JWT-%23000000.svg?style=for-the-badge&logo=jsonwebtokens&logoColor=white)
![Gemini AI](https://img.shields.io/badge/Gemini_AI-4285F4?style=for-the-badge&logo=Google&logoColor=white)
![AI](https://img.shields.io/badge/AI-Powered-6A5ACD?style=for-the-badge&logo=OpenAI&logoColor=white)


A modern, feature-rich email management application built with Flutter and Node.js, providing seamless Gmail integration with intelligent email organization and access.

## 🔐 Login & Test Account Usage

### 📌 Important Notice — Use Test Accounts Only

This application is currently in **development mode**, and the Gmail OAuth consent screen is in **Testing** status.

Because of this:

- Only **whitelisted test users** in Google Cloud Console can log in using Gmail OAuth.
- If you are **not** added as a test user, Google will block login and show:  
  **“Access blocked: This app is not verified.”**

---

## 👤 How to Log In

You can log in to InboxIQ in two ways:

### 1️⃣ Supabase Email/Password Login

You can create an account using your:

- Email  
- Password  

This will allow you to access the app and connect Gmail later.

### 2️⃣ Gmail Login (For Test Users Only)

To use Gmail features (Inbox, Drafts, Sent, Attachments, etc.),  
you **must log in using a Google account added as a test user**.

If you are a tester, please use the following test account:

### 📧 Test Gmail Account (For Development Only)

Email: utkb30938@gmail.com <br>
Password: test@123

⚠️ Use only this test account.

 --- 
 
## ✨ Features

- 🔐 **Hybrid Authentication System** - Secure Supabase authentication with email/password
- 🔗 **Gmail OAuth Integration** - Seamless Gmail account connection with read-only access
- 📬 **Email Management** - View and organize emails by type (Inbox, Sent, Drafts, Starred, Unread, Trash, Spam)
- 🔄 **Automatic Email Sync** - Background synchronization of up to 500 latest emails
- 📎 **Attachment Support** - View and download email attachments
- 🎨 **Rich Email Display** - HTML rendering with inline images and formatting
- 📱 **Cross-Platform** - Works on Android and iOS
- 🔒 **Secure Token Storage** - Encrypted OAuth tokens with AES-256-CBC
- 🎯 **Clean Architecture** - Feature-based modular structure

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Riverpod** - State management
- **Dio** - HTTP client
- **Supabase Flutter** - Authentication and database client
- **flutter_html** - HTML email rendering

### Backend
- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **Google APIs** - Gmail API integration
- **Supabase** - PostgreSQL database and authentication
- **Crypto** - Token encryption

### Infrastructure
- **Supabase** - Database, authentication, and storage
- **Google Cloud Console** - OAuth 2.0 credentials
- **Cloudflare Tunnel** - Public HTTPS tunnel for development

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0 or higher)
  ```bash
  flutter --version
  ```
- **Node.js** (18.0 or higher)
  ```bash
  node --version
  ```
- **npm** (comes with Node.js)
  ```bash
  npm --version
  ```
- **Supabase Account** - [Sign up here](https://supabase.com)
- **Google Cloud Console Project** - [Create here](https://console.cloud.google.com)
- **Cloudflare Tunnel** (for development) - [Download here](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/)

## 📁 Project Structure

```
inboxiq/
├── lib/
│   ├── features/              # Feature-based modules
│   │   ├── auth/             # Authentication feature
│   │   │   ├── domain/       # Business logic layer
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   ├── data/         # Data layer
│   │   │   │   ├── datasources/
│   │   │   │   ├── models/
│   │   │   │   └── repositories/
│   │   │   └── presentation/ # UI layer
│   │   │       ├── providers/
│   │   │       └── screens/
│   │   └── email/            # Email feature
│   │       ├── domain/
│   │       ├── data/
│   │       └── presentation/
│   │           ├── providers/
│   │           ├── screens/
│   │           └── widgets/
│   ├── backend/              # Node.js backend
│   │   ├── config/           # Configuration files
│   │   ├── controllers/      # Request handlers
│   │   ├── middleware/       # Express middleware
│   │   ├── routes/           # API routes
│   │   ├── services/         # Business logic
│   │   └── utils/            # Utility functions
│   ├── core/                 # Shared utilities
│   │   ├── constants/
│   │   ├── di/               # Dependency injection
│   │   ├── errors/
│   │   └── utils/
│   └── main.dart             # App entry point
├── supabase/
│   └── schema.sql            # Database schema
└── .env                      # Environment variables
```

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd inboxiq
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Install Backend Dependencies

```bash
cd lib/backend
npm install
cd ../..
```

## ⚙️ Configuration

### 1. Supabase Setup

1. Create a new project at [Supabase](https://supabase.com)
2. Go to **Settings** → **API** and copy:
   - Project URL
   - `anon` public key
   - `service_role` secret key
3. Run the database schema:
   ```sql
   -- Execute supabase/schema.sql in Supabase SQL Editor
   ```

### 2. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable **Gmail API**
4. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
5. Configure OAuth consent screen:
   - User Type: External
   - Publishing status: Testing
   - Add test users (your Gmail account)
   - Scopes: `https://www.googleapis.com/auth/gmail.readonly`
6. Create OAuth 2.0 Client ID:
   - Application type: Web application
   - Authorized redirect URIs: `https://your-cloudflare-url.trycloudflare.com/api/oauth/callback`

### 3. Environment Variables

#### Flutter (.env in project root)

Create `.env` file in the project root:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
API_BASE_URL=https://your-cloudflare-url.trycloudflare.com
```

#### Backend (lib/backend/.env)

Create `.env` file in `lib/backend/`:

```env
PORT=3000
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_REDIRECT_URI=https://your-cloudflare-url.trycloudflare.com/api/oauth/callback
ENCRYPTION_KEY=your_32_byte_hex_encryption_key
```

**Generate Encryption Key:**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 4. Cloudflare Tunnel Setup (Development)

1. Download Cloudflare Tunnel
2. Start tunnel:
   ```bash
   cloudflared tunnel --url http://localhost:3000
   ```
3. Copy the generated URL (e.g., `https://xxxxx.trycloudflare.com`)
4. Update `.env` files with the new URL
5. Update Google Cloud Console redirect URI

## 🏃 Running the Application

### Start Backend Server

```bash
cd lib/backend
npm start
```

The server will start on `http://localhost:3000`

### Start Cloudflare Tunnel (in separate terminal)

```bash
cloudflared tunnel --url http://localhost:3000
```

### Run Flutter App

```bash
flutter run
```

## 📡 API Endpoints

### Health Check
- `GET /health` - Server health status

### OAuth
- `GET /api/oauth/connect` - Generate OAuth URL (requires auth)
- `GET /api/oauth/callback` - Handle OAuth callback
- `POST /api/oauth/verify` - Verify authorization code (requires auth)
- `GET /api/oauth/connect/status` - Check connection status (requires auth)

### Emails
- `GET /api/emails` - Get emails list
  - Query params: `limit`, `offset`, `type` (inbox, sent, draft, starred, unread, trash, spam)
- `GET /api/emails/:emailId` - Get email details
- `GET /api/emails/:emailId/attachments/:attachmentId` - Get attachment
- `POST /api/emails/sync` - Start email sync
- `GET /api/emails/sync/status` - Get sync status

## 🏗️ Architecture

### Frontend Architecture (Clean Architecture)

**Features:**
- **Domain**: Entities, repositories (interfaces), use cases
- **Data**: Models, repository implementations, data sources
- **Presentation**: Screens, widgets, providers (Riverpod)

### Backend Architecture (MVC Pattern)

```
Routes → Controllers → Services → Database/APIs
```

**Layers:**
- **Routes**: Express route definitions
- **Controllers**: Request/response handling
- **Services**: Business logic
- **Config**: Configuration files
- **Middleware**: Authentication, logging
- **Utils**: Helper functions

## 🔐 Security Features

- ✅ Encrypted OAuth tokens (AES-256-CBC)
- ✅ Row-level security in Supabase
- ✅ JWT token authentication
- ✅ Secure token refresh mechanism
- ✅ Environment variable protection
- ✅ HTTPS via Cloudflare Tunnel

## 🐛 Troubleshooting

### Backend Issues
These are the error faced by me while integrating backend Google client and Application

**"Connection refused" error:**
- Ensure backend is running on port 3000
- Check firewall settings
- Verify `API_BASE_URL` in Flutter `.env`

**"redirect_uri_mismatch" error:**
- Verify Cloudflare URL matches Google Cloud Console redirect URI exactly
- Check for trailing slashes
- Ensure URL is HTTPS

## 📝 Database Schema

Key tables:
- `oauth_tokens` - Encrypted OAuth tokens
- `emails` - Synced email data
- `email_sync_status` - Sync progress tracking

See `supabase/schema.sql` for full schema.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🌍 Contact
**💻 Author: Utkarsh**<br>
**📧 Email: ubhatt2004@gmail.com**<br>
**🐙 GitHub: https://github.com/UKbhatt**<br>

## 🙏 Acknowledgments

- [Supabase](https://supabase.com) for backend infrastructure
- [Flutter](https://flutter.dev) for cross-platform development
- [Google Gmail API](https://developers.google.com/gmail/api) for email access

---

**Note:** This application requires Google OAuth consent screen approval for production use. For development, use test users in Google Cloud Console.
