#!/bin/bash

# Script pour combiner la documentation DropIt dans l'ordre du sidebar
# Basé sur astro.config.mjs sidebar structure

DOCS_DIR="../src/content/docs"
OUTPUT_FILE="../DropIt-Documentation-Complete.md"

# Fonction pour convertir les balises <img> en Markdown
convert_img_to_markdown() {
    # Convertir <img src="..." alt="..." width="..." /> en ![alt](src)
    sed -E 's|<img[^>]*src="([^"]*)"[^>]*alt="([^"]*)"[^>]*/?>|![\2](\1)|g'
}

echo "🚀 Création du document combiné DropIt Documentation..."

# Supprimer le fichier existant s'il existe
rm -f "$OUTPUT_FILE"

# Page d'accueil
echo "# DropIt Documentation Complète" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Introduction
echo "# Introduction" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [ -f "$DOCS_DIR/introduction/presentation.md" ]; then
    echo "## Présentation du projet" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    # Supprimer le titre frontmatter et le premier titre
    tail -n +4 "$DOCS_DIR/introduction/presentation.md" | sed '/^# /d' | sed 's|../../../assets/|src/assets/|g' | sed 's|src="/src/assets/|src="src/assets/|g' | convert_img_to_markdown >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "\\newpage" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

if [ -f "$DOCS_DIR/introduction/contexte.md" ]; then
    echo "## Contexte et enjeux" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    tail -n +4 "$DOCS_DIR/introduction/contexte.md" | sed '/^# /d' | sed 's|../../../assets/|src/assets/|g' | sed 's|src="/src/assets/|src="src/assets/|g' | convert_img_to_markdown >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "\\newpage" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# Conception et développement
echo "# Conception et développement" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

declare -a conception_files=(
    "analyse:Analyse des besoins"
    "architecture:Architecture logicielle" 
    "base-donnees:Base de données"
    "acces-donnees:Accès aux données"
    "presentations:Présentations"
    "interfaces:Interfaces"
)

for item in "${conception_files[@]}"; do
    IFS=':' read -r filename title <<< "$item"
    if [ -f "$DOCS_DIR/conception/$filename.md" ]; then
        echo "## $title" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        tail -n +4 "$DOCS_DIR/conception/$filename.md" | sed '/^# /d' | sed 's|../../../assets/|src/assets/|g' | sed 's|src="/src/assets/|src="src/assets/|g' | convert_img_to_markdown >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "\\newpage" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Sécurité
echo "# Sécurité" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

declare -a securite_files=(
    "conception:Conception sécurisée"
    "authentification:Authentification"
    "permissions:Gestion des rôles"
)

for item in "${securite_files[@]}"; do
    IFS=':' read -r filename title <<< "$item"
    if [ -f "$DOCS_DIR/securite/$filename.md" ]; then
        echo "## $title" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        tail -n +4 "$DOCS_DIR/securite/$filename.md" | sed '/^# /d' | sed 's|../../../assets/|src/assets/|g' | sed 's|src="/src/assets/|src="src/assets/|g' | convert_img_to_markdown >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "\\newpage" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Tests et validation
echo "# Tests et validation" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

declare -a tests_files=(
    "plans:Plans de tests"
    "validation:Validation des composants"
)

for item in "${tests_files[@]}"; do
    IFS=':' read -r filename title <<< "$item"
    if [ -f "$DOCS_DIR/tests/$filename.md" ]; then
        echo "## $title" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        tail -n +4 "$DOCS_DIR/tests/$filename.md" | sed '/^# /d' | sed 's|../../../assets/|src/assets/|g' | sed 's|src="/src/assets/|src="src/assets/|g' | convert_img_to_markdown >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "\\newpage" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Déploiement et production
echo "# Déploiement et production" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

declare -a deploiement_files=(
    "preparation:Préparation au déploiement"
    "production:Mise en production"
)

for item in "${deploiement_files[@]}"; do
    IFS=':' read -r filename title <<< "$item"
    if [ -f "$DOCS_DIR/deploiement/$filename.md" ]; then
        echo "## $title" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        tail -n +4 "$DOCS_DIR/deploiement/$filename.md" | sed '/^# /d' | sed 's|../../../assets/|src/assets/|g' | sed 's|src="/src/assets/|src="src/assets/|g' | convert_img_to_markdown >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "\\newpage" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Gestion de projet
echo "# Gestion de projet" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

declare -a gestion_files=(
    "contribution:Contribution au projet"
    "documentations:Documentations"
)

for item in "${gestion_files[@]}"; do
    IFS=':' read -r filename title <<< "$item"
    if [ -f "$DOCS_DIR/gestion/$filename.md" ]; then
        echo "## $title" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        tail -n +4 "$DOCS_DIR/gestion/$filename.md" | sed '/^# /d' | sed 's|../../../assets/|src/assets/|g' | sed 's|src="/src/assets/|src="src/assets/|g' | convert_img_to_markdown >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "\\newpage" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Annexes (placées à la fin comme demandé)
echo "# Annexes" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

declare -a annexes_files=(
    "bilan:Bilan"
    "analyse-besoins:Analyse des besoins"
    "architecture-technique:Architecture technique"
    "conception-base-donnees:Conception technique de la base de données"
    "implementation-acces-donnees:Implémentation accès aux données"
    "implementation-presentations:Implémentation présentations"
    "authentifications:Authentifications"
    "permissions:Permissions"
    "glossaire:Glossaire"
)

for item in "${annexes_files[@]}"; do
    IFS=':' read -r filename title <<< "$item"
    if [ -f "$DOCS_DIR/annexes/$filename.md" ]; then
        echo "## $title" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        tail -n +4 "$DOCS_DIR/annexes/$filename.md" | sed '/^# /d' | sed 's|../../../assets/|src/assets/|g' | sed 's|src="/src/assets/|src="src/assets/|g' | convert_img_to_markdown >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "\\newpage" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

echo "✅ Document combiné créé: $OUTPUT_FILE"
echo "📄 Nombre de lignes: $(wc -l < "$OUTPUT_FILE")"
echo ""
echo "📄 Pour créer un DOCX complet avec images Mermaid, code et images intégrées:"
echo "./create-docx-transparent.sh"
echo ""