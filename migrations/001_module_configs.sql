-- ============================================
-- MIGRATION: user_configs → module_configs
-- ============================================
-- Exécuter dans Supabase SQL Editor
-- https://supabase.com/dashboard/project/byqfnpdcnifauhwgetcq/sql

-- 1. CRÉER LA NOUVELLE TABLE module_configs
-- ============================================
CREATE TABLE IF NOT EXISTS module_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  module_name TEXT NOT NULL,

  -- Config spécifique au module (JSONB flexible)
  config JSONB DEFAULT '{}',

  -- Sheet associé (optionnel, un module peut avoir son propre sheet)
  sheet_id TEXT,

  -- État du module pour cet utilisateur
  is_enabled BOOLEAN DEFAULT TRUE,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Contrainte: 1 config par module par user
  UNIQUE(user_id, module_name)
);

-- Index pour requêtes rapides
CREATE INDEX IF NOT EXISTS idx_module_configs_user ON module_configs(user_id);
CREATE INDEX IF NOT EXISTS idx_module_configs_module ON module_configs(module_name);
CREATE INDEX IF NOT EXISTS idx_module_configs_user_module ON module_configs(user_id, module_name);

-- RLS (Row Level Security)
ALTER TABLE module_configs ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see/edit their own configs
CREATE POLICY "Users can view own module configs" ON module_configs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own module configs" ON module_configs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own module configs" ON module_configs
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own module configs" ON module_configs
  FOR DELETE USING (auth.uid() = user_id);

-- Service role bypass (pour le bot)
CREATE POLICY "Service role full access" ON module_configs
  FOR ALL USING (auth.role() = 'service_role');

-- 2. MIGRER LES DONNÉES EXISTANTES
-- ============================================
INSERT INTO module_configs (user_id, module_name, config, sheet_id, is_enabled, created_at)
SELECT
  user_id,
  'compta' as module_name,
  excel_config as config,
  sheet_id,
  is_active as is_enabled,
  created_at
FROM user_configs
ON CONFLICT (user_id, module_name) DO NOTHING;

-- 3. AJOUTER current_module À telegram_links
-- ============================================
ALTER TABLE telegram_links
ADD COLUMN IF NOT EXISTS current_module TEXT DEFAULT NULL;

-- 4. VÉRIFICATION
-- ============================================
-- Compter les enregistrements migrés
SELECT
  (SELECT COUNT(*) FROM user_configs) as old_count,
  (SELECT COUNT(*) FROM module_configs WHERE module_name = 'compta') as new_count;

-- 5. (OPTIONNEL) APRÈS VALIDATION - SUPPRIMER L'ANCIENNE TABLE
-- ============================================
-- ⚠️ NE PAS EXÉCUTER TOUT DE SUITE - Attendre que tout fonctionne
-- DROP TABLE user_configs;
