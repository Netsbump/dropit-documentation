# Scripts de génération de documentation DropIt

Ce dossier contient tous les scripts nécessaires pour générer la documentation DropIt au format DOCX avec images intégrées.

## 📋 Scripts disponibles

### 1. `combine-markdowns.sh`
**Rôle** : Combine tous les fichiers Markdown de la documentation en un seul fichier Markdown.

**Fonctionnalités** :
- Assemble tous les fichiers `.md` selon l'ordre du sidebar
- Corrige automatiquement les chemins d'images :
  - `../../../assets/` → `src/assets/` (format Markdown)
  - `src="/src/assets/` → `src="src/assets/` (format HTML)
- Supprime les frontmatters et titres redondants
- Ajoute des sauts de page entre les sections

**Utilisation** :
```bash
./scripts/combine-markdowns.sh
```

**Sortie** : `DropIt-Documentation-Complete.md`

---

### 2. `create-docx.sh`
**Rôle** : Génère un DOCX avec images Mermaid et blocs de code recadrés automatiquement.

**Fonctionnalités** :
- Combine les fichiers Markdown
- Convertit les diagrammes Mermaid en images PNG
- Convertit les blocs de code en images avec syntaxe colorée
- **Recadre automatiquement** les images de code avec ImageMagick
- Optimise en évitant la régénération des images existantes (cache MD5)
- Génère le DOCX final avec Pandoc

**Utilisation** :
```bash
./scripts/create-docx.sh
```

**Sortie** : `DropIt-Documentation.docx`

**Dépendances** :
- `mermaid-cli` (npm install -g @mermaid-js/mermaid-cli)
- `silicon` (cargo install silicon)
- `imagemagick` (sudo pacman -S imagemagick)
- `pandoc`

---

## 🚀 Procédure recommandée

### Pour générer la documentation complète :

**Script principal** (une seule commande) :
```bash
./scripts/create-docx.sh
```

Ce script fait tout automatiquement :
- ✅ Combine tous les fichiers Markdown
- ✅ Convertit les diagrammes Mermaid en images
- ✅ Convertit les blocs de code en images avec syntaxe colorée
- ✅ Recadre automatiquement les images pour optimiser l'espace
- ✅ Génère le DOCX final avec toutes les images intégrées

### Alternative étape par étape :

Si vous voulez séparer les étapes :

1. **Combiner les fichiers** :
```bash
./scripts/combine-markdowns.sh
```

2. **Générer le DOCX** :
```bash
./scripts/create-docx.sh
```

---

## 📁 Structure des fichiers générés

```
dropit-documentation/
├── DropIt-Documentation-Complete.md          # Fichier Markdown combiné
├── DropIt-Documentation.docx                 # DOCX final
├── mermaid-images/                           # Images des diagrammes Mermaid
│   ├── mermaid-diagram-1.png
│   ├── mermaid-diagram-2.png
│   └── ...
├── code-images/                              # Images des blocs de code
│   ├── code-block-1.png
│   ├── code-block-2.png
│   └── ...
└── scripts/                                  # Scripts de génération
    ├── README.md
    ├── combine-markdowns.sh
    └── create-docx.sh
```

---

## 🔧 Installation des dépendances

### Sur Manjaro/Arch Linux :

```bash
# ImageMagick pour le recadrage
sudo pacman -S imagemagick

# Pandoc pour la conversion DOCX
sudo pacman -S pandoc

# Mermaid CLI pour les diagrammes
npm install -g @mermaid-js/mermaid-cli

# Silicon pour les images de code
cargo install silicon
```

### Vérification des dépendances :

```bash
# Vérifier que tous les outils sont installés
which mmdc && echo "✅ Mermaid CLI" || echo "❌ Mermaid CLI manquant"
which silicon && echo "✅ Silicon" || echo "❌ Silicon manquant"
which convert && echo "✅ ImageMagick" || echo "❌ ImageMagick manquant"
which pandoc && echo "✅ Pandoc" || echo "❌ Pandoc manquant"
```

---

## ⚙️ Configuration et personnalisation

### Thème des blocs de code
Le script utilise le thème `OneHalfLight` pour les images de code. Pour changer :

1. Modifier dans `create-docx-transparent.sh` :
```bash
--theme 'OneHalfLight'  # Changer le thème ici
```

### Police des blocs de code
La police par défaut est `JetBrains Mono`. Pour changer :

1. Modifier dans `create-docx-transparent.sh` :
```bash
--font 'JetBrains Mono'  # Changer la police ici
```

### Paramètres Pandoc
Les paramètres de conversion DOCX peuvent être modifiés dans le script :

```bash
pandoc 'DropIt-Documentation-Complete.md' \
  --toc \                    # Table des matières
  --number-sections \        # Numérotation des sections
  --variable fontsize=11pt \ # Taille de police
  --variable linestretch=1.2 \ # Espacement des lignes
  --variable margin-left=2cm \  # Marges
  --variable margin-right=2cm \
  --variable margin-top=2cm \
  --variable margin-bottom=2cm \
  -o 'DropIt-Documentation-Transparent.docx'
```

---

## 🐛 Dépannage

### Erreur "mermaid-cli not found"
```bash
npm install -g @mermaid-js/mermaid-cli
```

### Erreur "silicon not found"
```bash
cargo install silicon
```

### Erreur "ImageMagick not found"
```bash
sudo pacman -S imagemagick
```

### Erreur "Pandoc not found"
```bash
sudo pacman -S pandoc
```

### Images de code avec fond violet
- Le script `create-docx.sh` recadre automatiquement les images
- Plus besoin de gérer les fonds colorés manuellement

### Images non trouvées dans le DOCX
- Vérifiez que les chemins d'images sont corrects dans les fichiers Markdown
- Le script `combine-markdowns.sh` corrige automatiquement les chemins relatifs

---

## 📊 Statistiques de génération

Le script affiche des statistiques à la fin :

```
🎉 Documentation complète créée!
📄 Fichier DOCX: DropIt-Documentation-Transparent.docx
📝 Fichier Markdown: DropIt-Documentation-Complete.md
🖼️  Total d'images intégrées: 90
```

---

## 🔄 Optimisation et cache

Les scripts utilisent un système de cache MD5 pour éviter la régénération des images existantes :

- Chaque image générée a un fichier `.md5` associé
- Si le contenu n'a pas changé, l'image existante est réutilisée
- Cela accélère considérablement les générations suivantes

Pour forcer la régénération de toutes les images :
```bash
rm -rf mermaid-images/ code-images/
./scripts/create-docx.sh
```
