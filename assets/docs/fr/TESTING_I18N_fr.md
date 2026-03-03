# Guide de test pour l'internationalisation

Ce guide explique comment tester l'implémentation de l'internationalisation dans Aquarium AI.

## Prérequis

- Flutter SDK installé
- Projet Aquarium AI cloné
- Dépendances installées : `flutter pub get`

## Générer le code de localisation

Avant de tester, générez le code de localisation :

```bash
flutter gen-l10n
```

Cette commande :

- Lit les fichiers ARB depuis `lib/l10n/`
- Génère le code Dart dans `.dart_tool/flutter_gen/gen_l10n/`
- Crée la classe `AppLocalizations` et les implémentations spécifiques aux langues

## Méthodes de test

### 1. Changer la langue du périphérique

**Sur l'émulateur Android :**

1. Ouvrir les Paramètres
2. Naviguer vers Système > Langue et saisie > Langues
3. Ajouter et sélectionner votre langue de test (p. ex., espagnol, français, allemand)
4. Redémarrer l'application
5. Vérifier que les chaînes traduites s'affichent correctement

**Sur le simulateur iOS :**

1. Ouvrir les Réglages
2. Naviguer vers Général > Langue et région
3. Sélectionner votre langue de test
4. Redémarrer l'application
5. Vérifier les traductions

### 2. Forcer une langue spécifique dans le code (pour les tests)

Modifier temporairement `lib/main.dart` pour forcer une langue :

```dart
return MaterialApp(
  locale: const Locale('es'), // Force Spanish
  localizationsDelegates: const [
    AppLocalizations.delegate,
    // ...
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('es'),
    // ...
  ],
  // ...
);
```

**N'oubliez pas de supprimer ceci après les tests !**

### 3. Tester le comportement de repli

Tester ce qui se passe lorsqu'une traduction est manquante :

1. Supprimer une clé d'un fichier ARB non anglais
2. Configurer le périphérique dans cette langue
3. L'application doit revenir à l'anglais pour cette chaîne

### 4. Tester les valeurs des espaces réservés

Pour les chaînes avec des espaces réservés (p. ex., `{count}`) :

1. Naviguer vers la section « Mes aquariums »
2. Créer plusieurs aquariums
3. Vérifier que le nombre s'affiche correctement dans votre langue
4. Vérifier le format : `"Total: {count}"` doit afficher `"Total: 3"` (ou l'équivalent traduit)

### 5. Vérifier les langues RTL (si ajoutées)

Pour les langues de droite à gauche comme l'arabe :

1. Configurer la langue du périphérique en arabe
2. Vérifier que l'interface se reflète correctement
3. Vérifier que le texte s'aligne à droite
4. S'assurer que les icônes et la navigation sont reflétés

## Ce qu'il faut tester

### Écran d'accueil

- [ ] Titre de bienvenue
- [ ] Sous-titre de bienvenue
- [ ] Tous les noms de fonctionnalités (Outil de compatibilité IA, Chatbot IA, etc.)
- [ ] Toutes les descriptions de fonctionnalités
- [ ] Bouton « Créer votre premier aquarium »

### Tiroir de l'application

- [ ] Titre « Mes aquariums »
- [ ] Message « Aucun aquarium pour l'instant »
- [ ] Tous les titres d'éléments de menu
- [ ] Toutes les descriptions d'éléments de menu

### Écran des paramètres

- [ ] Titre des paramètres
- [ ] Texte du bouton Enregistrer
- [ ] Message de succès après l'enregistrement
- [ ] Messages d'erreur pour les clés API manquantes
- [ ] Tous les noms de fournisseurs (le cas échéant)

### Éléments communs

- [ ] Indicateurs de chargement
- [ ] Messages d'erreur
- [ ] Messages de succès
- [ ] Étiquettes de boutons (Enregistrer, Annuler, Supprimer, etc.)

## Liste de vérification des tests

### Pour chaque langue

- [ ] Générer le code de localisation : `flutter gen-l10n`
- [ ] Exécuter l'application : `flutter run`
- [ ] Changer la langue du périphérique
- [ ] Naviguer dans tous les écrans
- [ ] Vérifier que tout le texte est traduit
- [ ] Vérifier qu'aucun texte anglais n'apparaît (sauf les termes techniques)
- [ ] Vérifier que le texte s'insère dans les éléments de l'interface
- [ ] Vérifier que les espaces réservés fonctionnent correctement
- [ ] Tester que les caractères spéciaux s'affichent correctement
- [ ] Vérifier que le texte ne déborde pas des conteneurs

### Cas limites

- [ ] Traductions très longues (p. ex., mots composés allemands)
- [ ] Traductions très courtes
- [ ] Caractères spéciaux (é, ñ, ü, etc.)
- [ ] Indices/exposants (CO₂)
- [ ] Nombres et espaces réservés

## Tests de compilation

### Compilation de débogage

```bash
flutter build apk --debug
# or
flutter build ios --debug
```

Vérifier que les traductions fonctionnent dans l'application compilée.

### Compilation de production

```bash
flutter build apk --release
# or
flutter build ios --release
```

S'assurer qu'aucune donnée de traduction n'est supprimée en mode production.

## Outils de validation

### 1. Validation des fichiers ARB

Valider la syntaxe JSON :

```bash
# Install jq if not already installed
# macOS: brew install jq
# Ubuntu: sudo apt-get install jq

# Validate ARB files
jq empty lib/l10n/app_en.arb
jq empty lib/l10n/app_es.arb
jq empty lib/l10n/app_fr.arb
jq empty lib/l10n/app_de.arb
```

### 2. Vérifier les traductions manquantes

Comparer le nombre de clés :

```bash
# Count keys in English (template)
grep -c '"[a-zA-Z]' lib/l10n/app_en.arb

# Count keys in other languages
grep -c '"[a-zA-Z]' lib/l10n/app_es.arb
grep -c '"[a-zA-Z]' lib/l10n/app_fr.arb
grep -c '"[a-zA-Z]' lib/l10n/app_de.arb
```

Tous doivent correspondre !

### 3. Script pour trouver les clés manquantes

Créer `scripts/check_translations.sh` :

```bash
#!/bin/bash

TEMPLATE="lib/l10n/app_en.arb"
TRANSLATIONS=(lib/l10n/app_*.arb)

for TRANS in "${TRANSLATIONS[@]}"; do
  if [ "$TRANS" != "$TEMPLATE" ]; then
    echo "Checking $TRANS..."
    TEMPLATE_KEYS=$(jq -r 'keys[]' "$TEMPLATE" | grep -v "^@")
    TRANS_KEYS=$(jq -r 'keys[]' "$TRANS" | grep -v "^@")
    
    echo "$TEMPLATE_KEYS" | while read key; do
      if ! echo "$TRANS_KEYS" | grep -q "^$key$"; then
        echo "  Missing: $key"
      fi
    done
  fi
done
```

L'exécuter :

```bash
chmod +x scripts/check_translations.sh
./scripts/check_translations.sh
```

## Problèmes courants et solutions

### Problème : AppLocalizations not found

**Solution :** Exécuter `flutter gen-l10n` et redémarrer l'IDE

### Problème : La traduction n'apparaît pas

**Solution :**

1. Vérifier la syntaxe du fichier ARB
2. Vérifier que la clé correspond exactement (sensible à la casse)
3. Exécuter `flutter gen-l10n`
4. Effectuer un redémarrage à chaud de l'application (pas un rechargement à chaud)

### Problème : L'espace réservé ne fonctionne pas

**Solution :**

1. Vérifier la syntaxe de l'espace réservé : `{variableName}`
2. Vérifier que le fichier ARB a une section espaces réservés
3. S'assurer que le code passe le bon paramètre

### Problème : Débordement de texte

**Solution :**

1. Utiliser les widgets `Flexible` ou `Expanded`
2. Activer le retour à la ligne : `overflow: TextOverflow.ellipsis`
3. Envisager des abréviations dans la traduction

### Problème : Les caractères spéciaux s'affichent comme des cases

**Solution :**

1. S'assurer que la police prend en charge le jeu de caractères
2. Vérifier la configuration des polices dans `pubspec.yaml`
3. Vérifier que l'encodage du fichier est UTF-8

## Tests automatisés

### Tests de widgets

```dart
testWidgets('Welcome screen shows translated text', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WelcomeScreen(),
    ),
  );
  
  expect(find.text('Bienvenido'), findsOneWidget);
});
```

### Tests d'intégration

```dart
testWidgets('Language switches correctly', (tester) async {
  // Test language switching functionality
});
```

## Tests de performance

Vérifier que la localisation n'impacte pas les performances :

1. Exécuter l'application en mode profil : `flutter run --profile`
2. Vérifier que les fréquences d'images restent cohérentes
3. Surveiller l'utilisation de la mémoire
4. Tester sur des appareils bas de gamme

## Tests d'accessibilité

S'assurer que les traductions sont accessibles :

- [ ] Les lecteurs d'écran fonctionnent correctement
- [ ] La mise à l'échelle du texte fonctionne
- [ ] Le mode contraste élevé fonctionne
- [ ] Les étiquettes sémantiques sont localisées si nécessaire

## Documentation

Documenter les résultats des tests :

1. Créer un rapport de test pour chaque langue
2. Noter les problèmes trouvés
3. Documenter les solutions de contournement ou les corrections nécessaires
4. Mettre à jour ce guide avec les nouvelles découvertes

## Intégration continue

Ajouter au pipeline CI/CD :

```yaml
# .github/workflows/test.yml
- name: Validate ARB files
  run: |
    for file in lib/l10n/app_*.arb; do
      jq empty "$file" || exit 1
    done

- name: Generate localizations
  run: flutter gen-l10n

- name: Run tests
  run: flutter test
```

## Avant la publication

- [ ] Tous les fichiers ARB validés
- [ ] Toutes les traductions complètes
- [ ] Génération de code réussie
- [ ] Application testée dans toutes les langues prises en charge
- [ ] Captures d'écran prises pour chaque langue (pour les fiches des stores)
- [ ] Crédits de traduction mis à jour dans la section À propos
- [ ] Les notes de version mentionnent les nouvelles langues

## Collecte de retours

Après la publication :

- Surveiller les retours des utilisateurs sur la qualité des traductions
- Vérifier les analyses d'utilisation par langue
- Créer des issues pour les problèmes de traduction signalés
- Mettre à jour les traductions en fonction des retours

## Ressources

- [Documentation d'internationalisation Flutter](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [Format de fichier ARB](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Guide de traduction](TRANSLATION_GUIDE.md)
- [Guide du développeur](LOCALIZATION_DEV_GUIDE.md)

## Obtenir de l'aide

Si les tests échouent ou si vous rencontrez des problèmes :

1. Consulter ce guide
2. Consulter la documentation i18n de Flutter
3. Rechercher dans les issues GitHub existantes
4. Créer une nouvelle issue avec :
   - Message d'erreur
   - Étapes pour reproduire
   - Contenu du fichier ARB (si pertinent)
   - Informations sur l'appareil/émulateur

Bon test ! 🧪
