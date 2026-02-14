#!/bin/bash
set -e

USAGE="USAGE: build.sh [debug]"

# Calculate flags
if [[ $1 = "" ]]; then
    FLAGS='--optimize'
elif [[ $1 = 'debug' ]]; then
    FLAGS='--debug'
else
    echo "Invalid argument $1"
    echo $USAGE
    exit 1
fi

echo "Building Elm application..."
elm make src/Main.elm --output=build/elm.js $FLAGS

echo "Build complete! Files ready for deployment."
echo "To test locally: python3 -m http.server 8000"
