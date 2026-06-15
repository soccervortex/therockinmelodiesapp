-- ============================================================
--  The Rockin' Melodies — Supabase bookings table setup
--  Run this in the Supabase SQL editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. Create the bookings table
CREATE TABLE IF NOT EXISTS public.bookings (
    id          UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
    date        TEXT         NOT NULL,
    "time"      TEXT         NOT NULL DEFAULT '',
    location    TEXT         NOT NULL DEFAULT '',
    contact_name  TEXT       NOT NULL DEFAULT '',
    contact_phone TEXT       NOT NULL DEFAULT '',
    contact_email TEXT       NOT NULL DEFAULT '',
    status      TEXT         NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 2. Enable Row Level Security
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 3. RLS policies
--    For this booking app the anon key handles both client and admin
--    operations. In production you would split these using a server-side
--    function authenticated with the service_role key.

-- Allow anyone to read ALL bookings (needed for admin pending list)
CREATE POLICY "read_all" ON public.bookings
    FOR SELECT USING (true);

-- Allow anyone to insert a new pending booking request
CREATE POLICY "insert_pending" ON public.bookings
    FOR INSERT WITH CHECK (status = 'pending');

-- Allow admin to update status (accept / reject / manual block)
CREATE POLICY "update_status" ON public.bookings
    FOR UPDATE USING (true) WITH CHECK (true);

-- 4. Enable Realtime so the app receives live updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;

-- ============================================================
--  Done! Copy your project URL and anon key from:
--  Supabase Dashboard → Project Settings → API
--  and paste them into lib/main.dart (SUPABASE_URL / SUPABASE_ANON_KEY)
-- ============================================================
