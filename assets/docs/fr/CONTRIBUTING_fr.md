# Contribuer à Aquarium AI

Merci de votre intérêt pour contribuer à Aquarium AI ! Ce document fournit des lignes directrices pour contribuer au projet.

## Façons de Contribuer

### 🌍 Traductions (Aucune programmation requise !)

L'une des façons les plus faciles et les plus impactantes de contribuer est de traduire l'application dans votre langue. Consultez notre [Guide de Traduction](TRANSLATION_GUIDE.md) pour des instructions détaillées.

**Démarrage rapide pour les traductions :**

1. Consultez la [Référence Rapide de Traduction](TRANSLATION_QUICK_REF.md)
2. Copiez le [fichier modèle](lib/l10n_template.arb)
3. Traduisez les chaînes dans votre langue
4. Soumettez une pull request ou ouvrez une issue avec votre traduction

### 🐛 Rapports de Bogues

Vous avez trouvé un bogue ? Aidez-nous à le corriger :

1. Vérifiez si le bogue a déjà été signalé dans les [Issues](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
2. Si ce n'est pas le cas, créez une nouvelle issue avec :
   - Description claire du bogue
   - Étapes pour reproduire
   - Comportement attendu vs. comportement réel
   - Captures d'écran si applicable
   - Informations sur le dispositif/la plateforme

### 💡 Demandes de Fonctionnalités

Vous avez une idée pour une nouvelle fonctionnalité ?

1. Consultez les [demandes de fonctionnalités existantes](https://github.com/TheRealFalseReality/Aquarium-AI/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. Si c'est nouveau, créez une issue décrivant :
   - Le problème que votre fonctionnalité résoudrait
   - Comment vous envisagez le fonctionnement de la fonctionnalité
   - Des exemples provenant d'autres applications

### 💻 Contributions de Code

Vous souhaitez contribuer du code ? Excellent !

**Avant de commencer :**

1. Consultez les [issues ouvertes](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
2. Commentez l'issue sur laquelle vous souhaitez travailler
3. Attendez l'approbation pour éviter les doublons

**Configuration de l'environnement de développement :**

1. Forkez le dépôt
2. Clonez votre fork : `git clone https://github.com/YOUR_USERNAME/Aquarium-AI.git`
3. Créez une branche : `git checkout -b feature/your-feature-name`
4. Apportez vos modifications
5. Testez vos modifications de manière approfondie
6. Committez avec des messages clairs : `git commit -m "Add feature: description"`
7. Poussez vers votre fork : `git push origin feature/your-feature-name`
8. Créez une Pull Request

**Directives de code :**

- Respectez le style de code existant
- Rédigez des messages de commit clairs et descriptifs
- Ajoutez des commentaires pour la logique complexe
- Mettez à jour la documentation si nécessaire
- Testez vos modifications sur plusieurs plateformes si possible

### 📖 Documentation

Aidez à améliorer notre documentation :

- Corriger les fautes de frappe ou les instructions peu claires
- Ajouter des exemples
- Traduire la documentation
- Rédiger des tutoriels ou des guides

## Processus de Pull Request

1. **Mettre à jour la documentation** : Si votre changement affecte les fonctionnalités visibles par l'utilisateur, mettez à jour les documents pertinents
2. **Respecter les conventions** : Respectez le style et la structure de code existants
3. **Tester minutieusement** : Assurez-vous que vos modifications fonctionnent comme prévu
4. **PRs petites** : Gardez les pull requests focalisées sur une seule fonctionnalité/correction
5. **Décrire vos changements** : Rédigez une description claire de quoi et pourquoi

## Directives Spécifiques aux Traductions

### Structure des Fichiers

```text
├── app_en.arb    (English - template, always complete)
├── app_es.arb    (Spanish)
├── app_fr.arb    (French)
├── app_de.arb    (German)
└── app_XX.arb    (Your language)
```

### Ajouter une Nouvelle Langue

1. Créez `lib/l10n/app_XX.arb` (XX = code de langue)
2. Traduisez toutes les chaînes de `app_en.arb`
3. Mettez à jour `lib/main.dart` :

   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('XX'), // Add your language here
   ],
   ```

4. Testez en changeant la langue de votre appareil
5. Soumettez un PR

### Mettre à Jour les Traductions Existantes

1. Consultez `app_en.arb` pour les nouvelles chaînes
2. Ajoutez les traductions manquantes à votre fichier de langue
3. Soumettez un PR avec les mises à jour

## Directives de la Communauté

- **Soyez respectueux** : Traitez tout le monde avec respect et gentillesse
- **Soyez patient** : Rappelez-vous que tout le monde apprend
- **Soyez serviable** : Aidez les autres quand vous le pouvez
- **Restez sur le sujet** : Gardez les discussions centrées sur Aquarium AI

## Questions ?

- **Questions générales** : Ouvrez une [Discussion](https://github.com/TheRealFalseReality/Aquarium-AI/discussions)
- **Rapports de bogues** : Ouvrez une [Issue](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
- **Aide à la traduction** : Consultez le [Guide de Traduction](TRANSLATION_GUIDE.md)

## Reconnaissance

Tous les contributeurs sont reconnus dans :

- La section À propos de l'application
- Page des contributeurs GitHub
- Notes de version (pour les contributions significatives)

## Licence

En contribuant, vous acceptez que vos contributions seront licenciées sous la même licence que le projet (Licence MIT).

## Première Contribution ?

Bienvenue ! Voici quelques bonnes premières issues :

- Traduire dans une nouvelle langue
- Corriger des fautes de frappe dans la documentation
- Ajouter des exemples aux guides
- Issues étiquetées « good first issue »

Merci de rendre Aquarium AI meilleur pour tout le monde ! 🐠
