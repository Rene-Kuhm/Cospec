-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT NOT NULL,
  role TEXT CHECK (role IN ('admin', 'technician')) NOT NULL DEFAULT 'technician',
  approved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create complaints table
CREATE TABLE public.complaints (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  service_type TEXT CHECK (service_type IN ('telefono', 'telefono_internet', 'fibra_optica', 'tv', 'tv_fibra_optica')) NOT NULL,
  phone_number TEXT NOT NULL,
  internet_number TEXT,
  customer_name TEXT NOT NULL,
  address TEXT NOT NULL,
  reason TEXT NOT NULL,
  received_by UUID REFERENCES auth.users NOT NULL,
  technician_id UUID REFERENCES auth.users,
  status TEXT CHECK (status IN ('pendiente', 'en_proceso', 'resuelto')) DEFAULT 'pendiente' NOT NULL,
  technician_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  resolved_at TIMESTAMP WITH TIME ZONE
);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_complaints_updated_at
  BEFORE UPDATE ON public.complaints
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Only admins can update profiles"
  ON public.profiles
  FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
      AND approved = true
  ));

CREATE POLICY "Only admins can view all profiles"
  ON public.profiles
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
      AND approved = true
  ));

-- Complaints policies
CREATE POLICY "Admins can do everything"
  ON public.complaints
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
      AND approved = true
  ));

CREATE POLICY "Technicians can view assigned complaints"
  ON public.complaints
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'technician'
        AND approved = true
    )
    AND (
      technician_id = auth.uid()
      OR status = 'pendiente'
    )
  );

CREATE POLICY "Technicians can update assigned complaints"
  ON public.complaints
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'technician'
        AND approved = true
    )
    AND technician_id = auth.uid()
  );

-- Create indexes for better performance
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_approved ON public.profiles(approved);
CREATE INDEX idx_complaints_status ON public.complaints(status);
CREATE INDEX idx_complaints_technician ON public.complaints(technician_id);
CREATE INDEX idx_complaints_service_type ON public.complaints(service_type);

-- Create buckets for file storage
INSERT INTO storage.buckets (id, name, public) 
VALUES ('complaints', 'complaints', false);

-- Enable storage policies
CREATE POLICY "Authenticated users can upload complaint files"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'complaints');

CREATE POLICY "Users can view their own complaint files"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'complaints'
    AND (EXISTS (
      SELECT 1 FROM public.complaints c
      WHERE c.id::text = storage.objects.name
        AND (
          c.technician_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
              AND role = 'admin'
              AND approved = true
          )
        )
    ))
  );