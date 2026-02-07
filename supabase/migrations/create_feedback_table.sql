-- Create feedback table for in-app/customer feedback

CREATE TABLE IF NOT EXISTS public.feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  user_id uuid NULL,
  category text NOT NULL,
  message text NULL,
  email text NULL,
  context jsonb NOT NULL,
  status text NOT NULL DEFAULT 'received',
  source text NOT NULL DEFAULT 'in_app'
);

-- Optional: link to auth.users for convenience (do not cascade delete feedback)
ALTER TABLE public.feedback DROP CONSTRAINT IF EXISTS feedback_user_fk;
ALTER TABLE public.feedback
  ADD CONSTRAINT feedback_user_fk
  FOREIGN KEY (user_id)
  REFERENCES auth.users (id)
  ON DELETE SET NULL;

-- Basic indexes
CREATE INDEX IF NOT EXISTS feedback_created_at_idx
  ON public.feedback (created_at DESC);

CREATE INDEX IF NOT EXISTS feedback_user_id_idx
  ON public.feedback (user_id);

-- Enable RLS
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert feedback for themselves (or anonymously)
DROP POLICY IF EXISTS "Authenticated users can insert feedback" ON public.feedback;
CREATE POLICY "Authenticated users can insert feedback"
  ON public.feedback
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id IS NULL OR user_id = auth.uid());

-- Allow anonymous clients to insert feedback with no user_id
DROP POLICY IF EXISTS "Anonymous users can insert feedback" ON public.feedback;
CREATE POLICY "Anonymous users can insert feedback"
  ON public.feedback
  FOR INSERT
  TO anon
  WITH CHECK (user_id IS NULL);

-- No general SELECT/UPDATE/DELETE policies; only service role should read all feedback.

