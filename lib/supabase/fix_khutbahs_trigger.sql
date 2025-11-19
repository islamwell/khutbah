-- Fix the khutbahs trigger to use modified_at instead of updated_at
-- This fixes the error: record "new" has no field "updated_at"

-- Create a new function specifically for khutbahs table that updates modified_at
CREATE OR REPLACE FUNCTION update_modified_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.modified_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Drop the old trigger on khutbahs (and minbar_khutbahs if renamed)
DROP TRIGGER IF EXISTS update_khutbahs_modified_at ON khutbahs;
DROP TRIGGER IF EXISTS update_khutbahs_modified_at ON minbar_khutbahs;

-- Create new trigger on minbar_khutbahs table using the correct function
CREATE TRIGGER update_khutbahs_modified_at BEFORE UPDATE ON minbar_khutbahs
    FOR EACH ROW EXECUTE FUNCTION update_modified_at_column();

-- Add comment for documentation
COMMENT ON FUNCTION update_modified_at_column() IS
'Trigger function to automatically update the modified_at timestamp for khutbahs table';
