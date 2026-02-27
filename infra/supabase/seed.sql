-- Supabase / Postgres seed script for Sparknote (example data)
-- Run this in Supabase SQL editor or via psql against your project's DB.

-- Ensure required extensions (pgcrypto for gen_random_uuid)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  uid uuid := gen_random_uuid();
  nid uuid := gen_random_uuid();
  cid uuid := gen_random_uuid();
BEGIN
  -- sample user
  INSERT INTO users (id, email, provider) VALUES (uid, 'alice@example.com', 'email');

  -- sample note owned by user
  INSERT INTO notes (id, owner_id, title, content, summary) VALUES (
    nid,
    uid,
    'Seed: Morning Idea',
    'I had an idea about a lightweight notes app that captures voice and images.',
    NULL
  );

  -- sample conversation with messages
  INSERT INTO conversations (id, owner_id, title, status) VALUES (cid, uid, 'Brainstorm with AI', 'open');

  INSERT INTO messages (id, conversation_id, sender, text) VALUES (gen_random_uuid(), cid, 'user', 'What if Sparknote auto-summarizes my conversation?');
  INSERT INTO messages (id, conversation_id, sender, text) VALUES (gen_random_uuid(), cid, 'ai', 'It can — summarize, extract tags, and suggest actions.');

  -- sample attachment
  INSERT INTO attachments (id, owner_id, note_id, type, url, meta) VALUES (
    gen_random_uuid(), uid, nid, 'image', 'https://example.com/sample.jpg', '{"width":800,"height":600}'::jsonb
  );
END
$$;

-- Optional: show inserted sample rows
SELECT u.id as user_id, n.id as note_id, c.id as conversation_id
FROM users u
LEFT JOIN notes n ON n.owner_id = u.id
LEFT JOIN conversations c ON c.owner_id = u.id
WHERE u.email = 'alice@example.com';
