-- ============================================
-- Storage Buckets for BioBiz
-- ============================================

-- Create the main storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'biobiz',
  'biobiz',
  true,
  5242880, -- 5MB max file size
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'audio/mp4', 'audio/mpeg', 'audio/wav']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Storage RLS Policies
-- ============================================

-- Anyone can view public files (card images, logos)
CREATE POLICY "Public read access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'biobiz');

-- Authenticated users can upload to their own folder
CREATE POLICY "Users can upload to own folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'biobiz'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN ('profiles', 'scans', 'contacts', 'recordings')
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

-- Users can update their own files
CREATE POLICY "Users can update own files"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'biobiz'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

-- Users can delete their own files
CREATE POLICY "Users can delete own files"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'biobiz'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );
