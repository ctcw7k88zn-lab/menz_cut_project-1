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
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parse request body
    const { image_url, user_id, salon_id, service_id } = await req.json()

    if (!image_url || !user_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Mock AI suggestions (replace with actual AI service integration)
    const mockSuggestions = [
      {
        type: 'haircut',
        title: 'Modern Bob Cut',
        description: 'A sleek, modern bob that frames your face beautifully',
        confidence: 0.85,
        tags: ['short', 'modern', 'professional'],
        image_url: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
        estimated_price: 45,
        duration_minutes: 60,
        difficulty: 'medium'
      },
      {
        type: 'haircut',
        title: 'Layered Pixie',
        description: 'A trendy pixie cut with subtle layers for texture',
        confidence: 0.78,
        tags: ['short', 'trendy', 'low-maintenance'],
        image_url: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
        estimated_price: 40,
        duration_minutes: 45,
        difficulty: 'easy'
      },
      {
        type: 'styling',
        title: 'Beach Waves',
        description: 'Effortless beach waves for a relaxed, summery look',
        confidence: 0.72,
        tags: ['waves', 'casual', 'summer'],
        image_url: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
        estimated_price: 35,
        duration_minutes: 30,
        difficulty: 'easy'
      },
      {
        type: 'color',
        title: 'Balayage Highlights',
        description: 'Natural-looking highlights that grow out beautifully',
        confidence: 0.68,
        tags: ['highlights', 'natural', 'low-maintenance'],
        image_url: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
        estimated_price: 120,
        duration_minutes: 180,
        difficulty: 'hard'
      }
    ]

    // Filter suggestions based on salon services if provided
    let suggestions = mockSuggestions
    if (salon_id) {
      // In a real implementation, you would filter based on available salon services
      suggestions = mockSuggestions.filter(s => s.estimated_price <= 100) // Example filter
    }

    // Return suggestions
    return new Response(
      JSON.stringify({ 
        success: true, 
        suggestions: suggestions,
        user_id: user_id,
        salon_id: salon_id,
        service_id: service_id,
        generated_at: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200, 
      }
    )

  } catch (error) {
    console.error('Error in AI style suggestion function:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})