# <img src="https://github.com/aidenybai/react-grab/blob/main/.github/public/logo.png?raw=true" width="60" align="center" /> Everywhere Grab

Coding agents often receive a screenshot or description without the source location needed to make a precise edit. This fork of [React Grab](https://github.com/aidenybai/react-grab) lets you select a UI element in a development site and copy its markup, source location, nearby code, and component stack for an agent. It adds plain-HTML project setup and a local-source installation path to the upstream project.

## Demo

[Try the upstream React Grab demo →](https://react-grab.com)

There is no separate hosted demo or deployment for this fork.

## Install this fork

Requires Git, Node.js 22+, and pnpm. The reviewable path is:

```bash
git clone https://github.com/pc-style/everywhere-grab.git
cd everywhere-grab
./install.sh
source .grab-fork.env
grab init
```

The installer builds from source and globally links the `grab` CLI; it does not install a separately published `everywhere-grab` npm package. By default a remote install clones into `~/.everywhere-grab`. The script can also append a line that sources `.grab-fork.env` to your shell profile, but asks first in an interactive shell.

After reviewing [`install.sh`](https://github.com/pc-style/everywhere-grab/blob/main/install.sh), the equivalent unattended download is:

```bash
curl -fsSL https://raw.githubusercontent.com/pc-style/everywhere-grab/main/install.sh | bash
```

Set `GRAB_INSTALL_NO_SHELL_RC=1` to prevent shell-profile changes. Set `GRAB_INSTALL_YES=1` to accept them without prompting. Override the clone location with `GRAB_FORK_DIR`, branch with `GRAB_INSTALL_BRANCH`, or repository URL with `GRAB_INSTALL_REPO`.

## Trust and privacy

- `install.sh` fetches source and npm dependencies, builds the workspace, globally links the CLI, and writes `.grab-fork.env`. Review it before running it, especially through `curl | bash`.
- Grabbed context can contain DOM markup, local source paths, source excerpts, and component names. Review it before pasting it into any external coding agent.
- This fork has not undergone an independent security or privacy audit. No security, privacy, or deployment guarantees are made here.

## Project status

This is an experimental downstream fork, not the canonical React Grab distribution. As of 2026-08-16, it is based on upstream commit [`e4e8bc4`](https://github.com/aidenybai/react-grab/commit/e4e8bc40f1b967dbd607af3fcfca0191ca89b872), has 8 fork-only commits, and is 161 upstream commits behind. Use [upstream React Grab](https://github.com/aidenybai/react-grab) for the current canonical release. No maintenance cadence or compatibility with current upstream is promised.

## Provenance and fork delta

The original project is [Aiden Bai's `aidenybai/react-grab`](https://github.com/aidenybai/react-grab). Its history, author metadata, package attribution, copyright notice, and MIT license are preserved.

Compared with the common ancestor above, this fork:

- adds plain-HTML detection and `index.html` transforms to `grab init`, with tests;
- allows `--pkg` / `GRAB_PKG` to point the CLI at a local package build;
- adds `install.sh` for cloning, building, globally linking, and optionally configuring that local build;
- adds a plain-HTML framework roadmap and Cursor Cloud notes; and
- removes the upstream publish-any-commit workflow from the fork.

See the [GitHub comparison](https://github.com/pc-style/everywhere-grab/compare/e4e8bc40f1b967dbd607af3fcfca0191ca89b872...main) for the concrete code delta.

## License

MIT. See [`LICENSE`](https://github.com/pc-style/everywhere-grab/blob/main/LICENSE), which retains the upstream copyright and license notice.

## How It Works

React Grab turns a browser selection into source context your agent can use:

1. Hover any UI element in your app.
2. Press **⌘C** or **Ctrl+C**.
3. Paste the copied context into your agent.

The copied context includes the selected element, source location, nearby code, and component stack:

```txt
<a class="ml-auto inline-block text-sm" href="#">
  Forgot your password?
</a>

// components/login-form.tsx:46
  45| <div className="flex items-center">
> 46|   <a className="ml-auto inline-block text-sm" href="#">
  47|     Forgot your password?
  48|   </a>

  in LoginForm (at components/login-form.tsx:46:19)
```

## Manual Installation

If you cannot use the CLI, install React Grab manually for your framework:

#### Next.js (App router)

Add this inside your `app/layout.tsx`:

```jsx
import Script from "next/script";

export default function RootLayout({ children }) {
  return (
    <html>
      <head>
        {process.env.NODE_ENV === "development" && (
          <Script
            src="//unpkg.com/grab/dist/index.global.js"
            crossOrigin="anonymous"
            strategy="beforeInteractive"
          />
        )}
      </head>
      <body>{children}</body>
    </html>
  );
}
```

#### Next.js (Pages router)

Add this into your `pages/_document.tsx`:

```jsx
import { Html, Head, Main, NextScript } from "next/document";

export default function Document() {
  return (
    <Html lang="en">
      <Head>
        {process.env.NODE_ENV === "development" && (
          <Script
            src="//unpkg.com/grab/dist/index.global.js"
            crossOrigin="anonymous"
            strategy="beforeInteractive"
          />
        )}
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
```

#### Vite

Add this at the top of your main entry file (e.g., `src/main.tsx`):

```tsx
if (import.meta.env.DEV) {
  import("grab");
}
```

#### Webpack

First, install React Grab:

```bash
npm install grab
```

Then add this at the top of your main entry file (e.g., `src/index.tsx` or `src/main.tsx`):

```tsx
if (process.env.NODE_ENV === "development") {
  import("grab");
}
```

## Plugins

Use plugins to extend React Grab's built-in UI with context menu actions, toolbar menu items, lifecycle hooks, and theme overrides. Plugins run within React Grab.

Register a plugin using the `registerPlugin` and `unregisterPlugin` exports:

```js
import { registerPlugin } from "grab";

registerPlugin({
  name: "my-plugin",
  hooks: {
    onElementSelect: (element) => {
      console.log("Selected:", element.tagName);
    },
  },
});
```

In React, register inside a `useEffect`:

```jsx
import { registerPlugin, unregisterPlugin } from "grab";

useEffect(() => {
  registerPlugin({
    name: "my-plugin",
    actions: [
      {
        id: "my-action",
        label: "My Action",
        shortcut: "M",
        onAction: (context) => {
          console.log("Action on:", context.element);
          context.hideContextMenu();
        },
      },
    ],
  });

  return () => unregisterPlugin("my-plugin");
}, []);
```

Actions use a `target` field to control where they appear. Omit `target` (or set `"context-menu"`) for the right-click menu, or set `"toolbar"` for the toolbar dropdown:

```js
actions: [
  {
    id: "inspect",
    label: "Inspect",
    shortcut: "I",
    onAction: (ctx) => console.dir(ctx.element),
  },
  {
    id: "toggle-freeze",
    label: "Freeze",
    target: "toolbar",
    isActive: () => isFrozen,
    onAction: () => toggleFreeze(),
  },
];
```

See [`packages/react-grab/src/types.ts`](https://github.com/aidenybai/react-grab/blob/main/packages/react-grab/src/types.ts) for the full `Plugin`, `PluginHooks`, and `PluginConfig` interfaces.

## Upstream resources and contributing

The [demo](https://react-grab.com), [Contributing Guide](https://github.com/aidenybai/react-grab/blob/main/CONTRIBUTING.md), [Discord](https://discord.com/invite/G7zxfUzkm7), [issue tracker](https://github.com/aidenybai/react-grab/issues), and [Code of Conduct](https://github.com/aidenybai/react-grab/blob/main/.github/CODE_OF_CONDUCT.md) are maintained by the upstream React Grab project. Report fork-specific installer or plain-HTML issues in this repository; send changes intended for the canonical project upstream.

_Thank you to [Andrew Luetgers](https://github.com/andrewluetgers) for donating the `grab` npm package name._
