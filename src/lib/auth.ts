import { supabase } from './supabase';

export async function signIn(email: string, password: string, role: 'admin' | 'technician') {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) throw error;

  if (data.user) {
    const { data: profileData } = await supabase
      .from('profiles')
      .select('role, approved')
      .eq('id', data.user.id)
      .single();

    if (!profileData?.approved) {
      throw new Error('Tu cuenta está pendiente de aprobación');
    }

    if (profileData.role !== role) {
      throw new Error(`No tienes permisos de ${role}`);
    }

    return data.user;
  }

  return null;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}