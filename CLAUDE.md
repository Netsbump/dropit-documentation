# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **DropIt Documentation** project - an Astro-powered documentation site built with Starlight for a weightlifting club management application. The project documents the complete development process of the DropIt application, from needs analysis to production deployment, serving as a professional portfolio for a "Concepteur Développeur d'Applications" certification.

## Technology Stack

- **Framework**: Astro 5.1.5 with Starlight integration
- **Package Manager**: pnpm (uses pnpm-lock.yaml)
- **Node Version**: >=18.20.8 (required for deployment)
- **Special Features**: 
  - Mermaid diagram support via @beoe/rehype-mermaid
  - Dark/light mode theme switching for diagrams
  - Playwright for screenshot generation

## Development Commands

| Command | Purpose |
|---------|---------|
| `pnpm install` | Install dependencies |
| `pnpm dev` | Start development server at localhost:4321 |
| `pnpm build` | Build production site to ./dist/ |
| `pnpm preview` | Preview production build locally |
| `pnpm astro ...` | Run Astro CLI commands |

## Content Architecture

The documentation follows a structured approach with content organized in `src/content/docs/`:

### Content Structure
- **Introduction**: Project presentation and context (`introduction/`)
- **Environment**: Installation and tools (`environnement/`)
- **Conception**: Architecture, database, interfaces (`conception/`)
- **Security**: Authentication, OWASP, permissions (`securite/`)
- **Testing**: Test plans and validation (`tests/`)
- **Deployment**: Production setup and performance (`deploiement/`)
- **Project Management**: Contributions, documentation (`gestion/`)
- **References**: Glossary, roadmap, references (`annexes/`)

### Key Files
- `src/content/docs/index.mdx`: Homepage with hero section and feature cards
- `astro.config.mjs`: Main configuration with Starlight sidebar structure
- `src/content.config.ts`: Content collection schema
- `src/styles/mermaid.css`: Dark/light mode styles for Mermaid diagrams

## Mermaid Diagrams

The project uses @beoe/rehype-mermaid for diagram rendering:
- Diagrams are rendered as SVG files in `public/beoe/`
- Dark/light mode variants supported
- CSS in `src/styles/mermaid.css` handles theme switching
- Configuration in astro.config.mjs under markdown.rehypePlugins

## Content Guidelines

- Documentation is written in French
- Uses MDX format for interactive components
- Starlight components available: Card, CardGrid
- Images stored in `src/assets/`
- Static assets in `public/`

## Writing Style Guidelines

### Tone and Style
- **ALWAYS** adopt a professional and personal writing tone
- **STAY HUMBLE**: Student learning posture, not confirmed expert
- **AVOID** AI-style bullet point lists (generic bullet points)
- **USE** first person to show personal involvement ("I chose", "my approach", "in my context")
- **STRUCTURE** in narrative paragraphs that tell the development journey
- **JUSTIFY** every technical choice with thoughtful argumentation
- **SHOW** learning, discoveries, questioning rather than absolute certainties

### Document Structure
- **START** each section with contextual introduction
- **DEVELOP** arguments with concrete project examples
- **CONCLUDE** with perspectives or lessons learned
- **RESPECT** logical hierarchy: H2 for main sections, H3 for subsections

### Technical Justification
- **EXPLAIN** the why before the how for each technical choice
- **COMPARE** alternatives considered and argue the final choice
- **MENTION** project constraints (time, skills, resources)
- **INTEGRATE** learning aspects and skill development

### Words to Avoid
- "Simply", "easily", "quickly" (without justification)
- Impersonal formulations without context
- Unexplained technical jargon
- Unargued statements

### Words to Favor
- "In the context of this project"
- "This approach allows to"
- "I chose this solution because"
- "This decision is based on"
- "The analysis reveals that"
- "This experience allowed me to"
- "I discovered that", "I learn that", "I'm beginning to understand"
- "This approach allows me to explore", "This constitutes learning for me"

### Examples of Correct Formulations

❌ **Avoid:** "I used React because it's popular"
✅ **Correct:** "I chose React for the frontend based on my two years of experience with this technology, which allowed me to focus on business challenges rather than learning a new framework"

❌ **Avoid:** "PostgreSQL is a good database"
✅ **Correct:** "PostgreSQL emerged as the primary database choice due to its proven reliability in production contexts, my familiarity with this tool acquired during previous projects, and its advanced capabilities for managing complex relationships needed to model training data"

## Deployment

- Target: Cloudflare Pages (https://docs-dropit.pages.dev/)
- Requires Node.js >=18.20.8
- Uses Playwright for screenshot generation during build

## Project Context

This documentation serves as a technical portfolio demonstrating:
- Complete application development lifecycle
- Modern web technologies and best practices  
- Security considerations and implementation
- Testing strategies and deployment processes

The actual DropIt application being documented uses React/TypeScript frontend, Node.js/NestJS backend, and PostgreSQL database.