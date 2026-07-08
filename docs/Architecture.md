# Architecture

Jarvis follows a modular architecture designed to separate responsibilities between the mobile application, backend services, memory system, retrieval pipeline, and external tools.

---

## High Level Architecture

```text
Flutter
    │
HTTPS
    │
FastAPI
    │
├── Conversation Manager
├── Memory System
├── Context Builder
├── Tool Router
└── RAG Pipeline
        │
        ├── PostgreSQL
        ├── Supabase pgvector
        └── Groq LLM
```

---

## Core Components

- Flutter Android Client
- FastAPI Backend
- PostgreSQL
- Supabase pgvector
- Groq LLM
- Tavily Search
- Static Markdown Context
- Tool Calling Framework

---

A more detailed architecture diagram will be added in future updates.