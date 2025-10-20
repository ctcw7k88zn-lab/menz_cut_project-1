-- Enhance the chat system with real-time features
-- This migration adds typing indicators, message status, and online presence

-- Add new columns to messages table
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS edited_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- Create chat_threads table for better thread management
CREATE TABLE IF NOT EXISTS public.chat_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id VARCHAR(255) NOT NULL UNIQUE,
    participant_1 UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    participant_2 UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique thread between two participants
    CONSTRAINT unique_thread_participants UNIQUE (participant_1, participant_2)
);

-- Create typing_indicators table for real-time typing status
CREATE TABLE IF NOT EXISTS public.typing_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id VARCHAR(255) NOT NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 seconds'),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint for one typing indicator per user per thread
    CONSTRAINT unique_user_thread_typing UNIQUE (thread_id, user_id)
);

-- Create online_status table for user presence
CREATE TABLE IF NOT EXISTS public.online_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_online BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status_message VARCHAR(100) DEFAULT 'Online',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- One status per user
    CONSTRAINT unique_user_online_status UNIQUE (user_id)
);

-- Create message_reactions table for message reactions
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reaction VARCHAR(10) NOT NULL, -- emoji or reaction type
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- One reaction per user per message
    CONSTRAINT unique_user_message_reaction UNIQUE (message_id, user_id)
);

-- Enable RLS on new tables
ALTER TABLE public.chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.online_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chat_threads
CREATE POLICY "Users can view threads they participate in" ON public.chat_threads
FOR SELECT USING (
    auth.uid() = participant_1 OR auth.uid() = participant_2
);

CREATE POLICY "Users can create threads" ON public.chat_threads
FOR INSERT WITH CHECK (
    auth.uid() = participant_1 OR auth.uid() = participant_2
);

CREATE POLICY "Users can update threads they participate in" ON public.chat_threads
FOR UPDATE USING (
    auth.uid() = participant_1 OR auth.uid() = participant_2
);

-- RLS Policies for typing_indicators
CREATE POLICY "Users can view typing indicators for their threads" ON public.typing_indicators
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.chat_threads 
        WHERE chat_threads.thread_id = typing_indicators.thread_id 
        AND (chat_threads.participant_1 = auth.uid() OR chat_threads.participant_2 = auth.uid())
    )
);

CREATE POLICY "Users can create typing indicators for their threads" ON public.typing_indicators
FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM public.chat_threads 
        WHERE chat_threads.thread_id = typing_indicators.thread_id 
        AND (chat_threads.participant_1 = auth.uid() OR chat_threads.participant_2 = auth.uid())
    )
);

CREATE POLICY "Users can update their own typing indicators" ON public.typing_indicators
FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own typing indicators" ON public.typing_indicators
FOR DELETE USING (user_id = auth.uid());

-- RLS Policies for online_status
CREATE POLICY "Users can view online status of others" ON public.online_status
FOR SELECT USING (true); -- Allow viewing online status of other users

CREATE POLICY "Users can create their own online status" ON public.online_status
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own online status" ON public.online_status
FOR UPDATE USING (user_id = auth.uid());

-- RLS Policies for message_reactions
CREATE POLICY "Users can view reactions on messages in their threads" ON public.message_reactions
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.messages 
        JOIN public.chat_threads ON messages.thread_id = chat_threads.thread_id
        WHERE messages.id = message_reactions.message_id 
        AND (chat_threads.participant_1 = auth.uid() OR chat_threads.participant_2 = auth.uid())
    )
);

CREATE POLICY "Users can create reactions on messages" ON public.message_reactions
FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM public.messages 
        JOIN public.chat_threads ON messages.thread_id = chat_threads.thread_id
        WHERE messages.id = message_reactions.message_id 
        AND (chat_threads.participant_1 = auth.uid() OR chat_threads.participant_2 = auth.uid())
    )
);

CREATE POLICY "Users can delete their own reactions" ON public.message_reactions
FOR DELETE USING (user_id = auth.uid());

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chat_threads_participants ON public.chat_threads(participant_1, participant_2);
CREATE INDEX IF NOT EXISTS idx_chat_threads_last_message ON public.chat_threads(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_thread ON public.typing_indicators(thread_id);
CREATE INDEX IF NOT EXISTS idx_typing_indicators_expires ON public.typing_indicators(expires_at);
CREATE INDEX IF NOT EXISTS idx_online_status_user ON public.online_status(user_id);
CREATE INDEX IF NOT EXISTS idx_online_status_online ON public.online_status(is_online);
CREATE INDEX IF NOT EXISTS idx_message_reactions_message ON public.message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_messages_thread_created ON public.messages(thread_id, created_at DESC);

-- Create functions for real-time chat features

-- Function to update last message in thread
CREATE OR REPLACE FUNCTION update_thread_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.chat_threads 
    SET 
        last_message_at = NEW.created_at,
        last_message_id = NEW.id,
        updated_at = NOW()
    WHERE thread_id = NEW.thread_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update thread when new message is added
DROP TRIGGER IF EXISTS trg_update_thread_last_message ON public.messages;
CREATE TRIGGER trg_update_thread_last_message
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION update_thread_last_message();

-- Function to clean up expired typing indicators
CREATE OR REPLACE FUNCTION cleanup_expired_typing_indicators()
RETURNS void AS $$
BEGIN
    DELETE FROM public.typing_indicators 
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get or create thread between two users
CREATE OR REPLACE FUNCTION get_or_create_thread(user1_id UUID, user2_id UUID)
RETURNS UUID AS $$
DECLARE
    thread_uuid UUID;
    thread_id_str VARCHAR(255);
BEGIN
    -- Create sorted thread ID
    IF user1_id::text < user2_id::text THEN
        thread_id_str := user1_id::text || '_' || user2_id::text;
    ELSE
        thread_id_str := user2_id::text || '_' || user1_id::text;
    END IF;
    
    -- Try to get existing thread
    SELECT id INTO thread_uuid
    FROM public.chat_threads 
    WHERE (participant_1 = user1_id AND participant_2 = user2_id) 
       OR (participant_1 = user2_id AND participant_2 = user1_id);
    
    -- Create new thread if doesn't exist
    IF thread_uuid IS NULL THEN
        INSERT INTO public.chat_threads (thread_id, participant_1, participant_2)
        VALUES (thread_id_str, user1_id, user2_id)
        RETURNING id INTO thread_uuid;
    END IF;
    
    RETURN thread_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(thread_id_param VARCHAR, user_id_param UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.messages 
    SET status = 'read'
    WHERE thread_id = thread_id_param 
    AND receiver_id = user_id_param 
    AND status != 'read';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread message count for user
CREATE OR REPLACE FUNCTION get_unread_message_count(user_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO unread_count
    FROM public.messages 
    WHERE receiver_id = user_id_param 
    AND status != 'read';
    
    RETURN COALESCE(unread_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user online status
CREATE OR REPLACE FUNCTION update_user_online_status(user_id_param UUID, is_online_param BOOLEAN)
RETURNS void AS $$
BEGIN
    INSERT INTO public.online_status (user_id, is_online, last_seen, updated_at)
    VALUES (user_id_param, is_online_param, NOW(), NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        is_online = is_online_param,
        last_seen = CASE WHEN is_online_param THEN NOW() ELSE online_status.last_seen END,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a scheduled job to clean up expired typing indicators (if pg_cron is available)
-- SELECT cron.schedule('cleanup-typing-indicators', '*/30 * * * *', 'SELECT cleanup_expired_typing_indicators();');

-- Add some sample data for testing
INSERT INTO public.online_status (user_id, is_online, last_seen, status_message)
SELECT id, false, NOW(), 'Offline'
FROM public.profiles
WHERE id NOT IN (SELECT user_id FROM public.online_status);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chat_threads TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.typing_indicators TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.online_status TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.message_reactions TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_or_create_thread(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_messages_as_read(VARCHAR, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_message_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_online_status(UUID, BOOLEAN) TO authenticated;
