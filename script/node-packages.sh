#!/bin/bash

NPM_PACKAGES=(
"jscpd"
"jsctags"
"jsinspect"
"flow-language-server"
"ocaml-language-server"
"netlify-cli"
"now"
"parker"
"prettier"
"serve"
"source-map-explorer"
"surge"
"svgo"
"tern"
"overtime-cli"
)

for package in "${NPM_PACKAGES[@]}"; do
  yarn global add --prefix "~/.yarn" "$package"
done


unset -v NPM_PACKAGES
