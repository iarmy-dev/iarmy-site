// iArmy Analytics - Tracking des visites
(function() {
  const SUPABASE_URL = 'https://byqfnpdcnifauhwgetcq.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5cWZucGRjbmlmYXVod2dldGNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4ODY1MTIsImV4cCI6MjA4MzQ2MjUxMn0.1W2OaRb0sApMvrG_28AoV2zUFAzrptzpwbR1c65tOPo';

  // Générer ou récupérer un visitor ID unique
  function getVisitorId() {
    let id = localStorage.getItem('iarmy_visitor_id');
    if (!id) {
      id = 'v_' + Math.random().toString(36).substr(2, 9) + Date.now().toString(36);
      localStorage.setItem('iarmy_visitor_id', id);
    }
    return id;
  }

  // Récupérer le user_id si connecté (depuis Supabase session)
  function getUserId() {
    try {
      const session = localStorage.getItem('sb-byqfnpdcnifauhwgetcq-auth-token');
      if (session) {
        const parsed = JSON.parse(session);
        return parsed?.user?.id || null;
      }
    } catch (e) {}
    return null;
  }

  // Envoyer la visite
  async function trackVisit() {
    try {
      const data = {
        visitor_id: getVisitorId(),
        user_id: getUserId(),
        page_path: window.location.pathname,
        page_title: document.title,
        referrer: document.referrer || null,
        user_agent: navigator.userAgent,
        screen_width: window.screen.width,
        screen_height: window.screen.height,
        language: navigator.language
      };

      await fetch(SUPABASE_URL + '/rest/v1/page_visits', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': 'Bearer ' + SUPABASE_ANON_KEY
        },
        body: JSON.stringify(data)
      });
    } catch (e) {
      // Silencieux - on ne veut pas perturber l'utilisateur
    }
  }

  // Tracker au chargement de la page
  if (document.readyState === 'complete') {
    trackVisit();
  } else {
    window.addEventListener('load', trackVisit);
  }
})();
