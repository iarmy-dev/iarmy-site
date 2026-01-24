# CLAUDE.md - Configuration iArmy pour Claude Code

## CONTEXTE PROJET

Tu travailles sur **iArmy**, une plateforme SaaS multi-modules pour automatiser les tâches des restaurants via Telegram + AI.

**Fondateur** : Ludovik (Luxembourg)
**Business model** : Compta 29€/mois, Personnel 39€/mois, Objectifs 19€/mois

---

## ARCHITECTURE

```
iArmy
├── SITE WEB (GitHub Pages)
│   └── https://iarmy.fr
│
├── BOT TELEGRAM (Render)
│   └── Hébergé sur RENDER
│
├── BACKEND (Supabase)
│   └── Edge Functions pour APIs
│
├── APIs
│   └── Google Cloud (OAuth + Sheets API)
│   └── Gemini AI (analyse Excel/audio/images)
│   └── Resend (emails)
│   └── Stripe (paiements)
│
└── WORKFLOW
    └── User connecte Google Sheets → AI analyse → Compte créé auto
    └── User envoie données Telegram → AI parse → Écrit dans Sheets
```

---

## REGLES CRITIQUES

### 1. NE JAMAIS ECRASER LE CODE EXISTANT
- Toujours vérifier ce qui existe avant de modifier
- Demander confirmation pour les suppressions

### 2. NE JAMAIS CHANGER LE DESIGN SANS DEMANDE EXPLICITE
- Le design actuel est validé
- Pas de modifications de style non demandées

### 3. TOUJOURS GENERER LES FICHIERS ENTIERS
- Jamais de "// reste du code..."
- Jamais de parties de code

### 4. SYSTEME MULTI-CLIENTS
- Chaque client a sa propre config Excel
- Ne pas hardcoder de structure Excel

---

## CREDENTIALS

**IMPORTANT: Les credentials sont stockés dans les variables d'environnement, PAS dans le code.**

- Supabase: Variables sur Render + Supabase Dashboard
- Telegram: Variable TELEGRAM_BOT_TOKEN sur Render
- Stripe: Variables sur Supabase secrets
- Google: Variables sur Render

---

## STRUCTURE DES REPOS

### iarmy-site (GitHub Pages - iarmy.fr)
```
iarmy-site/
├── index.html         # Landing page + modal connexion
├── privacy/           # Politique de confidentialite
├── cgu/               # Conditions generales
└── CNAME              # Domaine iarmy.fr
```

### iarmy-app (GitHub Pages - app.iarmy.fr)
```
iarmy-app/
├── index.html         # Dashboard utilisateur
├── compta/            # Module comptabilite
│   ├── index.html
│   └── setup/
├── auth/callback.html # OAuth callback
├── admin/             # Panel admin
└── CNAME              # Domaine app.iarmy.fr
```

### iarmy-bot (Render)
```
iarmy-bot/
├── bot.js             # Bot principal Telegram (webhook mode)
├── supabase/functions # Edge Functions
└── package.json
```

---

## CE QUI FONCTIONNE

- [x] Site web live sur iarmy.fr
- [x] Bot Telegram en mode webhook (scalable)
- [x] Sécurité webhook (secret token, IP whitelist, rate limit)
- [x] Parsing robuste avec 50+ aliases
- [x] Chiffrement AES-256-GCM des données sensibles
- [x] Google OAuth + Sheets API
- [x] Stripe payments + webhooks
- [x] Validation montants/dates

---

## COMMANDES UTILES

### Deployer le site
```bash
cd iarmy-site && git add . && git commit -m "Description" && git push
```

### Deployer le bot
```bash
cd iarmy-bot && git add . && git commit -m "Description" && git push
# Render redéploie automatiquement
```

### Deployer les functions Supabase
```bash
cd iarmy-bot && supabase functions deploy <function-name>
```

---

## NOTES IMPORTANTES

- Le bot est sur **RENDER** en mode webhook (plus de polling)
- Les Edge Functions Supabase gèrent les APIs sensibles
- Chaque client a une structure Excel différente → parsing adaptatif
