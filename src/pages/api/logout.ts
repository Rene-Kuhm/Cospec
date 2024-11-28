import type { APIRoute } from 'astro';
import { supabase } from '../../lib/supabase';

export const post: APIRoute = async ({ cookies, redirect }) => {
  const { error } = await supabase.auth.signOut();
  
  if (error) {
    return new Response(error.message, { status: 500 });
  }

  cookies.delete('sb-access-token', { path: '/' });
  return redirect('/');
};