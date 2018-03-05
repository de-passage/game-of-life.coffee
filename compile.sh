#!/bin/sh

mkdir -p scripts
webpack
./node_modules/node-sass/bin/node-sass --output styles sass
xdg-open ./index.html
