#!/bin/bash

set -ev

./scripts/ci/prepare-webclients.sh

yarn app:dist

# needed for e2e starts with SUID sandbox if user namespacing disabled
# https://github.com/electron/electron/issues/16631#issuecomment-476082063
# https://github.com/electron/electron/issues/17972
sudo ./scripts/prepare-chrome-sandbox.sh ./node_modules/electron/dist/chrome-sandbox

yarn test:e2e

# --env-file: https://github.com/electron-userland/electron-builder/issues/2450

# TODO use own docker image
docker run --rm -ti \
    --env-file <(env | grep -vE '\r|\n' | grep -iE '^(DEBUG|NODE_|ELECTRON_|YARN_|NPM_|CI|CIRCLE|TRAVIS|APPVEYOR|BUILD_)[A-Z_]*=') \
    -v ${PWD}:/project \
    -v ${PWD##*/}-node-modules:/project/node_modules \
    -v ~/.cache/electron:/root/.cache/electron \
    -v ~/.cache/electron-builder:/root/.cache/electron-builder \
    electronuserland/builder \
    /bin/bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash && export NVM_DIR=~/.nvm && source ~/.nvm/nvm.sh && nvm install $TRAVIS_NODE_VERSION && nvm use $TRAVIS_NODE_VERSION && apt-get update && apt-get install --yes --no-install-recommends libtool automake squashfs-tools libxss-dev snapcraft && yarn --pure-lockfile && yarn clean:prebuilds && yarn scripts/electron-builder/sequential-dist-linux"

yarn scripts/dist-packages/print-hashes
yarn scripts/dist-packages/upload
