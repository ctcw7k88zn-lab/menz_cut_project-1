import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { user_id, type, title, message, data = {} } = await req.json()

    if (!user_id || !type || !title || !message) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, type, title, message' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Insert notification into database
    const { data: notification, error } = await supabaseClient
      .from('notifications')
      .insert({
        user_id,
        type,
        title,
        message,
        data,
        is_read: false
      })
      .select()
      .single()

    if (error) {
      console.error('Error creating notification:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to create notification' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // TODO: Integrate with push notification service (FCM/APNs)
    // For now, we'll just log the notification
    console.log('Notification created:', notification)

    return new Response(
      JSON.stringify({ 
        success: true, 
        notification 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Function error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})