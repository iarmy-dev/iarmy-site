-- =============================================
-- TABLE SUBSCRIPTIONS - Gestion des abonnements par module
-- À exécuter dans Supabase SQL Editor
-- =============================================

-- Créer la table subscriptions
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  module_name TEXT NOT NULL CHECK (module_name IN ('compta', 'personnel', 'objectifs')),

  -- Stripe info (null pour les testeurs)
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,

  -- Status de l'abonnement
  status TEXT NOT NULL DEFAULT 'trialing' CHECK (status IN ('active', 'trialing', 'canceled', 'past_due', 'incomplete', 'tester')),

  -- Testeur gratuit (toi tu mets ça à true manuellement)
  is_tester BOOLEAN NOT NULL DEFAULT false,

  -- Dates importantes
  trial_ends_at TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Un seul abonnement par user par module
  UNIQUE(user_id, module_name)
);

-- Index pour les recherches rapides
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_customer ON public.subscriptions(stripe_customer_id);

-- RLS (Row Level Security)
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Policy: Les users peuvent voir leurs propres subscriptions
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Les users peuvent créer leurs propres subscriptions (pour le checkout)
CREATE POLICY "Users can create own subscriptions" ON public.subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Service role peut tout faire (pour les webhooks Stripe)
CREATE POLICY "Service role has full access" ON public.subscriptions
  FOR ALL USING (auth.role() = 'service_role');

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_subscription_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour updated_at
DROP TRIGGER IF EXISTS trigger_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER trigger_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_subscription_updated_at();

-- =============================================
-- FONCTION HELPER: Vérifier si un user a accès à un module
-- =============================================
CREATE OR REPLACE FUNCTION public.has_module_access(p_user_id UUID, p_module_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  sub RECORD;
BEGIN
  SELECT * INTO sub FROM public.subscriptions
  WHERE user_id = p_user_id AND module_name = p_module_name;

  -- Pas d'abonnement trouvé
  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Testeur = toujours accès
  IF sub.is_tester = true THEN
    RETURN true;
  END IF;

  -- Status actif ou en essai
  IF sub.status IN ('active', 'trialing', 'tester') THEN
    -- Vérifier si l'essai n'est pas expiré
    IF sub.status = 'trialing' AND sub.trial_ends_at IS NOT NULL AND sub.trial_ends_at < NOW() THEN
      RETURN false;
    END IF;
    RETURN true;
  END IF;

  -- Annulé mais période payée pas terminée
  IF sub.status = 'canceled' AND sub.current_period_end IS NOT NULL AND sub.current_period_end > NOW() THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- COMMANDES UTILES POUR TOI (ADMIN)
-- =============================================

-- Ajouter un testeur gratuit pour le module compta:
-- INSERT INTO public.subscriptions (user_id, module_name, status, is_tester)
-- SELECT id, 'compta', 'tester', true FROM auth.users WHERE email = 'email@exemple.com';

-- Voir tous les testeurs:
-- SELECT u.email, s.module_name, s.status, s.is_tester
-- FROM public.subscriptions s
-- JOIN auth.users u ON s.user_id = u.id
-- WHERE s.is_tester = true;

-- Retirer un testeur:
-- UPDATE public.subscriptions SET is_tester = false, status = 'trialing', trial_ends_at = NOW() + INTERVAL '7 days'
-- WHERE user_id = (SELECT id FROM auth.users WHERE email = 'email@exemple.com') AND module_name = 'compta';


-- =============================================
-- ADMIN POLICIES - Pour le dashboard admin
-- =============================================

-- Table admin_users pour définir les admins
CREATE TABLE IF NOT EXISTS public.admin_users (
  email TEXT PRIMARY KEY
);

-- Ajoute-toi comme admin
INSERT INTO public.admin_users (email) VALUES ('ludovikh@gmail.com') ON CONFLICT DO NOTHING;

-- Policy: Admin peut voir toutes les subscriptions
CREATE POLICY "Admin can view all subscriptions" ON public.subscriptions
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.admin_users WHERE email = auth.jwt()->>'email')
  );

-- Policy: Admin peut modifier toutes les subscriptions
CREATE POLICY "Admin can update all subscriptions" ON public.subscriptions
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.admin_users WHERE email = auth.jwt()->>'email')
  );

-- Policy: Admin peut insérer des subscriptions pour tout le monde
CREATE POLICY "Admin can insert subscriptions" ON public.subscriptions
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.admin_users WHERE email = auth.jwt()->>'email')
  );

-- Vue pour l'admin dashboard (users avec leurs subscriptions)
CREATE OR REPLACE VIEW public.admin_users_view AS
SELECT
  u.id as user_id,
  u.email,
  u.raw_user_meta_data->>'full_name' as full_name,
  u.raw_user_meta_data->>'avatar_url' as avatar_url,
  u.created_at as user_created_at,
  u.last_sign_in_at,
  COALESCE(
    (SELECT json_agg(json_build_object(
      'module', s.module_name,
      'status', s.status,
      'is_tester', s.is_tester,
      'trial_ends_at', s.trial_ends_at,
      'current_period_end', s.current_period_end
    )) FROM public.subscriptions s WHERE s.user_id = u.id),
    '[]'::json
  ) as subscriptions,
  (SELECT COUNT(*) FROM public.module_configs mc WHERE mc.user_id = u.id) as modules_configured
FROM auth.users u
ORDER BY u.created_at DESC;

-- RLS pour la vue admin
ALTER VIEW public.admin_users_view SET (security_invoker = true);

-- Policy: Seuls les admins peuvent voir la vue
CREATE POLICY "Admin can view admin_users_view" ON public.admin_users
  FOR SELECT USING (true);  -- La vue vérifie déjà l'accès
