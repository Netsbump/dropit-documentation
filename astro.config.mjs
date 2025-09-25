// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { rehypeMermaid } from "@beoe/rehype-mermaid";

// https://astro.build/config
export default defineConfig({
	site: 'https://docs-dropit.pages.devf',
	markdown: {
		rehypePlugins: [
			[
				rehypeMermaid,
				{
					strategy: "file",
					fsPath: "public/beoe",
					webPath: "/beoe",
					darkScheme: "class",
				},
			],
		],
	},
	integrations: [
		starlight({
			title: 'DropIt Docs',
			defaultLocale: 'root',
			locales: {
				root: {
					label: 'Français',
					lang: 'fr',
				},
			},
			social: {
				github: 'https://github.com/withastro/starlight',
			},
			customCss: [
				'./src/styles/mermaid.css',
			],
			sidebar: [
				{
					label: 'Introduction',
					items: [
						{ label: 'Présentation du projet', link: '/introduction/presentation/' },
						{ label: 'Contexte et enjeux', link: '/introduction/contexte/' },
					],
				},
				{
					label: 'Conception et développement',
					items: [
						{ label: 'Analyse des besoins', link: '/conception/analyse/' },
						{ label: 'Architecture logicielle', link: '/conception/architecture/' },
						{ label: 'Base de données', link: '/conception/base-donnees/' },
						{ label: 'Accès aux données', link: '/conception/acces-donnees/' },
						{ label: 'Présentations', link: '/conception/presentations/' },
						{ label: 'Interfaces', link: '/conception/interfaces/' },
					],
				},
				{
					label: 'Sécurité',
					items: [
						{ label: 'Conception', link: '/securite/conception/' },
						{ label: 'Authentification', link: '/securite/authentification/' },
						{ label: 'Gestion des roles', link: '/securite/permissions/' },
					],
				},
				{
					label: 'Tests et validation',
					items: [
						{ label: 'Plans de tests', link: '/tests/plans/' },
						{ label: 'Validation des composants', link: '/tests/validation/' },
					],
				},
				{
					label: 'Déploiement et production',
					items: [
						{ label: 'Préparation au déploiement', link: '/deploiement/preparation/' },
						{ label: 'Mise en production', link: '/deploiement/production/' },
					],
				},
				{
					label: 'Gestion de projet',
					items: [
						{ label: 'Contribution au projet', link: '/gestion/contribution/' },
						{ label: 'Documentations', link: '/gestion/documentations/' },
					],
				},
				{
					label: 'Annexes',
					items: [
						{ label: 'Analyse des besoins', link: '/annexes/analyse-besoins/' },
						{ label: 'Architecture technique', link: '/annexes/architecture-technique/' },
						{ label: 'Conception technique de la base de données', link: '/annexes/conception-base-donnees/' },
						{ label: 'Implémentation accès aux données', link: '/annexes/implementation-acces-donnees/' },
						{ label: 'Implémentation présentations', link: '/annexes/implementation-presentations/' },
						{ label: 'Authentifications', link: '/annexes/authentifications/' },
						{ label: 'Permissions', link: '/annexes/permissions/' },
						{ label: 'Glossaire', link: '/annexes/glossaire/' },
						{ label: 'Cahier des charges', link: '/annexes/cahier-des-charges/' },
						{ label: 'Bilan', link: '/annexes/bilan/' },
					],
				},
			],
		}),
	],
});
