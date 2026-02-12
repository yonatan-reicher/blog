# About This Project

This repository is my personal website. Built with Elm, because I love
functional programming. Check it out [right here](https://yonatan-reicher.github.io/blog/)!

## Running Locally

After cloning the repository, everything should already be set up. Just open up
a local server and your ready to go. You probably have python installed, so you
can just run:
```bash
python -m http.server
```

Now navigate to `localhost:8000` in your browser and you should see the site!

## Building

For building you need Elm 0.19, and make. Just run `make` and the site will be
ready.

## Adding a Blog Post

Blogs are html/markdown documents in the `blog/posts/` directory. Every post
must be listed in the `blog/posts.json` file.

To add a new post, **use the `new-post.py` script**. Run it from the `blog/`
directory.

```bash
cd blog/
python3 new-post.py ...
```

