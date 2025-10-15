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

    const { image_url, user_id, suggestion_type = 'haircut' } = await req.json()

    if (!image_url || !user_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: image_url, user_id' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Mock AI analysis (replace with actual AI API call)
    const mockSuggestions = [
      {
        title: 'Modern Fade Style',
        description: 'A contemporary fade haircut that would suit your face shape perfectly.',
        confidence_score: 0.92,
        tags: ['modern', 'fade', 'short'],
        salon_recommendations: [
          {
            salon_id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            service_id: '11111111-1111-1111-1111-111111111112',
            reason: 'Specializes in modern cuts'
          }
        ]
      },
      {
        title: 'Classic Side Part',
        description: 'A timeless side part hairstyle that never goes out of fashion.',
        confidence_score: 0.85,
        tags: ['classic', 'side_part', 'business'],
        salon_recommendations: [
          {
            salon_id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
            service_id: '33333333-3333-3333-3333-333333333334',
            reason: 'Expert in traditional cuts'
          }
        ]
      }
    ]

    // Insert AI suggestions into database
    const suggestions = mockSuggestions.map(suggestion => ({
      user_id,
      suggestion_type,
      title: suggestion.title,
      description: suggestion.description,
      content: suggestion,
      image_url,
      confidence_score: suggestion.confidence_score,
      tags: suggestion.tags,
      salon_id: suggestion.salon_recommendations[0]?.salon_id || null,
      service_id: suggestion.salon_recommendations[0]?.service_id || null
    }))

    const { data, error } = await supabaseClient
      .from('ai_suggestions')
      .insert(suggestions)
      .select()

    if (error) {
      console.error('Error inserting suggestions:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to save suggestions' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        suggestions: mockSuggestions,
        saved_count: data.length 
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