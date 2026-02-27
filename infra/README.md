# Infra notes

This folder contains notes about recommended infrastructure for early prototypes and later production.

Recommendations:
- Use Supabase for Auth/Postgres/Storage for MVP.
- Use Vercel/AWS Lambda for AI orchestration serverless functions that hold AI API keys.
- Use GitHub Actions for CI; add macOS runners or EAS/Bitrise for iOS builds.
