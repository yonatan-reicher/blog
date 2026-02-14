# About This Project

A static website to host some written thoughts. A blog! Built with Elm, because
I love pure functional programming. Check it out
[right here!](https://yonatan-reicher.github.io/blog)

## Structure

```
.
├── build.sh         # Builds the website
├── src/
│   ├── style.css    # Stylesheets for the app
│   └── Main.elm     # Main Elm application
├── posts/           # Blog posts in Markdown
│   ├── *.md
│   └── *.html
├── build/           # Build artifacts
├── posts.json       # List of all posts
└── index.html       # Entry point
```

## Running Locally

After cloning the repository, everything should already be set up. Just open up
a local server and your ready to go. You probably have python installed, so you
can just run:
```bash
python3 -m http.server
```

Now navigate to `localhost:8000` in your browser and you should see the site!

## Building

For building you need Elm 0.19, and a shell. Just run `build.sh` and the site
will be ready.

## Routing

Because this is a single-page site hosted on GitHub, I use query parameters for
navigation (GitHub hosting only allows having a single domain path host a
single-page site. So it's either this or the ugly hash-based routing).

- Home: `?` or `?page=home`
- Post: `page=post/<id>`

## Adding a Post

Blogs are html/markdown documents in the `posts/` directory. Every post
must be listed in the `posts.json` file.
