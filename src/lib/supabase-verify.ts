import { supabase } from './supabase';

export async function verifySupabaseSetup() {
  try {
    // Verificar conexión
    const { data: connectionTest, error: connectionError } = await supabase
      .from('profiles')
      .select('count(*)')
      .limit(1);

    if (connectionError) {
      console.error('Error de conexión:', connectionError.message);
      return false;
    }

    // Verificar estructura de la tabla
    const { data: tableInfo, error: tableError } = await supabase
      .rpc('get_table_info', { table_name: 'profiles' });

    if (tableError) {
      console.error('Error al verificar tabla:', tableError.message);
      return false;
    }

    // Verificar políticas RLS
    const { data: policies, error: policiesError } = await supabase
      .rpc('get_policies', { table_name: 'profiles' });

    if (policiesError) {
      console.error('Error al verificar políticas:', policiesError.message);
      return false;
    }

    console.log('Verificación completada exitosamente');
    return true;
  } catch (error) {
    console.error('Error durante la verificación:', error);
    return false;
  }
}