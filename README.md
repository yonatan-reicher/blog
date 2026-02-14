# Code, CS & Life - Blog

A simple, elegant blog built with Elm and hosted on GitHub Pages.

## Features

- ✨ Clean, minimal design
- 📝 Markdown-based blog posts
- 🔍 Query parameter-based routing (perfect for GitHub Pages)
- 🎨 Responsive layout
- ⚡ Built with Elm for reliability and maintainability

## Structure

```
.
├── src/
│   └── Main.elm          # Main Elm application
├── posts/                # Blog posts in Markdown
│   ├── welcome-to-my-blog.md
│   ├── elm-architecture-explained.md
│   └── algorithms-for-beginners.md
├── index.html            # Entry point
├── style.css             # Styles
└── elm.js                # Compiled Elm code
```

## Development

### Prerequisites

- Elm 0.19.1+

### Building

```bash
elm make src/Main.elm --output=elm.js --optimize
```

### Local Development

Open `index.html` in your browser or use a simple HTTP server:

```bash
python3 -m http.server 8000
```

Then visit `http://localhost:8000`

## Adding Blog Posts

1. Create a new `.md` file in the `posts/` directory
2. Add the post metadata to the `samplePosts` list in `src/Main.elm`:

```elm
{ slug = "your-post-slug"
, title = "Your Post Title"
, date = "2024-02-14"
, category = "Code"  -- or "CS" or "Life"
, excerpt = "A brief description..."
}
```

3. Recompile: `elm make src/Main.elm --output=elm.js --optimize`

## Routing

The blog uses query parameters for routing, which works perfectly with GitHub Pages:

- Home: `?` or `?page=home`
- Blog post: `?page=post/your-post-slug`
- About: `?page=about`

## Deploying to GitHub Pages

1. Create a new repository on GitHub
2. Initialize git and add files:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   ```
3. Push to GitHub:
   ```bash
   git branch -M main
   git remote add origin https://github.com/username/repo-name.git
   git push -u origin main
   ```
4. Go to Settings → Pages → Source → Select "main" branch
5. Your site will be live at `https://username.github.io/repo-name/`

## License

MIT
