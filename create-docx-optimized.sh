#!/bin/bash

# Script optimisé pour créer la documentation DOCX avec images Mermaid ET code
# 1. Combine tous les fichiers Markdown
# 2. Convertit les diagrammes Mermaid en images PNG (si pas déjà fait)
# 3. Convertit les blocs de code en images avec syntaxe colorée (si pas déjà fait)
# 4. Convertit en DOCX avec toutes les images intégrées

DOCS_DIR="src/content/docs"
OUTPUT_FILE="DropIt-Documentation-Complete.md"
DOCX_FILE="DropIt-Documentation.docx"
MERMAID_DIR="mermaid-images"
CODE_DIR="code-images"

echo "🚀 Création de la documentation DOCX complète avec images Mermaid ET code..."

# Étape 1: Créer le fichier Markdown combiné
echo "📝 Étape 1: Combinaison des fichiers Markdown..."
./combine-docs.sh

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "❌ Erreur: Impossible de créer le fichier Markdown combiné"
    exit 1
fi

# Créer les dossiers pour les images
mkdir -p "$MERMAID_DIR"
mkdir -p "$CODE_DIR"

# Étape 2: Convertir les diagrammes Mermaid en images (optimisé)
echo "🎨 Étape 2: Conversion des diagrammes Mermaid..."

if command -v mmdc &> /dev/null; then
    echo "✅ mermaid-cli détecté, conversion des diagrammes..."
    
    # Utiliser Python pour traiter les diagrammes Mermaid
    python3 << 'EOF'
import re
import os
import subprocess
import hashlib

# Lire le fichier Markdown
with open('DropIt-Documentation-Complete.md', 'r', encoding='utf-8') as f:
    content = f.read()

# Trouver tous les blocs Mermaid
mermaid_pattern = r'```mermaid\n(.*?)\n```'
matches = re.findall(mermaid_pattern, content, re.DOTALL)

print(f"📊 Trouvé {len(matches)} diagramme(s) Mermaid")

# Créer le dossier pour les images
os.makedirs('mermaid-images', exist_ok=True)

# Convertir chaque diagramme
for i, mermaid_content in enumerate(matches, 1):
    # Créer un hash du contenu pour vérifier si l'image existe déjà
    content_hash = hashlib.md5(mermaid_content.encode()).hexdigest()
    image_name = f'mermaid-diagram-{i}'
    image_path = f'mermaid-images/{image_name}.png'
    
    # Vérifier si l'image existe déjà
    if os.path.exists(image_path):
        print(f"⏭️  Image existe déjà: {image_name}.png")
        # Remplacer le bloc mermaid par une référence d'image
        old_block = f'```mermaid\n{mermaid_content}\n```'
        new_reference = f'![Diagramme Mermaid {i}](mermaid-images/{image_name}.png)'
        content = content.replace(old_block, new_reference)
        continue
    
    # Sauvegarder le contenu dans un fichier temporaire
    temp_file = f'temp_mermaid_{i}.mmd'
    with open(temp_file, 'w', encoding='utf-8') as f:
        f.write(mermaid_content)
    
    # Convertir avec mmdc
    cmd = ['mmdc', '-i', temp_file, '-o', image_path, '-w', '1200', '-H', '800', '-b', 'white']
    
    try:
        subprocess.run(cmd, check=True)
        print(f"✅ Converti: {image_name}.png")
        
        # Remplacer le bloc mermaid par une référence d'image
        old_block = f'```mermaid\n{mermaid_content}\n```'
        new_reference = f'![Diagramme Mermaid {i}](mermaid-images/{image_name}.png)'
        content = content.replace(old_block, new_reference)
        
    except subprocess.CalledProcessError:
        print(f"❌ Échec de conversion pour: {image_name}")
    
    # Nettoyer le fichier temporaire
    os.remove(temp_file)

# Sauvegarder le fichier modifié
with open('DropIt-Documentation-Complete.md', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Conversion Mermaid terminée!")
EOF
    
else
    echo "⚠️  mermaid-cli non installé. Les diagrammes Mermaid resteront en code brut."
    echo "💡 Pour installer: npm install -g @mermaid-js/mermaid-cli"
fi

# Étape 3: Convertir les blocs de code en images (optimisé)
echo "💻 Étape 3: Conversion des blocs de code..."

if command -v silicon &> /dev/null; then
    echo "✅ Silicon détecté, conversion des blocs de code..."
    
    # Utiliser Python pour traiter les blocs de code
    python3 << 'EOF'
import re
import os
import subprocess
import hashlib

# Lire le fichier Markdown
with open('DropIt-Documentation-Complete.md', 'r', encoding='utf-8') as f:
    content = f.read()

# Trouver tous les blocs de code (sauf mermaid)
code_pattern = r'```(\w+)\n(.*?)\n```'
matches = re.findall(code_pattern, content, re.DOTALL)

print(f"📊 Trouvé {len(matches)} bloc(s) de code")

# Créer le dossier pour les images
os.makedirs('code-images', exist_ok=True)

# Convertir chaque bloc de code
for i, (language, code_content) in enumerate(matches, 1):
    # Créer un hash du contenu pour vérifier si l'image existe déjà
    content_hash = hashlib.md5(f"{language}:{code_content}".encode()).hexdigest()
    image_name = f'code-block-{i}'
    image_path = f'code-images/{image_name}.png'
    
    # Vérifier si l'image existe déjà
    if os.path.exists(image_path):
        print(f"⏭️  Image existe déjà: {image_name}.png ({language})")
        # Remplacer le bloc de code par une référence d'image
        old_block = f'```{language}\n{code_content}\n```'
        new_reference = f'![Code {language} - Bloc {i}](code-images/{image_name}.png)'
        content = content.replace(old_block, new_reference)
        continue
    
    # Sauvegarder le contenu dans un fichier temporaire
    temp_file = f'temp_code_{i}.{language}'
    with open(temp_file, 'w', encoding='utf-8') as f:
        f.write(code_content)
    
    # Convertir avec silicon (utiliser un thème clair et spécifier le langage)
    cmd = ['silicon', temp_file, '-o', image_path, '--theme', 'OneHalfLight', '--font', 'JetBrains Mono', '--language', language]
    
    try:
        # Nettoyer le contenu des emojis pour éviter les erreurs de police
        clean_content = code_content
        # Remplacer les emojis courants par du texte
        emoji_replacements = {
            '🌐': '[Web]', '📋': '[Liste]', '💎': '[Premium]', '🔧': '[Config]',
            '❌': '[Erreur]', '✅': '[OK]', '⚠️': '[Attention]', '🚀': '[Démarrage]'
        }
        for emoji, replacement in emoji_replacements.items():
            clean_content = clean_content.replace(emoji, replacement)
        
        # Réécrire le fichier temporaire avec le contenu nettoyé
        with open(temp_file, 'w', encoding='utf-8') as f:
            f.write(clean_content)
        
        subprocess.run(cmd, check=True)
        print(f"✅ Converti: {image_name}.png ({language})")
        
        # Remplacer le bloc de code par une référence d'image
        old_block = f'```{language}\n{code_content}\n```'
        new_reference = f'![Code {language} - Bloc {i}](code-images/{image_name}.png)'
        content = content.replace(old_block, new_reference)
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Échec de conversion pour: {image_name} - {e}")
        # En cas d'échec, garder le bloc de code original
        continue
    
    # Nettoyer le fichier temporaire
    if os.path.exists(temp_file):
        os.remove(temp_file)

# Sauvegarder le fichier modifié
with open('DropIt-Documentation-Complete.md', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Conversion code terminée!")
EOF
    
else
    echo "⚠️  Silicon non installé. Les blocs de code resteront en code brut."
    echo "💡 Pour installer: sudo pacman -S silicon"
    echo "🔄 Continuation sans conversion des blocs de code..."
fi

# Étape 4: Convertir en DOCX
echo "📄 Étape 4: Conversion en DOCX..."

pandoc "$OUTPUT_FILE" \
    --toc \
    --number-sections \
    --variable fontsize=11pt \
    --variable linestretch=1.2 \
    --variable margin-left=2cm \
    --variable margin-right=2cm \
    --variable margin-top=2cm \
    --variable margin-bottom=2cm \
    -o "$DOCX_FILE"

if [ $? -eq 0 ]; then
    echo "✅ DOCX créé avec succès: $DOCX_FILE"
    echo "📄 Taille du fichier: $(du -h "$DOCX_FILE" | cut -f1)"
    
    # Compter les images créées
    mermaid_count=0
    code_count=0
    
    if [ -d "$MERMAID_DIR" ] && [ "$(ls -A "$MERMAID_DIR" 2>/dev/null)" ]; then
        mermaid_count=$(ls -1 "$MERMAID_DIR"/*.png 2>/dev/null | wc -l)
        echo "📁 Images Mermaid: $mermaid_count dans $MERMAID_DIR/"
    fi
    
    if [ -d "$CODE_DIR" ] && [ "$(ls -A "$CODE_DIR" 2>/dev/null)" ]; then
        code_count=$(ls -1 "$CODE_DIR"/*.png 2>/dev/null | wc -l)
        echo "💻 Images de code: $code_count dans $CODE_DIR/"
    fi
    
    echo ""
    echo "🎉 Documentation complète créée!"
    echo "📄 Fichier DOCX: $DOCX_FILE"
    echo "📝 Fichier Markdown: $OUTPUT_FILE"
    echo "🖼️  Total d'images intégrées: $((mermaid_count + code_count))"
    
else
    echo "❌ Erreur lors de la conversion DOCX"
    exit 1
fi
