# Journal des modifications

Toutes les modifications notables apportées à ce projet sont documentées dans ce fichier.

## [3.1.00] - 2026-3-3 – Avantages, fonctionnalités communauté et profil

### Ajouté

- **Ajout d'une section profil utilisateur avec authentification sociale**
- **Niveau Fondateur Aquariste, image héro moderne du Tank Showcase, système d'avantages fondateur, corrections des publications communautaires**
- Familles de polices sélectionnables par l'utilisateur dans l'écran d'apparence
- Sous-type d'aquarium récifal pour les aquariums marins avec prise en charge du filtrage
- Tri des données de poissons et classification de compatibilité récifale
- Registre global de TankTag avec prise en charge explicite de la sauvegarde/restauration
- Fonction de partage/importation d'un seul bac
- Écran d'accueil : grille à 2 colonnes avec bascule liste/grille + mode grille/mosaïque de gestion des bacs et personnalisation des cartes
- Ajout d'une photo de bannière principale du bac à l'écran des détails du bac
- Permet le masquage permanent de l'en-tête de l'écran d'accueil

### Modifié

- Chips de suggestions du chatbot localisées, paramètre de langue de réponse IA ajouté
- Localisation des écrans de compatibilité IA, calculateurs, à propos, informations et paramètres du fournisseur IA
- Chaînes codées en dur localisées dans les paramètres, le tiroir, l'écran d'accueil, la boîte de dialogue de promotion AquaPi, l'écran d'historique et plus encore

**Journal complet des modifications**: <https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.0.10...v3.1.00>

## [3.0.10] - 2026-2-27 – Mises à jour visuelles, corrections de l'outil Stocking

### Ajouté

- Amélioration du contraste visuel des boutons et des chips dans toute l'application
- Ajout des thèmes FlexColorScheme, du sélecteur de palette AppColorTheme, de l'écran
  d'apparence et du sélecteur de couleur personnalisé

### Corrigé

- Correction du bug où la fenêtre contextuelle d'espèces n'affichait pas les noms communs
- Correction du bug de retour arrière de l'outil AI Stocking, amélioration de l'UX de
  sélection d'espèces et taille du bac rendue optionnelle

**Journal complet des modifications**:
<https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.0.03...v3.0.10>

## [3.0.03] - 2026-2-24 – Mises à jour majeures

### Ajouté

- **Clé API Groq développeur avec limitation de débit ; fournisseur par défaut → Groq**
  - **Fonctionnalités AI gratuites dans l'application activées !!** Celles-ci sont
    limitées et peuvent être désactivées à tout moment. Groq est utilisé par défaut ;
    pas aussi performant que Gemini, mais fonctionnel.
- **Offrez-moi un café !** Option pour supprimer les publicités pour **0,99 USD**
  (pour l'instant). Ce sont les *« Avantages Fondateur »* pour ceux qui soutiennent
  le développement.
- **Outil AI d'informations sur les poissons ajouté**, écran de résultats dédié et
  chips d'outils mis en avant dans la carte du chatbot AI
- Feuille de partage native pour tous les résultats d'analyse AI
- Couleurs de thème dans toute l'interface de l'application avec regroupement de sections
- Journal des modifications intégré ajouté aux écrans Paramètres et Informations
- Historique des analyses AI ajouté : journal persistant avec favoris et relecture
  complète des rapports
- Dialogue de sélection granulaire d'espèces ajouté à l'outil de compatibilité
- Étiquettes d'espèces ajoutées aux habitants du bac

### Modifié

- Écrans de détails et de création de bac convertis en navigation par onglets
- Descriptions des cartes de l'écran d'accueil améliorées avec des détails
  spécifiques sur les fonctionnalités
- Superposition de modification des habitants repensée : sélecteur de poissons
  repliable, rembourrage supérieur, protection intelligente des noms
- Consommation de tokens AI réduite chez tous les fournisseurs
- Croissance illimitée des tokens dans tous les fournisseurs de chat résolue
- Gestion des erreurs AI améliorée : dialogue moderne, raccourcis de clé API et
  retour arrière en cas d'erreur de limite de débit

### Supprimé

- Suppression de « Inclure les noms personnalisés » des dialogues de rapport AI

**Journal complet des modifications**:
<https://github.com/TheRealFalseReality/Aquarium-AI/compare/v2.1.04...v3.0.03>

## [Non publié]

### À ajouter

- Détails spécifiques aux poissons, équipements et plantes avec images
- Meilleure et plus moderne UX/UI de paramètres et de dosage
- Métriques détaillées par bac avec métriques personnalisées (dernier changement d'eau,
  nombre de poissons, niveau d'algues ?)
- Guides de peuplement par bac
- Notifications et journal d'événements en vue calendrier
- Dépenses ou P&L
- Partager et importer des bacs avec des amis
- Fil d'exploration
- [**Suggérez plus !**](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
  Demander une fonctionnalité ou signaler un bug

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
