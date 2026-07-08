# Jarvis AI Assistant

> A production-ready Personal AI Assistant built with FastAPI, Flutter, Groq, PostgreSQL, pgvector, RAG, Long-Term Memory, and Tool Calling.

[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Railway](https://img.shields.io/badge/Deploy-Railway-purple?logo=railway)](https://railway.app)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## Overview

Jarvis is not a chatbot wrapper. It is a Personal AI Operating System designed to know its user deeply — remembering goals, learning from conversations, retrieving personal knowledge, and using external tools when needed.

The core philosophy: every response should be personal, contextual, and grounded — not generic.

---

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/home.jpeg" width="180"/><br/><sub>Home</sub></td>
    <td align="center"><img src="docs/screenshots/chat.jpeg" width="180"/><br/><sub>Chat</sub></td>
    <td align="center"><img src="docs/screenshots/sidebar.jpeg" width="180"/><br/><sub>Sidebar</sub></td>
    <td align="center"><img src="docs/screenshots/memory.jpeg" width="180"/><br/><sub>Memory</sub></td>
    <td align="center"><img src="docs/screenshots/voice.jpeg" width="180"/><br/><sub>Voice</sub></td>
  </tr>
</table>

---

## Tech Stack

### Backend

| Layer | Technology |
|---|---|
| Framework | FastAPI (Python 3.11) |
| ORM | SQLAlchemy |
| Primary Database | PostgreSQL (Railway) |
| Vector Database | Supabase + pgvector |
| Embedding Model | sentence-transformers/all-MiniLM-L6-v2 |
| LLM | Groq — llama-3.3-70b-versatile |
| Web Search | Tavily API |
| Deployment | Railway + GitHub CI |

### Mobile

| Layer | Technology |
|---|---|
| Framework | Flutter (Android) |
| Voice Input | speech_to_text |
| Voice Output | flutter_tts |
| State Management | Provider |

---

## Features

### AI Chat

- Multi-session conversation with persistent history
- Auto-generated conversation titles from first message
- Rename and delete conversations
- Sidebar navigation (ChatGPT-style)
- Context-aware responses across sessions

### Memory System

Jarvis maintains three layers of memory:

| Layer | Description |
|---|---|
| **Global Memory** | Persistent facts about the user (name, goals, skills, projects) — injected into every conversation |
| **Auto Extraction** | Facts are automatically extracted from natural conversation and stored without manual input |
| **Conversation History** | Per-session message history used for short-term context |

**Example:**

```
Session A:
User: My name is Kycal and I'm learning Flutter.

Session B (new conversation, days later):
User: What am I learning right now?
Jarvis: You are currently learning Flutter.
```

### Static Context Injection

Jarvis loads structured Markdown files as its "identity layer" on every request:

```
context/
├── profile/
│   ├── identity.md       # Who the user is
│   ├── goals.md          # Short and long-term goals
│   ├── preferences.md    # Learning and communication style
│   ├── personality.md    # Character, strengths, decision style
│   └── projects.md       # Active projects and status
├── prompts/
│   ├── system.md         # Core directive
│   ├── response_style.md # How Jarvis should respond
│   └── advisor.md        # How Jarvis should advise
└── config/
    └── capabilities.json # Feature flags
```

This allows Jarvis to answer as a personalized advisor rather than a generic assistant.

### Knowledge Base (RAG)

Personal documents are indexed and retrieved semantically at query time.

```
Markdown File
     ↓
  Chunking
     ↓
 Embedding (sentence-transformers)
     ↓
Supabase pgvector
     ↓
Semantic Retrieval (cosine similarity)
     ↓
  LLM Context
     ↓
   Answer
```

Supported formats: `.md` (Phase 4), with PDF and source code planned for Phase 5.

### Tool Calling

The LLM autonomously decides when to use a tool based on the query and conversation history.

| Tool | Trigger | Description |
|---|---|---|
| `web_search` | Real-time info needed | Tavily API search |
| `read_url` | URL present in query | Full page content extraction |
| `rag_retrieval` | Personal knowledge query | pgvector semantic search |

**Context-aware routing example:**

```
User: Who won the Champions League match tonight?
→ tool: web_search ✅

User: Who scored the goals?
→ tool: web_search ✅  (follow-up context detected)

User: What are my current projects?
→ tool: none  (answered from context/profile/projects.md)
```

**Prompt injection protection:** When a tool is used, the LLM is constrained to answer only from the tool result. If the tool result does not contain sufficient information, Jarvis states that explicitly rather than hallucinating.

### Voice Assistant

- Full voice input via STT on Android
- Auto-activates microphone on fresh app launch
- Reads responses aloud via TTS
- Activated via ColorOS screen-off gesture (no unlock required)

---

## Architecture

```
┌─────────────────────────────────────────┐
│              Flutter (Android)           │
│  Voice Input │ Chat UI │ Knowledge Mgmt  │
└──────────────────┬──────────────────────┘
                   │ HTTPS
┌──────────────────▼──────────────────────┐
│              FastAPI Backend             │
│                                          │
│  ┌─────────────┐   ┌──────────────────┐ │
│  │   Context   │   │  Tool Router     │ │
│  │   Builder   │   │  web_search      │ │
│  │  (MD files) │   │  read_url        │ │
│  └──────┬──────┘   └────────┬─────────┘ │
│         │                   │            │
│  ┌──────▼──────┐   ┌────────▼─────────┐ │
│  │   Memory    │   │   RAG Pipeline   │ │
│  │   System    │   │   pgvector       │ │
│  └──────┬──────┘   └────────┬─────────┘ │
│         └─────────┬─────────┘            │
│                   │                      │
│  ┌────────────────▼─────────────────┐   │
│  │         Groq LLM                 │   │
│  │    llama-3.3-70b-versatile       │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
         │                    │
┌────────▼──────┐   ┌─────────▼──────────┐
│  PostgreSQL   │   │  Supabase          │
│  (Railway)    │   │  pgvector          │
│  Conversations│   │  Knowledge chunks  │
│  Memory       │   │  Embeddings        │
└───────────────┘   └────────────────────┘
```

---

## API Reference

### Chat

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/chat` | Send message, returns response + tool/rag metadata |

**Request:**
```json
{
  "message": "What are my current projects?",
  "conversation_id": "optional-uuid"
}
```

**Response:**
```json
{
  "conversation_id": "uuid",
  "title": "Current Projects",
  "response": "...",
  "tool_used": null,
  "rag_used": true
}
```

### Conversations

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/conversations` | List all conversations |
| `GET` | `/conversations/{id}` | Get conversation with messages |
| `PATCH` | `/conversations/{id}/title` | Rename conversation |
| `DELETE` | `/conversations/{id}` | Delete conversation |

### Knowledge Base

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/knowledge/files` | List indexed files |
| `POST` | `/knowledge/upload` | Upload and ingest new MD file |
| `POST` | `/knowledge/ingest/all` | Re-ingest all files |
| `POST` | `/knowledge/ingest/file` | Ingest specific file |
| `DELETE` | `/knowledge/files/{filename}` | Remove file from index |

### Memory

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/memory` | List all memories |
| `POST` | `/memory` | Save a memory manually |
| `DELETE` | `/memory/{key}` | Delete a memory |

---

## Installation

### Prerequisites

- Python 3.11+
- Flutter 3.x
- PostgreSQL (Railway or local)
- Supabase account (for pgvector)
- Groq API key
- Tavily API key

### Backend

```bash
# Clone repository
git clone https://github.com/icalkyrie-dotcom/cognex-core.git
cd cognex-core/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your credentials
```

**Required environment variables:**

```env
DATABASE_URL=postgresql://...
VECTOR_DATABASE_URL=postgresql://...     # Supabase
GROQ_API_KEY=gsk_...
TAVILY_API_KEY=tvly-...
APP_SECRET_KEY=your-secret-key
LLM_PROVIDER=groq
EMBEDDING_PROVIDER=sentence_transformers
```

```bash
# Run development server
uvicorn main:app --reload
```

### Flutter

```bash
cd mobile

# Install dependencies
flutter pub get

# Update API endpoint
# Edit lib/core/constants.dart

# Run on connected Android device
flutter run

# Build release APK
flutter build apk --release
```

---

## Documentation

| Document | Description |
|---|---|
| [API Reference](docs/API.md) | Full endpoint documentation |
| [Architecture](docs/Architecture.md) | System design and data flow |
| [Backend Guide](docs/Backend.md) | Backend setup and structure |
| [Flutter Guide](docs/Flutter.md) | Mobile app structure and setup |
| [Roadmap](docs/Roadmap.md) | Full development roadmap |
| [Limitations](docs/Limitations.md) | Known limitations and planned fixes |

---

## Roadmap

<details>
<summary><b>Phase 1 ✅ Complete — Core Foundation</b></summary>

- FastAPI + PostgreSQL + Groq
- Railway deployment + GitHub CI
- Flutter Android app
- Voice Input (STT) + Voice Output (TTS)
- Gesture launcher (screen-off gesture)
- Multi-session conversation
- UI polish (bubble chat, timestamp, auto-expand input)

</details>

<details>
<summary><b>Phase 2 ✅ Complete — Memory & Session</b></summary>

- PostgreSQL migration
- Conversation sessions with sidebar
- Rename, delete, switch conversations
- Auto-generated conversation titles
- Global Memory System (cross-conversation)
- Auto Memory Extraction from conversation
- Static Context Injection via Markdown files

</details>

<details>
<summary><b>Phase 3 ✅ Complete — Tool Calling</b></summary>

- Tool Calling Framework with LLM router
- Web Search via Tavily API
- URL Reader (full page extraction)
- Context-aware follow-up routing (history-aware)
- Prompt injection protection (anti-hallucination)
- Flutter tool source indicators

</details>

<details>
<summary><b>Phase 4 ✅ Complete — Knowledge Base</b></summary>

- Supabase PostgreSQL + pgvector
- Provider-agnostic EmbeddingService abstraction
- Ingest pipeline: chunking → embedding → vector store
- Semantic retrieval (cosine similarity, threshold-based)
- Knowledge Management API (upload, ingest, delete)
- Flutter RAG source indicator
- Production verified on Railway

</details>

**Phase 5 — Proactive Memory** `In Progress`

- 5A: Auto conversation summary → knowledge base ingest
- 5B: Note taking tool (`save_note`)
- 5C: Conversation archive with semantic retrieval
- 5D: Multi-tool chaining

**Phase 6 — Agent Architecture** `Planned`

- ReAct loop (Reason → Act → Observe)
- Long-running background tasks
- Autonomous workflow execution

**Phase 7 — Ambient AI** `Planned`

- Hotword / always-listening detection
- Android notification system
- Desktop integration
- Multi-device sync

---

## Capability Map

| Capability | Status |
|---|---|
| Voice Input / Output | ✅ |
| Gesture Launch | ✅ |
| Multi Conversation + Sidebar | ✅ |
| Global Memory | ✅ |
| Auto Memory Extraction | ✅ |
| Static Context (MD files) | ✅ |
| Tool Calling Framework | ✅ |
| Web Search | ✅ |
| URL Reader | ✅ |
| Context-aware Tool Routing | ✅ |
| RAG Knowledge Base | ✅ |
| Knowledge Management API | ✅ |
| Auto Conversation Summary | ⏳ Phase 5A |
| Note Taking Tool | ⏳ Phase 5B |
| Multi-tool Chaining | ⏳ Phase 5D |
| Agent Architecture | ⏳ Phase 6 |
| Always Listening | ⏳ Phase 7 |

---

## Current Limitations

| Limitation | Detail | Planned Fix |
|---|---|---|
| Web search snippet depth | Tavily free tier returns short snippets; detailed stats (scorers, lineups) may not be available | Upgrade to Tavily pro or add URL reader fallback for rich sources |
| Embedding model scale | `all-MiniLM-L6-v2` (384 dim) is optimized for speed, not maximum retrieval accuracy | Upgrade to OpenAI `text-embedding-3-small` — EmbeddingService abstraction already supports this |
| Knowledge formats | Currently supports `.md` only | PDF, DOCX, source code ingestion planned Phase 5 |
| Single device | Android only | Desktop and multi-device sync planned Phase 7 |
| No background tasks | Summarization requires explicit trigger | Background scheduler planned Phase 6 |

---

## Current Status

| Component | Status |
|---|---|
| Backend | Stable |
| Production (Railway) | Live |
| Memory System | Working |
| Knowledge Base (RAG) | Working |
| Tool Calling | Working |
| Flutter (Android) | Working |
| Voice | Working |

---

## Future Vision

Jarvis is being built toward a single goal:

> **A Personal AI Operating System that remembers, learns, plans, and acts — on behalf of its user.**

Not a smarter search engine. Not a glorified chatbot.

The target end state:

```
Remember   → knows the user's history, goals, and context
Learn      → extracts knowledge from every conversation
Plan       → breaks complex goals into executable steps
Execute    → takes action via tools and automations
Exist      → available on all devices, always accessible
```

The north star metric is simple: how many times per day does the user open Jarvis instead of ChatGPT or Google?

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Contact

**Faisal Atmaja**

| Platform | Link |
|---|---|
| GitHub | [github.com/icalkyrie-dotcom](https://github.com/icalkyrie-dotcom) |
| LinkedIn | [linkedin.com/in/faisal-atmaja-b38330356](https://www.linkedin.com/in/faisal-atmaja-b38330356) |
| Email | faisalatmaja30@gmail.com |
