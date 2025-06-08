# Cursor Rules

Ce dossier contient les règles Cursor pour le projet Dropit Documentation. Ces règles sont utilisées par l'IA de Cursor pour comprendre les conventions et les bonnes pratiques du projet.

## Règles disponibles

- **global.mdc**: Règles pour la rédaction de la documentation (Ton, Syntaxe, Style, etc.)

## Comment utiliser les règles

Les règles sont automatiquement attachées aux conversations lorsque vous ouvrez un fichier qui correspond au glob pattern défini dans la règle. Vous pouvez également les référencer explicitement dans vos conversations avec l'IA.

### Exemple d'utilisation

```
Cursor, j'ai besoin d'aide pour créer une nouvelle page de documentation pour l'explication de la sécurité dans mon app. Peux-tu me guider en suivant les règles de notre global?
```

## Comment ajouter ou modifier des règles

1. Créez un nouveau fichier `.mdc` dans ce dossier
2. Ajoutez un titre à la première ligne
3. Ajoutez le contenu de la règle
4. Vous pouvez référencer des fichiers de documentation avec la syntaxe `[nom](mdc:chemin/vers/fichier.md)`

## Structure d'une règle

```
Titre de la règle
# Contenu de la règle

- Point 1
- Point 2
- Référence à la documentation: [nom](mdc:chemin/vers/fichier.md)
```
