# Copilot Instructions

This is an Elm-based blog site that compiles to a static site hosted on GitHub Pages.

## Build & Development

**Build the application:**
```bash
./build.sh
# or directly:
elm make src/Main.elm --output=elm.js --optimize
```

**Local development server:**
```bash
python3 -m http.server 8000
# Visit http://localhost:8000
```

**Deployment:** Push to `main` branch. GitHub Actions workflow (`.github/workflows/deploy.yml`) automatically builds and deploys.

## Architecture

### Routing Strategy
The app uses **query parameter-based routing** (not URL paths) because it's hosted on GitHub Pages without server-side routing:
- Home: `?` or `?page=home`
- Post: `?page=post/{slug}`
- About: `?page=about`

This is parsed via `Url.Parser.Query` in the `parseUrl` function. Do not attempt to use path-based routing (`/post/slug`) as it won't work on GitHub Pages without additional configuration.

### Post System
Posts are **statically defined** in two places:
1. **Markdown files** in `posts/` directory (e.g., `welcome-to-my-blog.md`)
2. **Metadata** in `src/Main.elm` in the `samplePosts` list

When adding a post:
- Create the `.md` file with the slug name
- Add corresponding metadata to `samplePosts` with matching slug
- Rebuild with `./build.sh`

The app fetches post content via HTTP GET at runtime using `Http.get` pointing to `posts/{slug}.md`.

### Elm Application Structure
- **Model:** Tracks current page, post list, loaded post content, and loading state
- **URL parsing:** Custom parser extracts `page` query parameter
- **Navigation:** Uses `Browser.application` for URL management (not `Browser.element`)
- **Post loading:** Asynchronous HTTP requests load markdown content when navigating to a post page

## Key Conventions

- **Elm version:** 0.19.1 (specified in `elm.json`)
- **Module structure:** Single-file application (`src/Main.elm`)
- **Post categories:** Limited to "Code", "CS", or "Life" (update view functions if adding new categories)
- **Date format:** YYYY-MM-DD strings in post metadata
- **Optimization flag:** Always use `--optimize` flag for production builds to minimize bundle size
- **No build artifacts in git:** `elm.js` is the compiled output (typically gitignored in Elm projects, but committed here for GitHub Pages convenience)

## File Structure

```
src/Main.elm       - Single Elm module containing entire application
posts/*.md         - Blog post content (markdown)
index.html         - Entry point, loads elm.js
style.css          - Styling (not managed by Elm)
elm.js             - Compiled output (regenerated on each build)
```
