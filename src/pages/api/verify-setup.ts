import type { APIRoute } from 'astro';
import { verifySupabaseSetup } from '../../lib/supabase-verify';

export const get: APIRoute = async () => {
  const isValid = await verifySupabaseSetup();
  
  return new Response(
    JSON.stringify({
      success: isValid,
      message: isValid ? 'Setup verificado correctamente' : 'Error en la verificación'
    }),
    {
      status: isValid ? 200 : 500,
      headers: {
        'Content-Type': 'application/json'
      }
    }
  );
};