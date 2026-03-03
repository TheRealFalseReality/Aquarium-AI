# Guide d'utilisation de la localisation pour les développeurs

Ce guide explique comment utiliser le système de localisation dans Aquarium AI pour les développeurs travaillant sur le code source.

## Configuration

Après avoir récupéré les modifications i18n, vous devez :

1. **Installer les dépendances** :

   ```bash
   flutter pub get
   ```

2. **Générer les fichiers de localisation** :

   ```bash
   flutter gen-l10n
   ```

   Cela génère le code Dart dans `.dart_tool/flutter_gen/gen_l10n/`

   **Remarque** : Cette étape est également exécutée automatiquement lorsque vous utilisez `flutter run` ou `flutter build`.

3. **Vérifier les fichiers générés** :
   Les fichiers suivants doivent être générés :
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_en.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_es.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_fr.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_de.dart`

## Démarrage rapide

### Accéder aux traductions dans les widgets

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Text(l10n.welcomeTitle);
  }
}
```

### Modèles courants

#### 1. Texte simple

**Avant :**

```dart
Text('Welcome')
```

**Après :**

```dart
Text(AppLocalizations.of(context)!.welcomeTitle)
```

#### 2. Avec des espaces réservés

**Avant :**

```dart
Text('Total: $count')
```

**Après (dans le fichier ARB) :**

```json
"totalTanks": "Total: {count}",
"@totalTanks": {
  "description": "Total number of tanks",
  "placeholders": {
    "count": {
      "type": "int"
    }
  }
}
```

**Après (dans le code) :**

```dart
Text(AppLocalizations.of(context)!.totalTanks(count))
```

#### 3. Dans AppBar

**Avant :**

```dart
AppBar(
  title: Text('Settings'),
)
```

**Après :**

```dart
AppBar(
  title: Text(AppLocalizations.of(context)!.settings),
)
```

#### 4. Dans les dialogues

**Avant :**

```dart
AlertDialog(
  title: Text('Error'),
  content: Text('Something went wrong'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Close'),
    ),
  ],
)
```

**Après :**

```dart
final l10n = AppLocalizations.of(context)!;

AlertDialog(
  title: Text(l10n.error),
  content: Text('Something went wrong'), // Add to ARB if needed
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(l10n.close),
    ),
  ],
)
```

#### 5. Dans ListView/ListTile

**Avant :**

```dart
ListTile(
  title: Text('My Tanks'),
  subtitle: Text('Manage your aquariums'),
)
```

**Après :**

```dart
final l10n = AppLocalizations.of(context)!;

ListTile(
  title: Text(l10n.myTanks),
  subtitle: Text('Manage your aquariums'), // Add to ARB if needed
)
```

## Ajouter de nouvelles chaînes

### Étape 1 : Ajouter à app_en.arb

```json
{
  "newStringKey": "English Text",
  "@newStringKey": {
    "description": "Description of what this string is for"
  }
}
```

### Étape 2 : Exécuter la génération de code

```bash
flutter gen-l10n
```

Cela génère le code Dart dans `.dart_tool/flutter_gen/gen_l10n/`

### Étape 3 : Utiliser dans le code

```dart
Text(AppLocalizations.of(context)!.newStringKey)
```

### Étape 4 : Mettre à jour les autres langues

Ajouter les traductions dans `app_es.arb`, `app_fr.arb`, etc.

## Travailler avec les pluriels

Pour les chaînes qui changent selon le nombre :

**Dans app_en.arb :**

```json
{
  "tankCount": "{count, plural, =0{No tanks} =1{1 tank} other{{count} tanks}}",
  "@tankCount": {
    "description": "Number of tanks",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

**Dans le code :**

```dart
Text(AppLocalizations.of(context)!.tankCount(tankList.length))
```

## Bonnes pratiques

### 1. Extraire toutes les chaînes visibles par l'utilisateur

Chaque chaîne que les utilisateurs voient doit figurer dans les fichiers ARB :

- ✅ Étiquettes de boutons
- ✅ Titres d'écrans
- ✅ Messages d'erreur
- ✅ Descriptions
- ✅ Infobulles
- ❌ Journaux de débogage
- ❌ Identifiants internes
- ❌ Points de terminaison API

### 2. Utiliser des clés descriptives

**Bien :**

```json
"settingsUpdatedSuccess": "Settings updated successfully!"
```

**Mauvais :**

```json
"msg1": "Settings updated successfully!"
```

### 3. Fournir du contexte

Toujours inclure `@description` :

```json
{
  "save": "Save",
  "@save": {
    "description": "Save button label"
  }
}
```

### 4. Gérer la sécurité nulle

Toujours utiliser l'opérateur d'assertion nulle `!` lors de l'accès à AppLocalizations :

```dart
final l10n = AppLocalizations.of(context)!;
```

Cela est sûr car nous configurons `localizationsDelegates` dans `main.dart`.

### 5. Créer une variable auxiliaire

Pour plusieurs utilisations dans le même widget :

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Column(
    children: [
      Text(l10n.welcomeTitle),
      Text(l10n.welcomeSubtitle),
      ElevatedButton(
        onPressed: () {},
        child: Text(l10n.save),
      ),
    ],
  );
}
```

## Tester les traductions

### 1. Exécuter l'application dans différentes langues

Changez la langue de votre appareil/émulateur pour tester les traductions.

### 2. Forcer une langue dans le code (pour les tests)

```dart
MaterialApp(
  locale: Locale('es'), // Force Spanish
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

### 3. Vérifier les traductions manquantes

Si une traduction est manquante, l'application reviendra à l'anglais.

## Problèmes courants

### Problème : « AppLocalizations not found »

**Solution :** Exécuter la génération de code :

```bash
flutter gen-l10n
```

### Problème : « l10n.myNewString doesn't exist »

**Solution :**

1. S'assurer que la clé est dans `app_en.arb`
2. Exécuter `flutter gen-l10n`
3. Redémarrer l'IDE/éditeur

### Problème : L'espace réservé ne fonctionne pas

**Solution :** Vérifier la syntaxe du fichier ARB :

```json
{
  "message": "Hello {name}",
  "@message": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

## Guide de migration

Pour migrer les chaînes codées en dur existantes :

1. **Trouver la chaîne codée en dur :**

   ```dart
   Text('Welcome')
   ```

2. **Ajouter à app_en.arb :**

   ```json
   "welcomeTitle": "Welcome"
   ```

3. **Exécuter la génération :**

   ```bash
   flutter gen-l10n
   ```

4. **Mettre à jour le code :**

   ```dart
   Text(AppLocalizations.of(context)!.welcomeTitle)
   ```

5. **Ajouter aux autres fichiers de langue :**

   ```json
   // app_es.arb
   "welcomeTitle": "Bienvenido"
   ```

## Structure des fichiers

```text
lib/
│   ├── app_en.arb    (English - template)
│   ├── app_es.arb    (Spanish)
│   ├── app_fr.arb    (French)
│   └── ...
└── main.dart

.dart_tool/
└── flutter_gen/
    └── gen_l10n/
        ├── app_localizations.dart
        ├── app_localizations_en.dart
        ├── app_localizations_es.dart
        └── ...
```

## Ressources

- [Guide d'internationalisation Flutter](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [Format de fichier ARB](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Notre guide de traduction](TRANSLATION_GUIDE.md) – Pour les traducteurs

## Exemple : Migration complète d'un widget

**Avant :**

```dart
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
      ),
      body: Column(
        children: [
          Text('Your intelligent assistant'),
          ElevatedButton(
            onPressed: () {},
            child: Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
```

**Après :**

```dart
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.welcomeTitle),
      ),
      body: Column(
        children: [
          Text(l10n.welcomeSubtitle),
          ElevatedButton(
            onPressed: () {},
            child: Text(l10n.getStarted),
          ),
        ],
      ),
    );
  }
}
```

Bonne localisation ! 🌍
