# Supabase deployment & seed instructions

This folder contains a seed script and instructions to create the database objects for Sparknote in a Supabase project or a Postgres instance.

Prerequisites
- Supabase project (https://supabase.com) or local Supabase CLI stack
- `supabase` CLI (optional for local development)
- `psql` (optional if you prefer using the DB connection string)

Quick options to apply schema + seed

1) Use Supabase SQL editor (web dashboard)
   - Open your Supabase project → SQL Editor → New query
   - Paste the contents of `db/migrations/001_create_tables.sql` and run
   - Paste the contents of `infra/supabase/seed.sql` and run

2) Using `psql` with project connection string
   - Get the DB connection string from Supabase dashboard (Settings → Database → Connection string)
   - Run locally:

```bash
# example (replace with your connection string)
psql "postgresql://postgres:YOUR_PASSWORD@db_host:5432/postgres" -f db/migrations/001_create_tables.sql
psql "postgresql://postgres:YOUR_PASSWORD@db_host:5432/postgres" -f infra/supabase/seed.sql
```

3) Using Supabase CLI (local dev)
   - Install CLI: https://supabase.com/docs/guides/cli
   - Start local stack (optional):

```bash
supabase start
# push SQL to the local DB (or use the SQL editor against local instance)
psql "postgresql://postgres:postgres@localhost:54322/postgres" -f db/migrations/001_create_tables.sql
psql "postgresql://postgres:postgres@localhost:54322/postgres" -f infra/supabase/seed.sql
```

Security notes
- Supabase Auth manages `users` by default; the `users` table in migrations is an example. If you use Supabase Auth, map `auth.users` to application users.
- Do NOT commit production DB credentials to the repo. Use environment variables or Supabase project settings.

Next steps
- After seeding, configure Storage buckets for attachments (images/audio/video) in the Supabase dashboard.
- Create RLS (row-level security) policies to restrict access so only owners or explicitly-shared users can read/write notes and attachments.
  A simple example policy set is provided below; you can add it in the SQL editor or include it as part of further migrations.

  ```sql
  -- assume all tables have an `owner_id uuid` column
  ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Notes owner access" ON notes
    FOR ALL USING (owner_id = auth.uid());
  CREATE POLICY "Notes insert update delete by owner" ON notes
    FOR INSERT, UPDATE, DELETE WITH CHECK (owner_id = auth.uid());

  ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Attachments owner access" ON attachments
    FOR ALL USING (owner_id = auth.uid());

  ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Conversations owner access" ON conversations
    FOR ALL USING (owner_id = auth.uid());
  CREATE POLICY "Conversations insert update delete by owner" ON conversations
    FOR INSERT, UPDATE, DELETE WITH CHECK (owner_id = auth.uid());

  ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
  CREATE POLICY "Messages conversation owner" ON messages
    FOR ALL USING (
      EXISTS(
        SELECT 1 FROM conversations c
        WHERE c.id = conversation_id AND c.owner_id = auth.uid()
      )
    );
  CREATE POLICY "Messages insert check" ON messages
    FOR INSERT WITH CHECK (
      EXISTS(
        SELECT 1 FROM conversations c
        WHERE c.id = conversation_id AND c.owner_id = auth.uid()
      )
    );
  ```
