-- SQLite Schema

CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_uid TEXT UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  priority INTEGER NOT NULL DEFAULT 1,
  is_completed INTEGER NOT NULL DEFAULT 0,
  is_read INTEGER NOT NULL DEFAULT 0,
  due_date TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  source INTEGER NOT NULL DEFAULT 0,
  created_by_agent_id TEXT,
  completed_at TEXT,
  tags TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0,
  last_synced_at TEXT,
  assigned_to TEXT,
  assigned_to_type TEXT,
  assigned_by TEXT,
  assigned_at TEXT,
  allow_dispatch INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_is_completed ON tasks(is_completed);
CREATE INDEX IF NOT EXISTS idx_tasks_is_read ON tasks(is_read);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);

CREATE TABLE IF NOT EXISTS conversations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  agent_id TEXT NOT NULL,
  title TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  message_count INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  last_message_content TEXT,
  is_pinned INTEGER NOT NULL DEFAULT 0,
  total_tokens INTEGER,
  metadata TEXT
);

CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at);
CREATE INDEX IF NOT EXISTS idx_conversations_is_active ON conversations(is_active);

CREATE TABLE IF NOT EXISTS messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  conversation_id INTEGER NOT NULL,
  agent_id TEXT NOT NULL,
  role INTEGER NOT NULL,
  content TEXT NOT NULL,
  status INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  error TEXT,
  token_count INTEGER,
  metadata TEXT,
  FOREIGN KEY(conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

CREATE TABLE IF NOT EXISTS task_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL,
  action_type INTEGER NOT NULL,
  timestamp TEXT NOT NULL,
  performed_by TEXT NOT NULL,
  changes TEXT,
  description TEXT,
  can_undo INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_task_actions_task_id ON task_actions(task_id);
