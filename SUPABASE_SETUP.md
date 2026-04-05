# DriveID App - Supabase Integration Setup

This Flutter app has been integrated with Supabase for backend data storage. Follow these steps to set up your Supabase project.

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create an account
2. Create a new project
3. Wait for the project to be set up

## 2. Get Your Project Credentials

1. In your Supabase dashboard, go to Settings > API
2. Copy your Project URL and anon/public key
3. Update `lib/config/supabase_config.dart` with your credentials:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  // ... rest of the code
}
```

## 3. Set Up Database Tables

Run these SQL commands in your Supabase SQL Editor:

### Create offense_types table:
```sql
CREATE TABLE offense_types (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  label TEXT NOT NULL,
  fine TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default offense types
INSERT INTO offense_types (label, fine) VALUES
  ('Speeding', 'MWK 25,000'),
  ('Driving without license', 'MWK 50,000'),
  ('Reckless driving', 'MWK 75,000'),
  ('Drunk driving', 'MWK 100,000'),
  ('Dangerous driving', 'MWK 150,000');
```

### Create offenses table:
```sql
CREATE TABLE offenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  registration_number TEXT NOT NULL,
  offense_type_id UUID REFERENCES offense_types(id),
  offense_type TEXT NOT NULL,
  location TEXT NOT NULL,
  status TEXT DEFAULT 'Pending',
  fine TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Create verifications table:
```sql
CREATE TABLE verifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  registration_number TEXT NOT NULL,
  verified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 4. Enable Row Level Security (Optional but Recommended)

For production apps, enable RLS and create policies:

```sql
-- Enable RLS
ALTER TABLE offenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE offense_types ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust based on your auth requirements)
CREATE POLICY "Allow all operations on offenses" ON offenses FOR ALL USING (true);
CREATE POLICY "Allow all operations on verifications" ON verifications FOR ALL USING (true);
CREATE POLICY "Allow read access to offense_types" ON offense_types FOR SELECT USING (true);
```

## 5. Install Dependencies

Run:
```bash
flutter pub get
```

## 6. Run the App

```bash
flutter run
```

## Features Added

- **Dashboard Stats**: Real-time statistics from Supabase
- **Offense Management**: Create and view offenses stored in Supabase
- **License Verification**: Record verification events in Supabase
- **Dynamic Offense Types**: Configurable offense types from database

## API Reference

The app uses these Supabase tables:
- `offenses`: Stores traffic violation records
- `offense_types`: Stores available offense types and fines
- `verifications`: Stores license verification records

All data operations are handled through the service classes in `lib/services/`.