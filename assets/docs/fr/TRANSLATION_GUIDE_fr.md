# Guide de traduction pour Aquarium AI

Merci de l'intérêt que vous portez à la traduction d'Aquarium AI ! Ce guide vous aidera à contribuer des traductions pour rendre l'application accessible aux utilisateurs du monde entier.

## Présentation

Aquarium AI utilise le système d'internationalisation (i18n) intégré de Flutter avec des fichiers ARB (Application Resource Bundle). Chaque langue possède son propre fichier ARB contenant toutes les chaînes traduisibles.

## Premiers pas

### Prérequis

- Notions de base du format JSON
- Maîtrise de la langue cible
- Un éditeur de texte (VS Code, Sublime Text ou tout éditeur de votre choix)

### Structure des fichiers

Les fichiers de traduction se trouvent dans :

```text
lib/l10n/
├── app_en.arb    (English - template)
├── app_es.arb    (Spanish - example)
├── app_fr.arb    (French - example)
└── app_XX.arb    (Your language)
```

## Comment ajouter une nouvelle langue

### Étape 1 : Créer votre fichier ARB

1. Copiez le fichier `app_en.arb`
2. Renommez-le en `app_XX.arb`, où `XX` est le code de votre langue (p. ex. `app_de.arb` pour l'allemand, `app_ja.arb` pour le japonais)
3. Mettez à jour la valeur `@@locale` avec le code de votre langue

**Codes de langue courants :**

- `de` - Allemand
- `ja` - Japonais
- `zh` - Chinois (simplifié)
- `pt` - Portugais
- `it` - Italien
- `ru` - Russe
- `ko` - Coréen
- `ar` - Arabe
- `hi` - Hindi
- `nl` - Néerlandais

Retrouvez d'autres codes de langue ici : <https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>

### Étape 2 : Traduire les chaînes

Traduisez chaque valeur de chaîne (mais PAS les clés). Voici un exemple :

**Anglais (app_en.arb) :**

```json
{
  "@@locale": "en",
  "welcomeTitle": "Welcome",
  "myTanks": "My Tanks"
}
```

**Allemand (app_de.arb) :**

```json
{
  "@@locale": "de",
  "welcomeTitle": "Willkommen",
  "myTanks": "Meine Aquarien"
}
```

### Étape 3 : Gérer les espaces réservés

Certaines chaînes contiennent des espaces réservés comme `{count}`. Conservez ces espaces réservés sans les modifier :

**Anglais :**

```json
"totalTanks": "Total: {count}"
```

**Allemand :**

```json
"totalTanks": "Gesamt: {count}"
```

### Étape 4 : Conserver les caractères spéciaux

Conservez les caractères spéciaux et la mise en forme :

- Emojis : 🐠, 🤖, 📷, etc.
- Symboles spéciaux : CO₂, ₂, etc.
- Entités HTML et séquences d'échappement

### Étape 5 : Mettre à jour main.dart

Après avoir créé votre fichier ARB, ajoutez votre langue à la liste `supportedLocales` dans `lib/main.dart` :

```dart
supportedLocales: const [
  Locale('en'), // English
  Locale('es'), // Spanish
  Locale('fr'), // French
  Locale('de'), // German (your new language)
],
```

## Conseils de traduction

### 1. Le contexte est important

- Lisez les champs `@description` dans le fichier ARB anglais pour obtenir du contexte
- En cas de doute, vérifiez où la chaîne est utilisée dans l'application

### 2. Maintenir la cohérence

- Utilisez une terminologie cohérente tout au long de la traduction
- Adoptez un ton professionnel mais accessible
- Respectez le style des traductions existantes

### 3. Adaptation culturelle

- Adaptez les expressions idiomatiques à votre culture
- Tenez compte des différences régionales de votre langue

### 4. Termes techniques

Certains termes techniques doivent rester en anglais ou utiliser des traductions communément acceptées :

- API Key
- AI (Artificial Intelligence)
- Noms de modèles (Gemini, OpenAI, Groq)
- Tank (terminologie aquariophile)

### 5. Considérations de longueur

- Essayez de conserver une longueur approximativement identique à l'original
- Les traductions très longues risquent de ne pas s'afficher correctement dans l'interface
- Si nécessaire, utilisez des abréviations courantes dans votre langue

## Tester votre traduction

Même si nous ne vous demandons pas de compiler et tester l'application vous-même, voici comment vérifier votre travail :

1. **Vérifier la syntaxe JSON** : Utilisez un validateur JSON (<https://jsonlint.com/>)
2. **Vérifier la complétude** : Assurez-vous que toutes les clés de `app_en.arb` sont traduites
3. **Vérifier les espaces réservés** : Confirmez que les espaces réservés comme `{count}` sont conservés

## Référence de la structure du fichier ARB

Chaque fichier ARB contient :

1. **Identifiant de paramètres régionaux :**

   ```json
   "@@locale": "en"
   ```

2. **Clé et valeur de traduction :**

   ```json
   "welcomeTitle": "Welcome"
   ```

3. **Métadonnées (optionnel, provenant du modèle) :**

   ```json
   "@welcomeTitle": {
     "description": "Title for the welcome screen"
   }
   ```

**Important :** Ne traduisez que les valeurs (côté droit), jamais les clés (côté gauche).

## Soumettre votre traduction

### Via une Pull Request (recommandé)

1. Forkez le dépôt
2. Créez une nouvelle branche : `git checkout -b translation/your-language`
3. Ajoutez votre fichier ARB dans `lib/l10n/`
4. Mettez à jour `lib/main.dart` pour inclure vos paramètres régionaux
5. Validez vos modifications : `git commit -m "Add [Language] translation"`
6. Poussez vers votre fork : `git push origin translation/your-language`
7. Créez une Pull Request sur GitHub

### Via une Issue

Si vous n'êtes pas familier avec Git :

1. Créez une nouvelle issue sur GitHub
2. Titre : "Translation: [Your Language]"
3. Joignez votre fichier ARB complété
4. Nous l'intégrerons pour vous !

## Liste de vérification de la traduction

Avant de soumettre, vérifiez :

- [ ] Le fichier ARB est correctement nommé (`app_XX.arb`)
- [ ] La valeur `@@locale` correspond au nom du fichier
- [ ] Toutes les chaînes de `app_en.arb` sont incluses
- [ ] Les espaces réservés sont conservés (p. ex. `{count}`)
- [ ] Les caractères spéciaux sont maintenus
- [ ] La syntaxe JSON est valide
- [ ] La langue est ajoutée à `supportedLocales` dans `main.dart`

## Besoin d'aide ?

- **Des questions ?** Ouvrez une issue sur GitHub avec le label « translation »
- **Incertain d'une chaîne ?** Posez la question dans l'issue avant de traduire
- **Vous avez trouvé une erreur ?** Signalez-la ou soumettez une correction

## Exemples de langues

Consultez ces exemples comme référence :

- Anglais : `lib/l10n/app_en.arb` (modèle)
- Espagnol : `lib/l10n/app_es.arb`
- Français : `lib/l10n/app_fr.arb`

## Remerciements

Tous les traducteurs seront crédités dans la section À propos de l'application et dans le README. Merci de rendre Aquarium AI accessible à davantage de personnes !

## État de couverture des langues

| Langue | Code | Statut | Traducteur |
| ------ | ---- | ------ | ---------- |
| Anglais | en | ✅ Complet | Natif |
| Espagnol | es | ✅ Complet | Communauté |
| Français | fr | ✅ Complet | Communauté |
| Allemand | de | ✅ Complet | Communauté |
| Japonais | ja | 🔄 Nécessaire | - |
| Chinois | zh | 🔄 Nécessaire | - |
| Portugais | pt | 🔄 Nécessaire | - |

Vous souhaitez ajouter votre langue ? Suivez ce guide et soumettez une PR !

## Avancé : Ajouter d'autres chaînes

À mesure que l'application évolue, de nouvelles chaînes peuvent être ajoutées à `app_en.arb`. Pour mettre à jour votre traduction :

1. Récupérez les dernières modifications du dépôt principal
2. Vérifiez si de nouvelles chaînes ont été ajoutées à `app_en.arb`
3. Ajoutez les traductions des nouvelles chaînes à votre fichier ARB
4. Soumettez une PR de mise à jour

## Merci

Votre contribution aide les passionnés d'aquariophilie du monde entier à utiliser cette application dans leur langue maternelle. Chaque traduction fait la différence ! 🌍🐠
