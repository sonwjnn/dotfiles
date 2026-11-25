---
name: Bun
description: Use when building, testing, bundling, or managing JavaScript/TypeScript applications with Bun. Reach for Bun when running Bun scripts, managing Bun workspaces, testing with bun test, bundling with bun build, or configuring Bun-specific runtime behavior.
---

# Bun Skill Reference

## Product Summary

Bun is an all-in-one JavaScript/TypeScript toolkit written in Rust and powered by JavaScriptCore. It replaces Node.js, npm, and other tools with a single binary. Key components:

- **Runtime**: Execute `.js`, `.ts`, `.jsx`, `.tsx` files directly with native transpilation (4x faster startup than Node.js)
- **Package Manager**: `bun install` is 25x faster than npm with global caching and workspace support
- **Test Runner**: Jest-compatible `bun test` with TypeScript, snapshots, mocks, and watch mode
- **Bundler**: `bun build` for browser and server bundles with code splitting and plugins

**Key files**: `bunfig.toml` (configuration), `package.json` (scripts and dependencies), `bun.lock` (lockfile)

**Primary docs**: <https://bun.com/docs>

---

## When to Use

Reach for Bun when:

- **Running scripts**: Execute TypeScript/JSX files without compilation step (`bun run script.ts`)
- **Managing dependencies**: Install packages faster with `bun install` in any Node.js project
- **Testing**: Write Jest-compatible tests with `bun test` and run them in parallel
- **Bundling**: Build optimized bundles for browsers or servers with `bun build`
- **Package scripts**: Run `package.json` scripts 28x faster than npm (`bun run dev`)
- **Development**: Use `--watch` or `--hot` for file watching and hot reloading
- **Monorepos**: Manage workspaces with `bun install --filter` and workspace commands

Do not use Bun for type checking (use `tsc` separately), generating type declarations, or projects requiring Node.js-only APIs not yet implemented in Bun.

## Quick Reference

### Essential Commands

| Task | Command |
|---|---|
| Run a file | `bun run script.ts` or `bun script.ts` |
| Run a script | `bun run dev` (from `package.json`) |
| Install dependencies | `bun install` or `bun i` |
| Add a package | `bun add react` or `bun add -d @types/node` |
| Remove a package | `bun remove react` |
| Run tests | `bun test` |
| Build a bundle | `bun build ./index.ts --outdir ./dist` |
| Watch files | `bun --watch run script.ts` or `bun build --watch` |
| Hot reload | `bun --hot run server.ts` |
| Execute a package | `bunx cowsay "Hello"` |

### Configuration Files

| File | Purpose |
|---|---|
| `bunfig.toml` | Bun-specific settings (runtime, test, install, bundler) |
| `package.json` | Scripts, dependencies, workspaces, metadata |
| `tsconfig.json` | TypeScript compiler options (Bun reads this) |
| `.env` | Environment variables (auto-loaded) |
| `bun.lock` | Text-based lockfile; replaces `package-lock.json` |

### Common `bunfig.toml` Sections

```toml
[install]
linker = "hoisted"  # or "isolated" for strict dependency isolation
dev = true
optional = true
production = false

[test]
root = "."
preload = ["./setup.ts"]
coverage = false

[serve]
port = 3000

[run]
shell = "system"  # or "bun" on Windows
bun = true          # alias node to bun in scripts
```

## Decision Guidance

### When to Use Hoisted vs. Isolated Installs

| Scenario | Use | Reason |
|---|---|---|
| New monorepo/workspace | `isolated` | Prevents phantom dependencies, strict isolation |
| New single-package project | `hoisted` | Traditional npm behavior, simpler |
| Existing project (pre-v1.3.2) | `hoisted` | Backward compatibility |
| Migrating from pnpm | `isolated` | Similar to pnpm's approach |

Set with `bun install --linker isolated` or in `bunfig.toml` under `[install]`.

### When to Use `--watch` vs. `--hot`

| Use case | Flag | Behavior |
|---|---|---|
| File changes trigger re-run | `--watch` | Full process restart, clean state |
| HTTP server development | `--hot` | Soft reload, preserves global state, faster |
| Test development | `--watch` | Better isolation between runs |
| Library bundling | `bun build --watch` | Incremental rebuilds |

### When to Use `bun run` vs. Direct Execution

| Scenario | Command | Why |
|---|---|---|
| Run a script from `package.json` | `bun run dev` | Respects lifecycle hooks (`pre`/`post`) |
| Run a file directly | `bun script.ts` | Faster, no script lookup |
| Run a local CLI tool | `bun run eslint` | Resolves from `node_modules/.bin` |
| Run a system command | `bun run ls` | Only works with `bun run` |

## Workflow

### 1. Initialize a Project

```bash
bun init my-app
# Choose template: Blank, React, or Library
cd my-app
```

This creates `package.json`, `tsconfig.json`, `index.ts`, and `.gitignore`.

### 2. Install Dependencies

```bash
bun install
# or add specific packages
bun add react
bun add -d typescript @types/node
```

Bun creates `bun.lock` (text-based lockfile) and `node_modules/`.

### 3. Write and Run Code

```bash
# Create index.ts with TypeScript/JSX (no compilation needed)
bun run index.ts

# Or add to package.json scripts
# "scripts": { "dev": "bun run index.ts" }
bun run dev
```

### 4. Write Tests

```typescript
import { test, expect } from "bun:test";

test("2 + 2 = 4", () => {
  expect(2 + 2).toBe(4);
});
```

```bash
bun test
bun test --watch
bun test --coverage
```

### 5. Bundle for Production

```bash
# Build for browser
bun build ./index.tsx --outdir ./dist --target browser

# Build for Node.js
bun build ./server.ts --outdir ./dist --target node --format cjs

# Build with minification
bun build ./index.ts --outdir ./dist --minify
```

### 6. Configure `bunfig.toml` (Optional)

```toml
[install]
linker = "isolated"

[test]
coverage = true
coverageThreshold = 0.8

[serve]
port = 3000
```

## Common Gotchas

- **Lifecycle scripts disabled by default**: Bun doesn't run `postinstall` scripts for security. Add packages to `trustedDependencies` in `package.json` to allow them.
- **Flags go after `bun`, not after the command**: Use `bun --watch run dev`, not `bun run dev --watch`. Flags at the end are passed to the script itself.
- **`bun run` prefers scripts over files**: If both a script and file have the same name, `bun run` runs the script. Use `bun run ./file.ts` to force file execution.
- **Environment variables must be literal**: `process.env.FOO` works in the bundler, but `const env = process.env; env.FOO` does not. Use `process.env.FOO` directly.
- **Auto-install only works without `node_modules`**: If `node_modules` exists, Bun uses it. Delete `node_modules` to enable auto-install from the global cache.
- **`bun.lock` is text-based by default**: Prior to v1.2, lockfiles were binary (`bun.lockb`). Upgrade with `bun install --save-text-lockfile --frozen-lockfile --lockfile-only`.
- **TypeScript 6+ requires explicit types**: Add `"types": ["bun"]` to `tsconfig.json` `compilerOptions` if using TypeScript 6 or later.
- **Phantom dependencies in hoisted mode**: With `linker = "hoisted"`, packages can import undeclared dependencies. Use `linker = "isolated"` to prevent this.
- **Test files must match patterns**: Bun only discovers `*.test.ts`, `*_test.ts`, `*.spec.ts`, and `*_spec.ts`. Adjust with `pathIgnorePatterns` in `bunfig.toml`.
- **Bundler doesn't type-check**: Use `tsc --noEmit` separately. Bun's bundler only transpiles.

## Verification Checklist

Before submitting work with Bun:

- [ ] Dependencies installed: `bun install` runs without errors
- [ ] Scripts work: `bun run <script>` executes correctly
- [ ] Tests pass: `bun test` shows all tests passing
- [ ] No TypeScript errors: Run `tsc --noEmit` if type checking is needed
- [ ] Bundle builds: `bun build` completes without errors
- [ ] Environment variables set: `.env` exists with required variables
- [ ] Lockfile committed: `bun.lock` is in version control
- [ ] No deprecated APIs: Check Bun docs for Node.js compatibility status
- [ ] Watch mode works: `bun --watch run dev` detects file changes
- [ ] Hot reload functional: `bun --hot run server.ts` updates without restart

## Resources

- Comprehensive navigation: <https://bun.com/docs/llms.txt>
- Runtime — Running files and scripts: <https://bun.com/docs/runtime>
- Package Manager — Installing and managing dependencies: <https://bun.com/docs/pm>
- Test Runner — Writing and running tests: <https://bun.com/docs/test>
- Bundler — Building and bundling code: <https://bun.com/docs/bundler>

For additional documentation and navigation, see: <https://bun.com/docs/llms.txt>
