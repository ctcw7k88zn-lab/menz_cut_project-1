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
    const body = await req.json()
    const { image_url, user_id, image_base64, prompt } = body

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: 'Missing user_id' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Use OpenRouter Grok API
    const openRouterApiKey = Deno.env.get('OPENROUTER_API_KEY') ?? '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'
    
    // Build request body for OpenRouter
    const imageData = image_base64 || (image_url ? await fetch(image_url).then(r => r.arrayBuffer()).then(b => btoa(String.fromCharCode(...new Uint8Array(b)))) : null)
    
    if (!imageData) {
      return new Response(
        JSON.stringify({ error: 'Missing image data' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    const openRouterRequest = {
      model: "x-ai/grok-4",
      messages: [
        {
          role: "user",
          content: prompt ? JSON.parse(prompt) : [
            {
              type: "text",
              text: `Analyze this person's face image carefully and provide the following analysis:

1. FIRST, identify the FACE SHAPE of the person in the image:
   - Determine the face shape category: Oval, Round, Square, Diamond, Heart, Triangle, or Oblong
   - Describe the face shape clearly (e.g., "Oval face shape", "Round face shape", "Diamond face shape")
   - Also note the face angle: front-facing (0 degrees), side profile (90 degrees), three-quarter view, etc.

2. THEN, based on this face shape and angle, suggest 2-3 best haircuts that would suit this person:
   - For each haircut, provide:
     * Name of the haircut style
     * Description
     * Why this haircut is best for this person based on their face shape and angle
     * Confidence score (0-1)
     * Haircut length (short, medium, long)
     * Style category (classic, modern, trendy, casual, professional)
   
3. Return the response in this EXACT JSON format:
{
  "face_shape": "Oval/Round/Square/Diamond/Heart/Triangle/Oblong",
  "face_angle": "description of face angle (e.g., 'Front-facing at 0 degrees' or 'Three-quarter left view at 45 degrees')",
  "face_angle_degrees": approximate angle number (0-180),
  "best_haircuts": [
    {
      "name": "Haircut name",
      "description": "Detailed description",
      "why_best": "Explanation why this haircut is best for this face shape and angle",
      "confidence": 0.85,
      "haircut_type": "short/medium/long",
      "style_category": "modern/classic/trendy/casual"
    }
  ]
}

IMPORTANT: 
- First identify the face shape (Oval, Round, Square, Diamond, Heart, Triangle, or Oblong)
- Then determine the face angle
- Finally, suggest haircuts that complement both the face shape and angle
- Format your response clearly: "Face Shape: [shape name]. Face Angle: [angle description]. According to this face shape and angle, these haircuts are best for you:"`
            },
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${imageData}`
              }
            }
          ]
        }
      ],
      temperature: 0.7,
      max_tokens: 2048,
    }

    // Call OpenRouter API
    const openRouterResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openRouterApiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://menzcut.app',
        'X-Title': 'MenzCut AI Hair Suggestions',
      },
      body: JSON.stringify(openRouterRequest),
    })

    if (!openRouterResponse.ok) {
      const errorText = await openRouterResponse.text()
      throw new Error(`OpenRouter API error: ${openRouterResponse.status} - ${errorText}`)
    }

    const openRouterData = await openRouterResponse.json()
    
    if (!openRouterData.choices || !openRouterData.choices[0] || !openRouterData.choices[0].message) {
      throw new Error('Invalid response from OpenRouter API')
    }

    const content = openRouterData.choices[0].message.content

    // Return the response
    return new Response(
      JSON.stringify({ 
        success: true, 
        content: content,
        user_id: user_id,
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
