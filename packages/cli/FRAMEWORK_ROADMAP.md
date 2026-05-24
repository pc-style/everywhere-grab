# CLI framework roadmap

## Plain HTML (shipped)

`grab init` detects projects with `index.html` and no React dependency when there is no bundled entry file (`src/main.tsx`, etc.).

- **Vite (or `vite.config`)**: injects a dev-only module script in `index.html` that dynamic-imports `react-grab`.
- **Static HTML**: injects the `index.global.js` CDN script (same bundle as Next.js manual setup).

Vanilla JS/TS apps that use Vite with a `src/main.js` entry still use the existing Vite transform on that entry file.

## Astro (planned)

Astro is currently listed as unsupported in `detectUnsupportedFramework`. Planned work:

- Detect Astro projects without blocking `grab init` when appropriate (islands + static pages).
- Inject into the root layout or a shared head component, respecting `import.meta.env.DEV` / SSR boundaries.
- Document interaction with React islands vs plain HTML pages.

## `grab create` scaffold (planned)

Optional command to scaffold a minimal dev setup for plain HTML/CSS products:

- `package.json` with `vite` and `react-grab`
- `index.html` with Grab wired for development
- `dev` script so `grab init` users without a bundler can run a local server immediately
