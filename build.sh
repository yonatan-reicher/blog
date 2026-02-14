#!/bin/bash
set -e

echo "Building Elm application..."
elm make src/Main.elm --output=elm.js --optimize

echo "Build complete! Files ready for deployment."
echo "To test locally: python3 -m http.server 8000"
