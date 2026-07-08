# API Reference

This document provides an overview of the REST API exposed by the Jarvis backend.

---

## Base URL

Development

```text
http://127.0.0.1:8000
```

Production

```text
Configured through Railway deployment.
```

---

## Main Endpoints

### Chat

| Method | Endpoint | Description |
|---------|----------|-------------|
| POST | `/chat` | Send a message to Jarvis |

---

### Conversations

| Method | Endpoint |
|---------|----------|
| GET | `/conversations` |
| GET | `/conversations/{id}` |
| PATCH | `/conversations/{id}/title` |
| DELETE | `/conversations/{id}` |

---

### Memory

| Method | Endpoint |
|---------|----------|
| GET | `/memory` |
| POST | `/memory` |
| DELETE | `/memory/{key}` |

---

### Knowledge Base

| Method | Endpoint |
|---------|----------|
| GET | `/knowledge/files` |
| POST | `/knowledge/upload` |
| POST | `/knowledge/ingest/all` |
| POST | `/knowledge/ingest/file` |
| DELETE | `/knowledge/files/{filename}` |

---

Additional request and response examples will be added as the project evolves.