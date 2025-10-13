-- Migration Script: Add minbar_ prefix to all tables
-- Run this in Supabase SQL Editor

-- Step 1: Rename tables
ALTER TABLE IF EXISTS khutbahs RENAME TO minbar_khutbahs;
ALTER TABLE IF EXISTS speech_logs RENAME TO minbar_speech_logs;
ALTER TABLE IF EXISTS content_items RENAME TO minbar_content_items;
ALTER TABLE IF EXISTS user_favorites RENAME TO minbar_user_favorites;
ALTER TABLE IF EXISTS templates RENAME TO minbar_templates;

-- Step 2: Update foreign key constraints (if any reference old table names)
-- Note: Foreign keys should automatically update with table rename, but verify

-- Step 3: Update indexes (they should rename automatically, but verify)
-- Check with: SELECT * FROM pg_indexes WHERE tablename LIKE 'minbar_%';

-- Step 4: Update RLS policies (they should stay with the table, but verify)
-- Check with: SELECT * FROM pg_policies WHERE tablename LIKE 'minbar_%';

-- Verification queries:
-- List all tables with minbar_ prefix
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'minbar_%'
ORDER BY table_name;

-- Check foreign keys
SELECT
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name LIKE 'minbar_%';

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename LIKE 'minbar_%'
ORDER BY tablename, policyname;

-- Check indexes
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE tablename LIKE 'minbar_%'
ORDER BY tablename, indexname;
