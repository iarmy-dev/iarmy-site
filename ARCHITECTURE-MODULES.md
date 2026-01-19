# Architecture Multi-Modules iArmy

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────┐
│                        UTILISATEUR                          │
│                     (profiles table)                        │
└─────────────────────────┬───────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   COMPTA    │  │  PERSONNEL  │  │  OBJECTIFS  │
│  (module)   │  │   (module)  │  │   (module)  │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                     1 BOT TELEGRAM                          │
│              (menu avec boutons modules)                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Tables Supabase

### 1. `profiles` (inchangé)
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL,
  name TEXT,
  avatar_url TEXT,
  plan TEXT DEFAULT 'free', -- 'free', 'starter', 'pro', 'enterprise'
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. `subscriptions` (existe, à enrichir)
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  module_name TEXT NOT NULL, -- 'compta', 'personnel', 'objectifs', etc.
  status TEXT DEFAULT 'active', -- 'active', 'cancelled', 'paused', 'trial'
  stripe_subscription_id TEXT,
  stripe_price_id TEXT,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, module_name)
);
```

### 3. `module_configs` (NOUVEAU - remplace user_configs)
```sql
CREATE TABLE module_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  module_name TEXT NOT NULL, -- 'compta', 'personnel', 'objectifs'

  -- Config spécifique au module (JSONB flexible)
  config JSONB DEFAULT '{}',

  -- Sheet associé (optionnel, un module peut avoir son propre sheet)
  sheet_id TEXT,

  -- État du module pour cet utilisateur
  is_enabled BOOLEAN DEFAULT TRUE, -- peut désactiver sans perdre config

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, module_name)
);

-- Index pour requêtes rapides
CREATE INDEX idx_module_configs_user ON module_configs(user_id);
CREATE INDEX idx_module_configs_module ON module_configs(module_name);
```

### 4. `telegram_links` (inchangé)
```sql
CREATE TABLE telegram_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  telegram_user_id TEXT NOT NULL UNIQUE,
  telegram_chat_id TEXT,
  current_module TEXT DEFAULT NULL, -- module actif dans la conversation
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 5. `google_credentials` (inchangé)
```sql
-- 1 compte Google par utilisateur, peut être partagé entre modules
CREATE TABLE google_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  access_token_encrypted TEXT,
  refresh_token_encrypted TEXT,
  token_iv TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Structure Config par Module

### Module Compta
```json
{
  "sheet_id": "abc123",
  "colonnes_a_remplir": [
    {"nom": "CB", "colonne": "B", "aliases": ["carte", "card"]},
    {"nom": "ESP", "colonne": "C", "aliases": ["espèces", "cash"]},
    {"nom": "TR", "colonne": "D", "aliases": ["ticket resto"]},
    {"nom": "DEP", "colonne": "E", "aliases": ["dépenses"]},
    {"nom": "RAZ", "colonne": "F", "aliases": ["caisse"]}
  ],
  "regles": [
    {"terms": [{"name": "CB"}, {"name": "ESP", "op": "+"}, {"name": "DEP", "op": "+"}], "target": "+"}
  ],
  "export_settings": {
    "auto_export_enabled": false,
    "export_email": "comptable@example.com",
    "notif_weekly_recap": true,
    "notif_monthly_recap": true,
    "notif_records": true,
    "monthly_objective": 50000
  }
}
```

### Module Personnel (futur)
```json
{
  "sheet_id": "def456",
  "employees": ["Jean", "Marie", "Pierre"],
  "shift_types": ["matin", "soir", "coupure"],
  "notifications": {
    "planning_reminder": true,
    "absence_alert": true
  }
}
```

### Module Objectifs (futur)
```json
{
  "goals": [
    {"name": "CA Mensuel", "target": 50000, "type": "monthly"},
    {"name": "Tickets/jour", "target": 100, "type": "daily"}
  ],
  "notifications": {
    "daily_progress": true,
    "goal_reached": true
  }
}
```

---

## Bot Telegram - Flow

### 1. Démarrage (/start)
```
Salut [Prénom] ! 👋

Tes modules actifs :
┌─────────────┬─────────────┐
│ 📊 Compta   │ 👥 Personnel│
└─────────────┴─────────────┘

Clique sur un module pour commencer.
```

### 2. Sélection Module
```
User clique "📊 Compta"
↓
Bot: "📊 Mode Compta activé !
      Envoie tes données (ex: CB 200 ESP 100)

      [← Menu] [⚙️ Config]"
↓
telegram_links.current_module = 'compta'
```

### 3. Traitement Message
```javascript
// Le bot vérifie le module actif
const link = await getLink(telegramUserId);
const currentModule = link.current_module;

if (!currentModule) {
  return showModuleMenu(chatId);
}

// Récupère la config du module actif
const moduleConfig = await getModuleConfig(link.user_id, currentModule);

// Traite selon le module
switch (currentModule) {
  case 'compta':
    return handleComptaMessage(msg, moduleConfig);
  case 'personnel':
    return handlePersonnelMessage(msg, moduleConfig);
  case 'objectifs':
    return handleObjectifsMessage(msg, moduleConfig);
}
```

### 4. Boutons en bas de chaque message
```
┌──────────┬──────────┬──────────┐
│ ← Menu   │ 📅 Date  │ ⚙️ Config │
└──────────┴──────────┴──────────┘
```

---

## Site Web - Structure

```
iarmy.fr/
├── index.html                    # Landing
├── inscription/                  # Wizard première inscription
├── compte/                       # Dashboard utilisateur
│   └── index.html
│       ├── Liste modules actifs
│       ├── Ajouter un module (+)
│       └── Gérer abonnements
└── modules/
    ├── compta/
    │   └── index.html            # Config module Compta
    ├── personnel/
    │   └── index.html            # Config module Personnel
    └── objectifs/
        └── index.html            # Config module Objectifs
```

### Page Compte - Dashboard
```
┌─────────────────────────────────────┐
│  Mes Modules                    [+] │
├─────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐│
│ │📊 Compta│ │👥Person.│ │🎯Object.││
│ │ Actif ✓ │ │ Actif ✓ │ │Inactif  ││
│ │[Config] │ │[Config] │ │[Activer]││
│ └─────────┘ └─────────┘ └─────────┘│
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Connexions                         │
├─────────────────────────────────────┤
│ 📱 Telegram: @paco_resto     [Lié] │
│ 📊 Google: paco@gmail.com    [Lié] │
└─────────────────────────────────────┘
```

---

## Migration user_configs → module_configs

### Script SQL
```sql
-- 1. Créer la nouvelle table
CREATE TABLE module_configs (...);

-- 2. Migrer les données existantes
INSERT INTO module_configs (user_id, module_name, config, sheet_id, is_enabled, created_at)
SELECT
  user_id,
  'compta' as module_name,
  excel_config as config,
  sheet_id,
  is_active as is_enabled,
  created_at
FROM user_configs;

-- 3. Vérifier la migration
SELECT COUNT(*) FROM user_configs;
SELECT COUNT(*) FROM module_configs WHERE module_name = 'compta';

-- 4. (Après validation) Supprimer l'ancienne table
-- DROP TABLE user_configs;
```

---

## API Changes

### Avant (user_configs)
```javascript
const { data } = await supabase
  .from('user_configs')
  .select('*')
  .eq('user_id', userId)
  .single();
```

### Après (module_configs)
```javascript
// Récupérer config d'un module spécifique
const { data } = await supabase
  .from('module_configs')
  .select('*')
  .eq('user_id', userId)
  .eq('module_name', 'compta')
  .single();

// Récupérer tous les modules d'un user
const { data: modules } = await supabase
  .from('module_configs')
  .select('module_name, is_enabled, config')
  .eq('user_id', userId);
```

---

## Pricing Modules

| Module | Prix/mois | Description |
|--------|-----------|-------------|
| Compta Express | 29€ | Saisie CA + export comptable |
| Personnel | 39€ | Planning + gestion équipe |
| Objectifs | 19€ | Suivi objectifs + motivation |
| Pack Pro | 69€ | Compta + Personnel + Objectifs |

---

## Checklist Implémentation

- [ ] Créer table `module_configs` dans Supabase
- [ ] Migrer données `user_configs` → `module_configs`
- [ ] Ajouter `current_module` à `telegram_links`
- [ ] Adapter bot.js pour multi-modules
- [ ] Créer menu modules dans le bot
- [ ] Adapter compte/index.html pour liste modules
- [ ] Créer page "Ajouter un module"
- [ ] Adapter modules/compta/ pour nouvelle structure
- [ ] Tester end-to-end
