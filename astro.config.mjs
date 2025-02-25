// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://docs-dropit.pages.devf',
	integrations: [
		starlight({
			title: 'DropIt Docs',
			social: {
				github: 'https://github.com/withastro/starlight',
			},
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
						{ label: 'Interfaces utilisateur', link: '/conception/interfaces/' },
						{ label: 'Base de données', link: '/conception/base-donnees/' },
						{ label: 'Accès aux données', link: '/conception/acces-donnees/' },
					],
				},
				{
					label: 'Sécurité',
					items: [
						{ label: 'Conception sécurisée', link: '/securite/conception/' },
						{ label: 'Gestion des accès', link: '/securite/acces/' },
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
						{ label: 'Documentation et rapports', link: '/gestion/documentation/' },
					],
				},
				{
					label: 'Environnement de travail',
					items: [
						{ label: 'Installation et configuration', link: '/environnement/installation/' },
						{ label: 'Outils et technologies', link: '/environnement/outils/' },
					],
				},
				{
					label: 'Annexes',
					items: [
						{ label: 'Glossaire', link: '/annexes/glossaire/' },
						{ label: 'Références', link: '/annexes/references/' },
					],
				},
			],
		}),
	],
});
