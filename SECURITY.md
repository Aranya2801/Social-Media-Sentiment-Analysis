# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | ✅ Actively maintained |
| < 1.0   | ❌ Not supported   |

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via:
- **Email**: security@aranyaghosh.org
- **Subject**: `[SMSIP SECURITY] Brief description`

Include:
1. Type of issue (SQL injection, XSS, authentication bypass, etc.)
2. Full path of source file(s) related to the issue
3. Location of the affected source code (tag/branch/commit or direct URL)
4. Step-by-step instructions to reproduce
5. Proof-of-concept or exploit code (if possible)
6. Impact of the issue, including how an attacker might exploit it

You will receive a response within **48 hours**. If you do not hear back, please follow up.

## Security Best Practices for Self-Hosting

1. **Rotate `SECRET_KEY`** — Use `openssl rand -hex 32`
2. **Never commit `.env`** — Always use environment variables
3. **Use strong passwords** for PostgreSQL, Redis, Grafana
4. **Enable TLS** in production — Configure via reverse proxy (nginx/caddy)
5. **Restrict network access** — Use private VPC/subnet for internal services
6. **Rate limiting** — Default: 100 req/min per IP
7. **Update dependencies** — Run `safety check -r requirements.txt` regularly
8. **Review model access** — Hugging Face model downloads should use verified checksums

## Known Security Considerations

- Models downloaded from Hugging Face: verify checksums match official releases
- LLM API keys have access to external services — scope them appropriately
- Redis is used as a cache — do not store sensitive user data with long TTLs
- Kafka topics are not encrypted by default in development — enable TLS in production
