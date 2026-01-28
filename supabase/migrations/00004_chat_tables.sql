-- ============================================================================
-- BiteWise Database Schema - Chat Tables
-- Migration: 00004_chat_tables.sql
-- Description: Creates chat_sessions and chat_messages tables
-- ============================================================================

-- ============================================================================
-- 1. CHAT_SESSIONS TABLE
-- Maps to ChatSession.swift
-- ============================================================================

CREATE TABLE public.chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    recipe_id UUID REFERENCES public.recipes(id) ON DELETE SET NULL,
    title TEXT DEFAULT 'New Chat',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_chat_sessions_user ON public.chat_sessions(user_id);
CREATE INDEX idx_chat_sessions_recipe ON public.chat_sessions(recipe_id) WHERE recipe_id IS NOT NULL;
CREATE INDEX idx_chat_sessions_updated ON public.chat_sessions(updated_at DESC);
CREATE INDEX idx_chat_sessions_user_updated ON public.chat_sessions(user_id, updated_at DESC);

-- Auto-update updated_at
CREATE TRIGGER update_chat_sessions_updated_at
    BEFORE UPDATE ON public.chat_sessions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 2. CHAT_MESSAGES TABLE
-- Maps to ChatMessage.swift
-- ============================================================================

CREATE TABLE public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.chat_sessions(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content_type TEXT NOT NULL DEFAULT 'text'
        CHECK (content_type IN ('text', 'recipe_card')),
    content TEXT NOT NULL,
    recipe_data JSONB,
    is_user BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX idx_chat_messages_session ON public.chat_messages(session_id);
CREATE INDEX idx_chat_messages_user ON public.chat_messages(user_id);
CREATE INDEX idx_chat_messages_created ON public.chat_messages(created_at);
CREATE INDEX idx_chat_messages_session_created ON public.chat_messages(session_id, created_at);

-- ============================================================================
-- 3. UPDATE SESSION updated_at WHEN MESSAGE ADDED
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_chat_session_on_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.chat_sessions
    SET updated_at = now()
    WHERE id = NEW.session_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_chat_message_insert
    AFTER INSERT ON public.chat_messages
    FOR EACH ROW EXECUTE FUNCTION public.update_chat_session_on_message();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.chat_sessions IS 'Chat conversation sessions - general or recipe-specific';
COMMENT ON TABLE public.chat_messages IS 'Individual messages within chat sessions';

COMMENT ON COLUMN public.chat_sessions.recipe_id IS 'NULL for general chats, set for recipe-specific conversations';
COMMENT ON COLUMN public.chat_sessions.title IS 'Auto-generated from first user message or default';
COMMENT ON COLUMN public.chat_messages.content_type IS 'text for normal messages, recipe_card for recipe suggestions';
COMMENT ON COLUMN public.chat_messages.content IS 'Text content of the message';
COMMENT ON COLUMN public.chat_messages.recipe_data IS 'Full recipe JSON when content_type is recipe_card';
COMMENT ON COLUMN public.chat_messages.is_user IS 'true if message from user, false if from AI assistant';
