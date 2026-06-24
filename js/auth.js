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
  window.location.href = 'daftar.html';
}
function requireAuth() {
  supabaseClient.auth.getSession().then(({ data: { session } }) => {
    if (!session) {
      window.location.href = 'daftar.html';
    }
  });
}
// Dipakai di daftar.html: user yang sudah login dialihkan ke tujuan yang sesuai
// — onboarding bila belum selesai, dashboard bila sudah.
function redirectIfLoggedIn() {
  supabaseClient.auth.getSession().then(async ({ data: { session } }) => {
    if (!session) return;
    try {
      const profile = await getProfile(session.user.id);
      window.location.href = (profile && profile.onboarding_selesai)
        ? 'dashboard.html'
        : 'onboarding.html';
    } catch (e) {
      // Profil belum ada (trigger handle_new_user belum jalan?) — coba onboarding
      window.location.href = 'onboarding.html';
    }
  });
}
