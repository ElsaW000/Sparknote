-- Example SQL migrations for Supabase/Postgres

-- users table (Supabase Auth may manage users; keep for reference)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE,
  provider text,
  created_at timestamptz DEFAULT now()
);

-- users table is usually managed by Supabase Auth; RLS is enforced by auth schema

CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES users(id),
  title text,
  content text,
  summary text,
  visibility text DEFAULT 'private',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- enable RLS and policies for notes
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Notes owner access" ON notes
  FOR ALL USING (owner_id = auth.uid());

CREATE POLICY "Notes insert update delete by owner" ON notes
  FOR INSERT, UPDATE, DELETE WITH CHECK (owner_id = auth.uid());

CREATE TABLE IF NOT EXISTS conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES users(id),
  title text,
  status text DEFAULT 'open',
  created_at timestamptz DEFAULT now(),
  closed_at timestamptz
);

-- RLS for conversations
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Conversations owner access" ON conversations
  FOR ALL USING (owner_id = auth.uid());

CREATE POLICY "Conversations insert update delete by owner" ON conversations
  FOR INSERT, UPDATE, DELETE WITH CHECK (owner_id = auth.uid());

CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES conversations(id),
  sender text,
  text text,
  created_at timestamptz DEFAULT now()
);

-- RLS: allow messages if user owns the conversation
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

CREATE TABLE IF NOT EXISTS attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid REFERENCES users(id),
  note_id uuid REFERENCES notes(id),
  conversation_id uuid REFERENCES conversations(id),
  type text,
  url text,
  meta jsonb,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS for attachments
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;

-- Policy: owner can manage their attachments
CREATE POLICY "Attachments owner access" ON attachments
  FOR ALL USING (owner_id = auth.uid());
