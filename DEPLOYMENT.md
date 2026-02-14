# Deployment Guide

## Quick Start

1. **Test Locally**
   ```bash
   ./build.sh
   python3 -m http.server 8000
   ```
   Visit http://localhost:8000

2. **Deploy to GitHub Pages**

   a. Create a new repository on GitHub
   
   b. Initialize and push:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Elm blog site"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

   c. Enable GitHub Pages:
   - Go to repository Settings → Pages
   - Under "Build and deployment" → Source: GitHub Actions
   - The workflow will automatically run and deploy

3. **Your site will be live at:**
   `https://YOUR_USERNAME.github.io/YOUR_REPO/`

## Adding New Posts

1. Create a markdown file in `posts/` directory:
   ```bash
   posts/my-new-post.md
   ```

2. Add metadata to `src/Main.elm` in the `samplePosts` list:
   ```elm
   , { slug = "my-new-post"
     , title = "My New Post"
     , date = "2024-02-14"
     , category = "Code"  -- or "CS" or "Life"
     , excerpt = "Brief description..."
     }
   ```

3. Rebuild:
   ```bash
   ./build.sh
   ```

4. Commit and push:
   ```bash
   git add .
   git commit -m "Add new post: My New Post"
   git push
   ```

## URL Structure

- Home: `?` or `index.html`
- Post: `?page=post/my-post-slug`
- About: `?page=about`

Query parameters work perfectly with GitHub Pages without any special configuration!

## Customization

- **Styles**: Edit `style.css`
- **Layout**: Modify `src/Main.elm` view functions
- **Posts**: Add/edit markdown files in `posts/`

## Troubleshooting

**Posts not loading?**
- Check that the post filename matches the slug
- Ensure the post is listed in `samplePosts`
- Verify elm.js was rebuilt after changes

**404 errors?**
- For GitHub Pages project sites, all routes use query parameters
- No special 404.html needed with this approach
