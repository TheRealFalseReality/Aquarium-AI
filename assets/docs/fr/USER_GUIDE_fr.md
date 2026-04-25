# Aquarium AI – Guide de l'utilisateur

Bienvenue dans **Aquarium AI** ! Ce guide explique chaque outil de l'application et
comment en tirer le meilleur parti.

---

## Table des matières

1. [Premiers pas – Clés API AI](#premiers-pas--clés-api-ai)
2. [Gestion des bacs](#gestion-des-bacs)
3. [Outil de compatibilité AI](#outil-de-compatibilité-ai)
4. [Chatbot AI](#chatbot-ai)
5. [Analyseur de photos](#analyseur-de-photos)
6. [Analyse des paramètres de l'eau](#analyse-des-paramètres-de-leau)
7. [Recherche d'informations sur les poissons](#recherche-dinformations-sur-les-poissons)
8. [Générateur de scripts d'automatisation](#générateur-de-scripts-dautomatisation)
9. [Assistant de peuplement AI](#assistant-de-peuplement-ai)
10. [Calculateurs d'aquarium](#calculateurs-daquarium)
11. [Journal des paramètres](#journal-des-paramètres)
12. [Journal de dosage](#journal-de-dosage)
13. [Historique des analyses](#historique-des-analyses)
14. [Communauté](#communauté)
15. [Paramètres et apparence](#paramètres-et-apparence)

---

## Premiers pas – Clés API AI

La plupart des outils alimentés par l'IA nécessitent une clé API d'un fournisseur
compatible.

**Niveau gratuit (aucune clé requise) :**

Aquarium AI comprend un niveau gratuit limité alimenté par une clé développeur intégrée.
Ce niveau prend en charge un petit nombre de requêtes par jour avec une fenêtre
d'historique de chat plus courte. Il peut être réduit ou désactivé à tout moment.

**Apportez votre propre clé (recommandé) :**

Pour un accès illimité, ajoutez votre propre clé API dans
**Paramètres → Clés API AI**. Fournisseurs compatibles :

| Fournisseur | Où obtenir une clé |
| ----------- | ------------------ |
| **Groq** (par défaut) | [console.groq.com](https://console.groq.com) |
| **Google Gemini** | [aistudio.google.com](https://aistudio.google.com) |
| **OpenAI (ChatGPT)** | [platform.openai.com](https://platform.openai.com) |

Vous pouvez changer le fournisseur AI actif à tout moment dans
**Paramètres → Fournisseur AI**.

---

## Gestion des bacs

**Route :** Menu principal → *Gestion des bacs*

La gestion des bacs est le hub central pour suivre vos aquariums.

### Créer un bac

1. Appuyez sur le bouton **+** (en bas à droite).
2. Renseignez le **Nom**, le **Type** (Eau douce / Marine) et le **Volume** (gallons ou
   litres).
3. Ajoutez optionnellement une **Description**, un indicateur compatible récif, et une
   **photo** ou une **image de bannière**.
4. Appuyez sur **Enregistrer**.

### Cartes de bac

Chaque carte affiche :

- Photo / image de bannière du bac
- Nom, type et volume
- Nombre d'habitants et score d'harmonie
- Boutons d'action rapide (Ajouter un habitant, Journal des paramètres, Journal de
  dosage, Analyse AI)
- Outils du menu de la carte, dont le **Calculateur du volume de changement d'eau** (20 % par défaut, avec pourcentage ajustable pour voir les gallons/litres à remplacer)

### Trier et filtrer

Utilisez le bouton **trier / filtrer** (en haut à droite) pour trier les bacs par nom,
type, taille ou date, et filtrer par type de bac ou étiquettes.

### Étiquettes de bac

Assignez des **étiquettes** colorées aux bacs pour un regroupement facile. Appuyez sur
un chip d'étiquette pour filtrer la liste. Gérez votre bibliothèque d'étiquettes globale
dans **Paramètres → Étiquettes d'espèces**.

### Détails du bac

Appuyez sur n'importe quelle carte de bac pour ouvrir ses détails, organisés en
onglets :

- **Aperçu** – modifier les informations du bac, voir le score d'harmonie
- **Habitants** – gérer les poissons et autres résidents
- **Paramètres** – journal et graphiques des paramètres de l'eau
- **Dosage** – journal des traitements / suppléments
- **Activité** – événements récents

### Outils AI depuis un bac

Depuis une carte de bac ou son écran de détails, vous pouvez lancer des outils AI
préchargés avec les données de votre bac :

- **Vérification de compatibilité AI** – analyser tous les habitants actuels
- **Recommandations de peuplement** – obtenir des suggestions AI pour de nouveaux
  ajouts
- **Analyse de photo** – analyser une photo du bac

### Sauvegarde et restauration

Utilisez **Paramètres → Sauvegarde / Restauration** pour exporter toutes les données
du bac dans un fichier JSON et les importer sur un autre appareil.

---

## Outil de compatibilité AI

**Route :** Menu principal → *Outil de compatibilité AI*
**Nécessite :** Clé API ou niveau gratuit

L'outil de compatibilité vous permet de sélectionner des espèces dans une base de
données de plus de 69 espèces d'eau douce et marines et de générer un rapport AI
détaillé.

### Comment utiliser

1. Choisissez l'onglet **Eau douce** ou **Marine**.
2. Parcourez ou **recherchez** dans la liste de poissons. Utilisez le filtre compatible
   récif pour les bacs marins.
3. **Appuyez sur les cartes de poissons** pour sélectionner les espèces que vous
   souhaitez vérifier ensemble (les cartes sélectionnées affichent une coche).
4. Appuyez sur **Vérifier la compatibilité** pour générer le rapport AI.

### Lire le rapport

Le rapport comprend :

- **Évaluation globale de compatibilité** avec un score d'harmonie
- **Notes de soins par espèce** (pH, température, agressivité)
- **Avertissements de conflits potentiels**
- **Taille de bac recommandée** pour le groupe sélectionné

---

## Chatbot AI

**Route :** Menu principal → *Chatbot AI*
**Nécessite :** Clé API ou niveau gratuit

Le Chatbot est un assistant d'aquarium polyvalent. Posez n'importe quelle question sur
les soins aux poissons, la chimie de l'eau, l'identification des maladies,
l'équipement, et plus encore.

### Chips d'outils AI intégrés

En haut de l'écran de chat, vous trouverez des chips de lancement rapide pour des
outils AI spécialisés :

- **Analyseur de photos** – lancer sans quitter le chat
- **Analyse des paramètres de l'eau**
- **Info poissons**
- **Générateur de scripts d'automatisation**

### Conseils de chat

- Les conversations sont désormais conservées entre les sessions de l'application.
- Utilisez le menu **Conversations** en haut à droite pour créer des conversations
  nommées.
- Vous pouvez associer chaque conversation à un aquarium précis, puis la filtrer et la
  recharger depuis le gestionnaire de conversations.
- Appuyez sur l'icône **partager** sur n'importe quelle réponse pour partager ou copier
  le texte.
- Créez une **nouvelle conversation** depuis le menu lorsque vous voulez repartir de
  zéro.

---

## Analyseur de photos

**Route :** Chatbot AI → *Chip Analyseur de photos* ou Menu principal →
*Analyseur de photos*

**Nécessite :** Clé API ou niveau gratuit (Gemini ou OpenAI pour de meilleurs résultats)

Analysez des photos d'aquarium pour identifier les poissons, détecter les maladies,
évaluer la clarté de l'eau et obtenir des recommandations.

### Comment utiliser

1. Appuyez sur **Choisir dans la galerie** ou **Prendre une photo**.
2. (Optionnel) Ajoutez une note décrivant ce que vous recherchez (p.ex. "Est-ce de
   l'ich ?").
3. Appuyez sur **Analyser la photo**.
4. L'écran de résultats affiche les conclusions de l'IA avec les actions suggérées.

---

## Analyse des paramètres de l'eau

**Route :** Chatbot AI → *Chip Analyse des paramètres de l'eau*
**Nécessite :** Clé API ou niveau gratuit

Entrez vos paramètres d'eau actuels et recevez une interprétation AI avec des conseils
ciblés.

### Entrées

- **Type de bac** (eau douce / marine)
- **pH**
- **Température** (°F ou °C)
- **Salinité / Densité spécifique** (marine uniquement)
- **Notes supplémentaires** (ammoniaque, nitrite, nitrate, KH, etc.)

L'IA signalera les valeurs hors des plages saines et suggérera des actions correctives.

---

## Recherche d'informations sur les poissons

**Route :** Chatbot AI → *Chip Info poissons*
**Nécessite :** Clé API ou niveau gratuit

Obtenez une fiche de soins complète pour n'importe quelle espèce de poisson.

### Comment utiliser

1. Entrez un ou plusieurs noms d'espèces (communs ou scientifiques).
2. Entrez optionnellement la taille de votre bac pour des conseils adaptés à la taille.
3. Appuyez sur **Obtenir les infos**.

Le résultat comprend :

- Noms communs et scientifiques
- Habitat naturel et origine
- Exigences de température, pH et dureté de l'eau
- Notes sur le régime alimentaire et l'alimentation
- Colocataires de bac compatibles
- Faits intéressants

---

## Générateur de scripts d'automatisation

**Route :** Chatbot AI → *Chip Script d'automatisation*
**Nécessite :** Clé API ou niveau gratuit

Générez des scripts d'automatisation pour les contrôleurs d'aquarium (p.ex. Apex, GHL,
Hydros).

### Comment utiliser

1. Décrivez l'automatisation dont vous avez besoin en langage courant (p.ex. "Allumer
   la pompe de sump à 8h, l'éteindre à 22h, et déclencher une alarme si le pH tombe
   en dessous de 7,8").
2. Appuyez sur **Générer le script**.
3. Le résultat affiche un script prêt à l'emploi avec des commentaires explicatifs.

---

## Assistant de peuplement AI

**Route :** Menu principal → *Assistant de peuplement AI*
**Nécessite :** Clé API ou niveau gratuit

Obtenez des recommandations de peuplement personnalisées pour un bac nouveau ou
existant.

### Comment utiliser

1. Sélectionnez **Eau douce** ou **Marine**.
2. Entrez la **taille de votre bac** (optionnel mais améliore la précision).
3. (Optionnel) Sélectionnez les poissons que vous avez déjà ou souhaitez à l'aide du
   **sélecteur d'espèces**.
4. Ajoutez des notes supplémentaires (préférence de biotope, niveau d'expérience, etc.).
5. Appuyez sur **Obtenir des recommandations**.

Le rapport liste les espèces appropriées avec une brève note de soins pour chacune,
plus des conseils sur la densité de peuplement.

---

## Calculateurs d'aquarium

**Route :** Menu principal → *Calculateurs*

Un ensemble de calculateurs instantanés hors ligne — aucune clé API requise.

| Calculateur | Ce qu'il fait |
| ----------- | ------------- |
| **Salinité** | Convertit entre PPT, PSU et densité spécifique |
| **CO₂** | Estime le CO₂ dissous à partir du pH et du KH |
| **Alcalinité** | Convertit entre dKH, meq/L et ppm |
| **Température** | Convertit entre °F et °C |

### Calculateur de volume de bac

**Route :** Menu principal → *Calculateur de volume de bac*

Calculez le volume d'eau des bacs rectangulaires, cylindriques ou hexagonaux en
utilisant les dimensions internes.

---

## Journal des paramètres

**Route :** Détails du bac → onglet *Paramètres*

(Également accessible depuis le bouton d'action rapide de la carte du bac)

Suivez la qualité de l'eau au fil du temps avec des graphiques et des journaux.

### Enregistrer une lecture

1. Appuyez sur **+ Ajouter un paramètre**.
2. Sélectionnez le type de paramètre (pH, Ammoniaque, Nitrite, Nitrate, Température,
   Salinité, KH, etc.) ou entrez un nom personnalisé.
3. Entrez la valeur et l'unité.
4. Appuyez sur **Enregistrer**.

### Graphiques

Appuyez sur la flèche **développer** d'un groupe de paramètres pour afficher un
graphique de série temporelle. Utile pour repérer les tendances et valider l'impact
des changements d'eau.

### Alertes proactives de tendance IA

Lorsqu'un schéma à risque est détecté dans les relevés récents, le Journal des
paramètres affiche désormais en haut une carte **Alertes de tendance IA**. Par
exemple, si le nitrate augmente pendant plusieurs jours, l'app suggère de manière
proactive d'envisager un changement d'eau.

---

## Journal de dosage

**Route :** Détails du bac → onglet *Dosage*

(Également accessible depuis le bouton d'action rapide de la carte du bac)

Conservez un enregistrement des traitements, suppléments et additifs.

### Ajouter une entrée

1. Appuyez sur **+ Ajouter une entrée de dosage**.
2. Entrez le nom du produit, la dose et l'unité.
3. Ajoutez optionnellement des notes (raison, numéro de lot, etc.).
4. Appuyez sur **Enregistrer**.

Les entrées sont regroupées par produit pour faciliter le suivi des traitements
récurrents.

---

## Historique des analyses

**Route :** Menu principal → *Historique des analyses*

Chaque résultat AI (rapport de compatibilité, recommandation de peuplement, analyse
des paramètres de l'eau, info poissons, analyse de photo) est automatiquement sauvegardé
ici.

- **Favoris** en appuyant sur l'icône étoile.
- **Relire** n'importe quel résultat pour le voir en entier.
- **Supprimer** des entrées individuelles ou effacer tout l'historique.

---

## Communauté

**Route :** Menu principal → *Communauté*

Parcourez et partagez des publications avec d'autres utilisateurs d'Aquarium AI.
Connectez-vous (anonymement ou avec Google/Facebook) pour publier, commenter et
réagir.

### Types de publication

- **Général** – discussion ouverte
- **Question** – posez la question à la communauté
- **Présentation** – montrez votre bac
- **Conseils** – partagez vos connaissances

### Se connecter

Appuyez sur **Se connecter** en haut de l'écran Communauté. Vous pouvez utiliser
Google, Facebook ou rester anonyme. Les comptes anonymes peuvent être mis à niveau
vers un compte nommé plus tard dans **Profil**.

---

## Paramètres et apparence

**Route :** Menu principal → *Paramètres*

| Paramètre | Description |
| --------- | ----------- |
| **Fournisseur AI** | Choisir entre Groq, Gemini et OpenAI |
| **Clés API AI** | Stocker vos clés API personnelles |
| **Limite d'historique de chat** | Nombre de messages précédents envoyés avec chaque requête |
| **Affichage du bac** | Afficher/masquer photos, métriques, habitants, notes, etc. |
| **Sauvegarde / Restauration** | Exporter et importer toutes les données du bac |
| **Notifications** | Planifier des rappels pour les changements d'eau, l'alimentation, etc. |

### Apparence

**Route :** Menu principal → *Apparence* (ou Paramètres → Apparence)

- Choisir parmi **15 thèmes de couleur** dont Material You (couleur dynamique depuis
  votre fond d'écran)
- Sélectionner une couleur de départ personnalisée avec le sélecteur de couleur
- Sélectionner une **famille de polices** (Poppins, Karla, Noto Sans)
- Basculer entre le mode **clair / sombre / système**

---

*Pour la documentation développeur, les guides de contribution et l'aide à la
traduction, consultez les autres documents dans la section Information.*
