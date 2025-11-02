# Technical Information - Starlight & Astro

This documentation project is built with [Starlight](https://starlight.astro.build/), a documentation template for [Astro](https://astro.build).

## Starlight Template

This project is based on the official Starlight template from Astro, which provides an optimized structure for building modern and performant documentation sites.

## File Structure

Starlight looks for `.md` or `.mdx` files in the `src/content/docs/` directory. Each file is exposed as a route based on its file name.

### Assets Organization

- **Images**: Add images to `src/assets/` and embed them in Markdown with a relative link
- **Static assets**: Static files (favicons, etc.) should be placed in the `public/` directory

## Available Commands

All commands are run from the root of the project, from a terminal:

| Command                   | Action                                           |
| :------------------------ | :----------------------------------------------- |
| `pnpm install`            | Installs dependencies                            |
| `pnpm dev`                | Starts local dev server at `localhost:4321`      |
| `pnpm build`              | Build your production site to `./dist/`          |
| `pnpm preview`            | Preview your build locally, before deploying     |
| `pnpm astro ...`          | Run CLI commands like `astro add`, `astro check` |
| `pnpm astro -- --help`    | Get help using the Astro CLI                     |

## Useful Resources

- [Starlight Documentation](https://starlight.astro.build/)
- [Astro Documentation](https://docs.astro.build)
- [Astro Discord Server](https://astro.build/chat)

## Credits

This project is based on the Starlight template developed by the Astro team.
