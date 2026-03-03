# Référence rapide de traduction

Voici une référence rapide pour les scénarios de traduction courants dans Aquarium AI.

## Convention de nommage des fichiers

| Langue | Nom de fichier | Code de paramètres régionaux |
| ------ | -------------- | ---------------------------- |
| Anglais | app_en.arb | en |
| Espagnol | app_es.arb | es |
| Français | app_fr.arb | fr |
| Allemand | app_de.arb | de |
| Japonais | app_ja.arb | ja |
| Chinois (simplifié) | app_zh.arb | zh |
| Portugais | app_pt.arb | pt |
| Italien | app_it.arb | it |
| Russe | app_ru.arb | ru |
| Coréen | app_ko.arb | ko |
| Arabe | app_ar.arb | ar |
| Hindi | app_hi.arb | hi |
| Néerlandais | app_nl.arb | nl |

## Exemples de traduction

### Texte simple

```json
"welcomeTitle": "Welcome"
```

**Allemand** : `"welcomeTitle": "Willkommen"`
**Japonais** : `"welcomeTitle": "ようこそ"`
**Espagnol** : `"welcomeTitle": "Bienvenido"`

### Texte avec espaces réservés

```json
"totalTanks": "Total: {count}"
```

**Allemand** : `"totalTanks": "Gesamt: {count}"`
**Japonais** : `"totalTanks": "合計: {count}"`
**Espagnol** : `"totalTanks": "Total: {count}"`

**Remarque** : Conservez `{count}` tel quel – c'est un espace réservé !

### Caractères spéciaux

```json
"aquariumCalculatorsDescription": "Essential tools for salinity, CO₂, alkalinity and more."
```

Conservez les caractères spéciaux comme `CO₂`, car ce sont des termes techniques.

### Termes techniques

Certains termes doivent rester en anglais ou utiliser des traductions communément acceptées :

- API Key (souvent conservé tel quel)
- AI (Artificial Intelligence)
- Noms de modèles : Gemini, OpenAI, Groq

### Éléments d'interface utilisateur

```json
"save": "Save",
"cancel": "Cancel",
"delete": "Delete"
```

Ces termes doivent être traduits pour correspondre à la langue native de l'interface de la plateforme.

## Tester votre traduction

### 1. Validation JSON

Utilisez <https://jsonlint.com/> pour valider votre syntaxe JSON.

### 2. Vérification de la complétude

Comparez votre fichier ARB avec `app_en.arb` :

```bash
# Count keys in English file
grep -c '"[a-zA-Z]' lib/l10n/app_en.arb

# Count keys in your translation
grep -c '"[a-zA-Z]' lib/l10n/app_XX.arb
```

Les deux doivent avoir le même nombre !

### 3. Vérification des espaces réservés

Recherchez tous les espaces réservés dans votre fichier :

```bash
grep '{' lib/l10n/app_XX.arb
```

Assurez-vous que tous les `{count}`, `{name}`, etc. sont présents et inchangés.

## Erreurs courantes à éviter

❌ **Incorrect** : Traduire les clés

```json
"bienvenue": "Bienvenue"  // DON'T translate the key!
```

✅ **Correct** : Traduire uniquement les valeurs

```json
"welcomeTitle": "Bienvenue"  // Only the value is translated
```

❌ **Incorrect** : Supprimer les espaces réservés

```json
"totalTanks": "Total: 5"  // Lost the {count} placeholder!
```

✅ **Correct** : Conserver les espaces réservés

```json
"totalTanks": "Total: {count}"
```

❌ **Incorrect** : JSON invalide

```json
{
  "save": "Save"  // Missing comma
  "cancel": "Cancel"
}
```

✅ **Correct** : JSON valide

```json
{
  "save": "Save",
  "cancel": "Cancel"
}
```

## Besoin d'aide ?

1. Consultez le [Guide de traduction](TRANSLATION_GUIDE.md) complet
2. Regardez les traductions existantes : [Espagnol](lib/l10n/app_es.arb) ou [Français](lib/l10n/app_fr.arb)
3. Utilisez le [fichier modèle](lib/l10n_template.arb)
4. Ouvrez une issue sur GitHub si vous êtes bloqué

## Étapes de démarrage rapide

1. Copiez `lib/l10n_template.arb` vers `lib/l10n/app_XX.arb`
2. Modifiez `@@locale` avec le code de votre langue
3. Remplacez tous les textes "TRANSLATE: " par vos traductions
4. Validez le JSON sur <https://jsonlint.com/>
5. Mettez à jour `lib/main.dart` pour ajouter vos paramètres régionaux à `supportedLocales`
6. Soumettez une Pull Request !

Merci de votre contribution ! 🌍
