-- Create user_khutbahs table for storing user-specific khutbah data
CREATE TABLE IF NOT EXISTS user_khutbahs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    khutbah_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tags TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    modified_at TIMESTAMP WITH TIME ZONE NOT NULL,
    estimated_minutes INTEGER NOT NULL DEFAULT 0,
    folder_id TEXT,
    synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, khutbah_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_khutbahs_user_id ON user_khutbahs(user_id);
CREATE INDEX IF NOT EXISTS idx_user_khutbahs_modified_at ON user_khutbahs(modified_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE user_khutbahs ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to only access their own khutbahs
CREATE POLICY "Users can only access their own khutbahs" ON user_khutbahs
    FOR ALL USING (auth.uid() = user_id);

-- Create users profile table (if not exists)
CREATE TABLE IF NOT EXISTS users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create content_items table for storing user-contributed content
CREATE TABLE IF NOT EXISTS content_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content_id TEXT NOT NULL,
    text TEXT NOT NULL,
    translation TEXT NOT NULL,
    source TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('quran', 'hadith', 'quote')),
    authenticity TEXT CHECK (authenticity IN ('sahih', 'hasan', 'daif') OR authenticity IS NULL),
    surah_name TEXT,
    verse_number INTEGER,
    keywords TEXT NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, content_id)
);

-- Enable RLS for users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policy for users table
CREATE POLICY "Users can only access their own profile" ON users
    FOR ALL USING (auth.uid() = id);

-- Create index for users table
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create indexes for content_items table
CREATE INDEX IF NOT EXISTS idx_content_items_user_id ON content_items(user_id);
CREATE INDEX IF NOT EXISTS idx_content_items_type ON content_items(type);
CREATE INDEX IF NOT EXISTS idx_content_items_public ON content_items(is_public);

-- Enable RLS for content_items table
ALTER TABLE content_items ENABLE ROW LEVEL SECURITY;

-- Create policy for content_items table
CREATE POLICY "Users can manage their own content items" ON content_items
    FOR ALL USING (auth.uid() = user_id);

-- Create policy for public content items (read-only)
CREATE POLICY "Anyone can read public content items" ON content_items
    FOR SELECT USING (is_public = true);

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function when a new user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();