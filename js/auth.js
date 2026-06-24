// GRIA Auth Utilities
async function getSession() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  return session;
}
async function getProfile(userId) {
  const { data, error } = await supabaseClient
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();
  if (error) throw error;
  return data;
}
async function signOut() {
  await supabaseClient.auth.signOut();
  window.location.href = 'login.html';
}
function requireAuth() {
  supabaseClient.auth.getSession().then(({ data: { session } }) => {
    if (!session) {
      window.location.href = 'login.html';
    }
  });
}
function redirectIfLoggedIn() {
  supabaseClient.auth.getSession().then(({ data: { session } }) => {
    if (session) {
      window.location.href = 'dashboard.html';
    }
  });
}