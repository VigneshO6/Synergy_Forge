-- ==============================================================================
-- ONION SMART - SUPABASE DATABASE SCHEMA
-- PostgreSQL schema for Supabase Authentication, Profiles, Batches, and Quality Reports
-- ==============================================================================

-- 1. Create Profiles Table (Linked to Supabase Auth auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'procurement' CHECK (role IN ('procurement', 'seller', 'admin')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT gmail_only_constraint CHECK (email ILIKE '%@gmail.com')
);

-- 2. Create Batches Table
CREATE TABLE IF NOT EXISTS public.batches (
    id TEXT PRIMARY KEY, -- e.g. BTH-2026-0098
    supplier_name TEXT NOT NULL,
    contact_number TEXT,
    location TEXT NOT NULL,
    total_quantity_kg NUMERIC(10, 2) NOT NULL,
    purchase_price_per_kg NUMERIC(10, 2) NOT NULL,
    procurement_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'Pending Analysis',
    notes TEXT,
    qr_code_data TEXT,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Quality Reports Table
CREATE TABLE IF NOT EXISTS public.quality_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id TEXT NOT NULL REFERENCES public.batches(id) ON DELETE CASCADE,
    total_detected INTEGER NOT NULL DEFAULT 0,
    good_count INTEGER NOT NULL DEFAULT 0,
    defective_count INTEGER NOT NULL DEFAULT 0,
    sprouted_count INTEGER NOT NULL DEFAULT 0,
    urs_count INTEGER NOT NULL DEFAULT 0,
    good_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.0,
    defective_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.0,
    sprouted_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.0,
    urs_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0.0,
    overall_quality TEXT NOT NULL,
    observations JSONB DEFAULT '[]'::jsonb,
    analyzed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create Analysis Records Table (Logs from Deep Learning Engine)
CREATE TABLE IF NOT EXISTS public.analysis_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id TEXT REFERENCES public.batches(id) ON DELETE SET NULL,
    image_url TEXT,
    engine_version TEXT DEFAULT 'DeepLearning-YOLO11+MobileNetV3',
    detections JSONB DEFAULT '[]'::jsonb,
    calibers JSONB DEFAULT '{}'::jsonb,
    processing_time_ms NUMERIC(10, 2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quality_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analysis_records ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
-- Profiles: Any authenticated user can read profiles; users can update their own
CREATE POLICY "Public profiles are viewable by authenticated users" 
ON public.profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can insert their own profile" 
ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Batches: Read and write for authenticated users
CREATE POLICY "Batches viewable by authenticated users" 
ON public.batches FOR SELECT TO authenticated USING (true);

CREATE POLICY "Batches insertable by authenticated users" 
ON public.batches FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Batches updatable by authenticated users" 
ON public.batches FOR UPDATE TO authenticated USING (true);

-- Quality Reports: Read and write for authenticated users
CREATE POLICY "Quality reports viewable by authenticated users" 
ON public.quality_reports FOR SELECT TO authenticated USING (true);

CREATE POLICY "Quality reports insertable by authenticated users" 
ON public.quality_reports FOR INSERT TO authenticated WITH CHECK (true);

-- 7. Trigger to automatically create a public.profiles row when auth.users is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Strict Gmail Domain Validation at Database Trigger Level
  IF NEW.email NOT ILIKE '%@gmail.com' THEN
    RAISE EXCEPTION 'Only @gmail.com email addresses are allowed.';
  END IF;

  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    LOWER(NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Inspector'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'procurement')
  )
  ON CONFLICT (id) DO UPDATE
  SET full_name = EXCLUDED.full_name,
      role = EXCLUDED.role,
      updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Bind Trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
