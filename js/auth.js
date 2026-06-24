// GRIA Auth Utilities

async function getSession() {
  const { data: { session } } = await supabase.auth.getSession();
  return session;
}

async function getProfile(userId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();
  if (error) throw error;
  return data;
}

async function signOut() {
  await supabase.auth.signOut();
  window.location.href = 'login.html';
}

function requireAuth() {
  supabase.auth.getSession().then(({ data: { session } }) => {
    if (!session) {
      window.location.href = 'login.html';
    }
  });
}

function redirectIfLoggedIn() {
  supabase.auth.getSession().then(({ data: { session } }) => {
    if (session) {
      window.location.href = 'dashboard.html';
    }
  });
}
