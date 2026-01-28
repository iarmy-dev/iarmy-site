/**
 * icons.js - Source UNIQUE pour les icônes de modules iArmy
 *
 * Ce fichier est la SEULE source de vérité pour les icônes des modules.
 * Toutes les pages utilisent getModuleIcon() ou getModuleIconWithBg().
 *
 * Usage:
 *   const iconHtml = getModuleIcon('telegram_sheets', '#22c55e');
 *   const iconWithBg = getModuleIconWithBg('bottles_count', '#06b6d4', 44);
 */

// Types d'icônes disponibles (correspondant à icon_type dans la table modules)
const MODULE_ICON_TYPES = [
  { id: 'telegram_sheets', name: 'Tableau' },
  { id: 'bottles_count', name: 'Stock' },
  { id: 'people_pdf', name: 'Equipe' },
  { id: 'calendar', name: 'Calendrier' },
  { id: 'reservation', name: 'Reservation' },
  { id: 'star', name: 'Etoile' },
  { id: 'custom', name: 'Defaut' }
];

/**
 * Templates d'icônes - UN SEUL template par icon_type
 * Utilisé partout: cards, admin, facturation, etc.
 */
const MODULE_ICON_TEMPLATES = {
  // Compta - Tableau/Spreadsheet
  telegram_sheets: (color) => `
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <rect x="3" y="3" width="18" height="18" rx="2"/>
      <line x1="3" y1="9" x2="21" y2="9"/>
      <line x1="9" y1="21" x2="9" y2="9"/>
    </svg>`,

  // Stock - Boîte/Cube
  bottles_count: (color) => `
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
      <polyline points="3.27 6.96 12 12.01 20.73 6.96"/>
      <line x1="12" y1="22.08" x2="12" y2="12"/>
    </svg>`,

  // Paie - Personnes/Equipe
  people_pdf: (color) => `
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
      <circle cx="9" cy="7" r="4"/>
      <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
      <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
    </svg>`,

  // Planning - Calendrier
  calendar: (color) => `
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
      <line x1="16" y1="2" x2="16" y2="6"/>
      <line x1="8" y1="2" x2="8" y2="6"/>
      <line x1="3" y1="10" x2="21" y2="10"/>
    </svg>`,

  // Réservations - Check/Liste
  reservation: (color) => `
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
      <polyline points="22 4 12 14.01 9 11.01"/>
    </svg>`,

  // Fidélité - Etoile
  star: (color) => `
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
    </svg>`,

  // Défaut - Cercle avec point
  custom: (color) => `
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <circle cx="12" cy="12" r="10"/>
      <line x1="12" y1="8" x2="12" y2="12"/>
      <line x1="12" y1="16" x2="12.01" y2="16"/>
    </svg>`
};

/**
 * Obtenir l'icône SVG pour un module
 * @param {string} iconType - Le type d'icône (telegram_sheets, bottles_count, etc.)
 * @param {string} color - La couleur hex (#22c55e, #06b6d4, etc.)
 * @param {number} size - Taille optionnelle (défaut: 24)
 * @returns {string} HTML de l'icône SVG
 */
function getModuleIcon(iconType, color = '#FF6B35', size = 24) {
  const template = MODULE_ICON_TEMPLATES[iconType] || MODULE_ICON_TEMPLATES.custom;
  let svg = template(color);

  // Ajuster la taille si différente de 24
  if (size !== 24) {
    svg = svg.replace(/width="24"/g, `width="${size}"`);
    svg = svg.replace(/height="24"/g, `height="${size}"`);
  }

  return svg;
}

/**
 * Obtenir l'icône avec un conteneur rond coloré (fond)
 * @param {string} iconType - Le type d'icône
 * @param {string} color - La couleur hex
 * @param {number} size - Taille du conteneur (défaut: 44)
 * @returns {string} HTML avec conteneur et icône
 */
function getModuleIconWithBg(iconType, color = '#FF6B35', size = 44) {
  const iconSize = Math.round(size * 0.55);
  const icon = getModuleIcon(iconType, color, iconSize);
  const bgColor = hexToRgba(color, 0.15);

  return `
    <div style="
      width: ${size}px;
      height: ${size}px;
      border-radius: 50%;
      background: ${bgColor};
      display: flex;
      align-items: center;
      justify-content: center;
    ">
      ${icon}
    </div>
  `;
}

/**
 * Convertir hex en rgba
 */
function hexToRgba(hex, alpha = 1) {
  if (!hex || hex.length < 7) return `rgba(255,107,53,${alpha})`;
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r},${g},${b},${alpha})`;
}

/**
 * Helper pour assombrir une couleur
 */
function darkenColor(hex, percent = 20) {
  if (!hex || hex.length < 7) return hex;
  const r = Math.max(0, parseInt(hex.slice(1, 3), 16) - percent);
  const g = Math.max(0, parseInt(hex.slice(3, 5), 16) - percent);
  const b = Math.max(0, parseInt(hex.slice(5, 7), 16) - percent);
  return `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`;
}

// Compatibilité avec l'ancien code (MINI_ICON_TEMPLATES)
// Redirige vers le nouveau système
const MINI_ICON_TEMPLATES = MODULE_ICON_TEMPLATES;

// Export pour modules ES6
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    MODULE_ICON_TYPES,
    MODULE_ICON_TEMPLATES,
    MINI_ICON_TEMPLATES,
    getModuleIcon,
    getModuleIconWithBg,
    hexToRgba,
    darkenColor
  };
}
