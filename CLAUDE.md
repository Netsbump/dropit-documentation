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