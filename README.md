<a name="readme-top"></a>

<!-- LOGO DU PROJET -->
<br />
<div align="center">
  <a href="https://github.com/Netsbump/dropit-documentation">
    <img src="chemin-vers-votre-logo-si-disponible" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">DropIt Documentation : Application de Club d'Haltérophilie</h3>

  <p align="center">
    La documentation officielle du projet DropIt, une application web dédiée à la gestion des clubs d'haltérophilie.
    Ce projet est développé dans le cadre de la préparation du titre professionnel
    "Concepteur Développeur d'Applications" (RNCP Niveau 6).
    <br />
    <br />
    <a href="https://docs-dropit.pages.dev/">Voir la Documentation</a>
    ·
    <a href="https://github.com/Netsbump/dropit-documentation/issues">Signaler un Bug</a>
    ·
    <a href="https://github.com/Netsbump/dropit-documentation/pulls">Demander une Fonctionnalité</a>
  </p>
</div>

---

## 📖 À propos

DropIt est une application web conçue pour simplifier la gestion des clubs d'haltérophilie. 
Ce projet s'inscrit dans le cadre de la formation "Concepteur Développeur d'Applications" et vise à répondre 
aux besoins réels des clubs sportifs en matière de suivi des athlètes et organisation des entraînements.

Cette documentation détaille l'ensemble du processus de développement, depuis l'analyse des besoins jusqu'au 
déploiement, en passant par la conception technique et les choix d'architecture.

## 📁 Structure du Projet

 ```
 src/content/docs/
 ├── introduction/
 │   ├── presentation.md     # Présentation du projet
 │   └── contexte.md        # Contexte et enjeux
 ├── environnement/
 │   ├── installation.md    # Guide d'installation
 │   └── outils.md         # Technologies utilisées
 ├── conception/
 │   ├── analyse.md        # Analyse des besoins
 │   ├── architecture.md   # Architecture logicielle
 │   ├── interfaces.md     # Interfaces utilisateur
 │   ├── composants.md     # Composants métier
 │   ├── base-donnees.md   # Structure BDD
 │   └── acces-donnees.md  # Accès aux données
 ├── securite/
 │   ├── conception.md     # Sécurité générale
 │   └── acces.md         # Gestion des accès
 ├── tests/
 │   ├── plans.md         # Plans de tests
 │   └── validation.md    # Validation
 ├── deploiement/
 │   ├── preparation.md   # Préparation
 │   └── production.md    # Mise en production
 ├── gestion/
 │   ├── contribution.md  # Contribution
 │   └── documentation.md # Documentation
 └── annexes/
     ├── glossaire.md     # Glossaire
     └── references.md    # Références
 ```


Starlight looks for `.md` or `.mdx` files in the `src/content/docs/` directory. Each file is exposed as a route based on its file name.

Images can be added to `src/assets/` and embedded in Markdown with a relative link.

Static assets, like favicons, can be placed in the `public/` directory.

## 🧞 Commands

All commands are run from the root of the project, from a terminal:

| Command                   | Action                                           |
| :------------------------ | :----------------------------------------------- |
| `npm install`             | Installs dependencies                            |
| `npm run dev`             | Starts local dev server at `localhost:4321`      |
| `npm run build`           | Build your production site to `./dist/`          |
| `npm run preview`         | Preview your build locally, before deploying     |
| `npm run astro ...`       | Run CLI commands like `astro add`, `astro check` |
| `npm run astro -- --help` | Get help using the Astro CLI                     |

## 👀 Want to learn more?

Check out [Starlight's docs](https://starlight.astro.build/), read [the Astro documentation](https://docs.astro.build), or jump into the [Astro Discord server](https://astro.build/chat).
