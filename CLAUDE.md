# CLAUDE.md - Configuration iArmy pour Claude Code

## 🎯 CONTEXTE PROJET

Tu travailles sur **iArmy**, une plateforme SaaS multi-modules pour automatiser les tâches des restaurants via Telegram + Claude AI.

**Fondateur** : Ludovik (Luxembourg)
**Business model** : Compta 29€/mois, Personnel 39€/mois, Objectifs 19€/mois

---

## 🏗️ ARCHITECTURE

```
iArmy
├── SITE WEB (GitHub Pages)
│   └── https://iarmy.fr
│   └── Repo: github.com/iarmy-dev/iarmy-site
│
├── BOT TELEGRAM (Render)
│   └── Repo: github.com/iarmy-dev/iarmy-bot
│   └── Hébergé sur RENDER (pas Railway)
│
├── BACKEND (Supabase)
│   └── Project ID: byqfnpdcnifauhwgetcq
│   └── URL: https://byqfnpdcnifauhwgetcq.supabase.co
│
├── APIs
│   └── Google Cloud (OAuth + Sheets API)
│   └── Claude AI (analyse Excel)
│   └── Resend (emails)
│   └── Stripe (paiements)
│
└── WORKFLOW
    └── User connecte Google Sheets → Claude analyse → Compte créé auto
    └── User envoie données Telegram → AI parse → Écrit dans Sheets
```

---

## ⚠️ RÈGLES CRITIQUES - À RESPECTER ABSOLUMENT

### 1. NE JAMAIS ÉCRASER LE CODE EXISTANT
- Toujours vérifier ce qui existe avant de modifier
- Demander confirmation pour les suppressions

### 2. NE JAMAIS CHANGER LE DESIGN SANS DEMANDE EXPLICITE
- Le design actuel est validé
- Pas de modifications de style non demandées

### 3. NE JAMAIS MODIFIER LE CODE D'ANALYSE EXCEL DE CLAUDE
- On a galéré pour le faire marcher
- C'est une boîte noire qui fonctionne

### 4. TOUJOURS GÉNÉRER LES FICHIERS ENTIERS
- Jamais de "// reste du code..."
- Jamais de parties de code
- Ludovik copie-colle directement sans modifier

### 5. SYSTÈME MULTI-CLIENTS
- Chaque client a sa propre config Excel
- Ne pas hardcoder de structure Excel

---

## 🔐 CREDENTIALS & ACCÈS

### Supabase
- **Project ID** : byqfnpdcnifauhwgetcq
- **URL** : https://byqfnpdcnifauhwgetcq.supabase.co
- **Anon Key** : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5cWZucGRjbmlmYXVod2dldGNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4ODY1MTIsImV4cCI6MjA4MzQ2MjUxMn0.1W2OaRb0sApMvrG_28AoV2zUFAzrptzpwbR1c65tOPo
- **Service Role Key** : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5cWZucGRjbmlmYXVod2dldGNxIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Nzg4NjUxMiwiZXhwIjoyMDgzNDYyNTEyfQ.Un7hRX9mamigIl2hTlSztYWzaV4UaINu0wYkk0zqcuM

### GitHub Repos
- **Site** : https://github.com/iarmy-dev/iarmy-site
- **Bot** : https://github.com/iarmy-dev/iarmy-bot

### Bot Telegram
- **Token** : 8366883614:AAG7NMGica82HgLUjuVJh3gOMMMI7Qq-7Ws
- **Username** : @IArmyBOT

### Hébergement
- **Site** : GitHub Pages (iarmy.fr)
- **Bot** : Render.com (service gratuit)

### Stripe (mode test)
- **Publishable Key** : pk_test_51SnhCpQnTQdmBOkyvcPgFDg8LQbPZzwAdBv9X1LeLhy8WKtlAorKQeqdiZKC2l994bjKJXxndPYal8G6izNilG15002j0OaFcP
- **Secret Key** : (dans Supabase secrets)
- **Price IDs** :
  - Compta : price_1SnhI0QnTQdmBOkyLm53KqqH (39€/mois)
- **Webhook URL** : https://byqfnpdcnifauhwgetcq.supabase.co/functions/v1/stripe-webhook

---

## 📂 STRUCTURE DES REPOS

### iarmy-site (GitHub Pages)
```
iarmy-site/
├── index.html         # Landing + modal connexion
├── compta.html        # Wizard configuration module Compta
├── compte.html        # Dashboard utilisateur
├── reset-password.html
├── auth/
│   └── callback.html  # ⚠️ CRITIQUE pour OAuth Google
└── CNAME              # Domaine iarmy.fr
```

### iarmy-bot (Render)
```
iarmy-bot/
├── bot.js             # Bot principal Telegram
├── database.js        # Connexion Supabase
├── gemini.js          # (legacy, utilise Claude maintenant)
├── sheets.js          # Google Sheets API
└── package.json
```

---

## 🐛 BUG ACTUEL À CORRIGER

### Problème OAuth Google
- **Symptôme** : User se connecte via Google mais token pas stocké dans Supabase
- **Conséquence** : Les infos du compte ne s'affichent pas
- **Cause** : Le fichier `auth/callback.html` ne récupère pas le token dans l'URL fragment (#access_token=...)
- **Solution** : Créer/corriger `auth/callback.html` pour appeler `supabase.auth.setSession()`

---

## ✅ CE QUI FONCTIONNE

- [x] Site web live sur iarmy.fr
- [x] DNS OVH configuré (4 A Records + CNAME)
- [x] Bot Telegram déployé et répond aux messages
- [x] Parsing robuste avec 50+ aliases (CB, ESP, TR, Dépenses...)
- [x] Boutons Valider/Annuler dans Telegram
- [x] Architecture module-agnostic (prêt pour multi-modules)
- [x] Supabase auth configuré
- [x] Google OAuth configuré (mais callback à corriger)

---

## ❌ TODO PRIORITAIRE

### 1. Corriger OAuth callback (CRITIQUE)
```javascript
// auth/callback.html doit :
// 1. Récupérer #access_token et #refresh_token de l'URL
// 2. Appeler supabase.auth.setSession({ access_token, refresh_token })
// 3. Rediriger vers /compte.html ou /
```

### 2. Ajouter sécurités au bot
- Validation des dates (2024-2027)
- Anti-flood (max 5 msg/minute)
- Validation des montants (max 999999€)

### 3. Afficher infos utilisateur après connexion
- Nom/email en haut à droite du site
- Bouton déconnexion

---

## 💡 COMMANDES UTILES

### Déployer le site
```bash
cd iarmy-site
git add .
git commit -m "Description"
git push origin main
# Attend 2-3 min pour GitHub Pages
```

### Déployer le bot
```bash
cd iarmy-bot
git add .
git commit -m "Description"
git push origin main
# Render redéploie automatiquement
```

### Tester le bot localement
```bash
cd iarmy-bot
npm install
node bot.js
```

---

## 📝 NOTES IMPORTANTES

- Le bot est sur **RENDER** (pas Railway)
- Toujours vérifier l'URL du service Render avant debug
- Les Edge Functions Supabase sont utilisées pour Stripe webhooks
- Le système utilise Claude AI pour analyser les fichiers Excel des clients
- Chaque client a une structure Excel différente → parsing adaptatif
