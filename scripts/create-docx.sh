#!/bin/bash

echo "🚀 Création de la documentation DOCX complète..."
echo ""

# Étape 1: Combinaison des fichiers Markdown
echo "📝 Étape 1: Combinaison des fichiers Markdown..."
./combine-markdowns.sh

# Étape 2: Conversion des diagrammes Mermaid
echo "🎨 Étape 2: Conversion des diagrammes Mermaid..."

# Vérifier si mermaid-cli est installé
if command -v mmdc &> /dev/null; then
    echo "✅ mermaid-cli détecté, conversion des diagrammes..."
    
    # Créer le dossier pour les images Mermaid
    mkdir -p ../mermaid-images
    
    # Utiliser Python pour traiter les blocs Mermaid
    python3 << 'EOF'
import re
import subprocess
import os

# Lire le fichier combiné
with open('../DropIt-Documentation-Complete.md', 'r', encoding='utf-8') as f:
    content = f.read()

# Trouver tous les blocs Mermaid
mermaid_blocks = re.findall(r'```mermaid\n(.*?)\n```', content, re.DOTALL)

print(f"📊 Trouvé {len(mermaid_blocks)} diagramme(s) Mermaid")

for i, mermaid_content in enumerate(mermaid_blocks, 1):
    # Créer un nom d'image unique
    image_name = f"mermaid-diagram-{i}"
    image_path = f"../mermaid-images/{image_name}.png"
    
    # Créer un fichier temporaire pour le contenu Mermaid
    temp_file = f"temp_mermaid_{i}.mmd"
    with open(temp_file, 'w', encoding='utf-8') as f:
        f.write(mermaid_content)
    
    # Vérifier si l'image existe déjà et si le contenu a changé
    if os.path.exists(image_path) and os.path.exists(f"{image_path}.md5"):
        current_hash = subprocess.run(['md5sum', temp_file], capture_output=True, text=True).stdout.split()[0]
        stored_hash = open(f"{image_path}.md5", 'r').read().strip()
        if current_hash == stored_hash:
            print(f"♻️  Image Mermaid existante, réutilisation: {image_name}.png")
            os.remove(temp_file)
            continue
    
    # Convertir avec mermaid-cli
    cmd = ['mmdc', '-i', temp_file, '-o', image_path, '-w', '1200', '-H', '800', '-b', 'white']
    
    try:
        subprocess.run(cmd, check=True)
        # Sauvegarder le hash du contenu
        subprocess.run(['md5sum', temp_file], stdout=open(f"{image_path}.md5", 'w'))
        print(f"✅ Converti: {image_name}.png")
        
        # Remplacer le bloc Mermaid par une référence d'image
        old_block = f'```mermaid\n{mermaid_content}\n```'
        new_reference = f'![Diagramme Mermaid {i}](mermaid-images/{image_name}.png)'
        content = content.replace(old_block, new_reference)
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Échec de conversion pour: {image_name} - {e}")
    
    # Nettoyer le fichier temporaire
    os.remove(temp_file)

# Sauvegarder le fichier modifié
with open('../DropIt-Documentation-Complete.md', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Conversion Mermaid terminée!")
EOF

else
    echo "⚠️  mermaid-cli non détecté, passage des diagrammes Mermaid..."
fi

# Étape 3: Conversion des blocs de code avec fond magenta
echo "💻 Étape 3: Conversion des blocs de code avec fond magenta..."

# Vérifier si silicon est installé
if command -v silicon &> /dev/null; then
    echo "✅ Silicon détecté, conversion des blocs de code..."
    
    # Créer le dossier pour les images de code
    mkdir -p ../code-images
    
    # Utiliser Python pour traiter les blocs de code
    python3 << 'EOF'
import re
import subprocess
import os

# Lire le fichier combiné
with open('../DropIt-Documentation-Complete.md', 'r', encoding='utf-8') as f:
    content = f.read()

# Trouver tous les blocs de code avec langage spécifié
code_blocks = re.findall(r'```(\w+)\n(.*?)\n```', content, re.DOTALL)

print(f"📊 Trouvé {len(code_blocks)} bloc(s) de code")

for i, (language, code_content) in enumerate(code_blocks, 1):
    # Créer un nom d'image unique
    image_name = f"code-block-{i}"
    image_path = f"../code-images/{image_name}.png"
    
    # Créer un fichier temporaire pour le contenu
    temp_file = f'temp_code_{i}.{language}'
    with open(temp_file, 'w', encoding='utf-8') as f:
        f.write(code_content)
    
    # Vérifier si l'image existe déjà et si le contenu a changé
    if os.path.exists(image_path) and os.path.exists(f"{image_path}.md5"):
        current_hash = subprocess.run(['md5sum', temp_file], capture_output=True, text=True).stdout.split()[0]
        stored_hash = open(f"{image_path}.md5", 'r').read().strip()
        if current_hash == stored_hash:
            print(f"♻️  Image de code existante, réutilisation: {image_name}.png ({language})")
            os.remove(temp_file)
            continue
    
    # Convertir avec silicon (fond blanc pour un meilleur rendu)
    cmd = ['silicon', temp_file, '-o', image_path, '--theme', 'OneHalfLight', '--font', 'JetBrains Mono', '--language', language, '--background', '#ffffff']
    
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
with open('../DropIt-Documentation-Complete.md', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Conversion code terminée!")
EOF

else
    echo "⚠️  Silicon non détecté, passage des blocs de code..."
fi

# Étape 4: Recadrage automatique des images avec ImageMagick
echo "🎨 Étape 4: Recadrage automatique des images avec ImageMagick..."

# Vérifier si ImageMagick est installé
if command -v magick &> /dev/null; then
    echo "✅ ImageMagick détecté, recadrage automatique des images..."
    
    # Traiter toutes les images de code
    for image_file in ../code-images/*.png; do
        if [ -f "$image_file" ]; then
            # Créer un fichier temporaire
            temp_file="${image_file}.tmp"
            
            # Recadrer automatiquement autour du contenu (supprime les bords vides)
            magick "$image_file" -trim +repage "$temp_file"
            
            # Remplacer l'original par la version recadrée
            mv "$temp_file" "$image_file"
            
            echo "✅ Image recadrée: $(basename "$image_file")"
        fi
    done
    
    echo "✅ Recadrage automatique terminé!"
    
    # Recadrage des images Whimsical spécifiques
    echo "🎨 Recadrage des images Whimsical..."
    
    # Liste des images Whimsical à recadrer
    whimsical_images=(
        "../src/assets/auth-better-auth.png"
        "../src/assets/better-auth-login.png"
        "../src/assets/better-auth-logout.png"
        "../src/assets/better-auth-ressource-prot.png"
        "../src/assets/global-architecture.png"
        "../src/assets/pipeline-auth.png"
    )
    
    for image_file in "${whimsical_images[@]}"; do
        if [ -f "$image_file" ]; then
            # Créer un fichier temporaire
            temp_file="${image_file}.tmp"
            
            # Recadrer automatiquement autour du contenu (supprime les bords vides)
            magick "$image_file" -trim +repage "$temp_file"
            
            # Supprimer la zone "Made with Whimsical" en bas (couper 60px en bas)
            magick "$temp_file" -gravity south -chop 0x60 "$image_file"
            
            # Nettoyer le fichier temporaire
            rm -f "$temp_file"
            
            echo "✅ Image Whimsical recadrée: $(basename "$image_file")"
        else
            echo "⚠️  Image non trouvée: $image_file"
        fi
    done
    
    echo "✅ Recadrage des images Whimsical terminé!"
else
    echo "⚠️  ImageMagick non détecté, installation recommandée:"
    echo "   sudo pacman -S imagemagick"
    echo "   Les images garderont leur taille originale."
fi

# Étape 5: Conversion en DOCX
echo "📄 Étape 5: Conversion en DOCX..."

cd .. && pandoc 'DropIt-Documentation-Complete.md' \
  --toc \
  --number-sections \
  --variable fontsize=11pt \
  --variable linestretch=1.2 \
  --variable margin-left=2cm \
  --variable margin-right=2cm \
  --variable margin-top=2cm \
  --variable margin-bottom=2cm \
  -o 'DropIt-Documentation.docx'

if [ $? -eq 0 ]; then
    echo "✅ DOCX créé avec succès: DropIt-Documentation.docx"
    
    # Afficher les statistiques
    file_size=$(du -h 'DropIt-Documentation.docx' | cut -f1)
    mermaid_count=$(find mermaid-images -name "*.png" 2>/dev/null | wc -l)
    code_count=$(find code-images -name "*.png" 2>/dev/null | wc -l)
    total_images=$((mermaid_count + code_count))
    
    echo "📄 Taille du fichier: $file_size"
    echo "📁 Images Mermaid: $mermaid_count dans mermaid-images/"
    echo "💻 Images de code: $code_count dans code-images/"
    echo ""
    echo "🎉 Documentation complète créée!"
    echo "📄 Fichier DOCX: DropIt-Documentation.docx"
    echo "📝 Fichier Markdown: DropIt-Documentation-Complete.md"
    echo "🖼️  Total d'images intégrées: $total_images"
else
    echo "❌ Erreur lors de la conversion DOCX"
    exit 1
fi
