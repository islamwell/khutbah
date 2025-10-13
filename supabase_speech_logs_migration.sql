-- Create speech_logs table
CREATE TABLE IF NOT EXISTS speech_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  khutbah_id UUID NOT NULL REFERENCES khutbahs(id) ON DELETE CASCADE,
  khutbah_title TEXT NOT NULL,
  delivery_date TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT NOT NULL,
  event_type TEXT NOT NULL,
  audience_size INTEGER,
  audience_demographics TEXT,
  positive_feedback TEXT NOT NULL DEFAULT '',
  negative_feedback TEXT NOT NULL DEFAULT '',
  general_notes TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  modified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_speech_logs_user_id ON speech_logs(user_id);
CREATE INDEX idx_speech_logs_khutbah_id ON speech_logs(khutbah_id);
CREATE INDEX idx_speech_logs_delivery_date ON speech_logs(delivery_date DESC);

-- Enable Row Level Security
ALTER TABLE speech_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own speech logs
CREATE POLICY "Users can view their own speech logs"
  ON speech_logs FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own speech logs
CREATE POLICY "Users can insert their own speech logs"
  ON speech_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own speech logs
CREATE POLICY "Users can update their own speech logs"
  ON speech_logs FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policy: Users can delete their own speech logs
CREATE POLICY "Users can delete their own speech logs"
  ON speech_logs FOR DELETE
  USING (auth.uid() = user_id);
