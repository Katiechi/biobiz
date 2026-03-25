-- ============================================
-- Security fixes
-- ============================================

-- Restrict card event insertion to authenticated users only
-- (was: anyone including anonymous could insert, enabling analytics spam)
DROP POLICY IF EXISTS "Anyone can insert card events" ON public.card_events;
CREATE POLICY "Authenticated users can insert card events"
  ON public.card_events FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Add missing policies for recording_summaries
-- (only SELECT existed — need INSERT for the AI summary service)
CREATE POLICY "Users can insert own recording summaries"
  ON public.recording_summaries FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.recordings
    WHERE recordings.id = recording_id AND recordings.user_id = auth.uid()
  ));

CREATE POLICY "Users can delete own recording summaries"
  ON public.recording_summaries FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM public.recordings
    WHERE recordings.id = recording_id AND recordings.user_id = auth.uid()
  ));
