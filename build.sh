#!/bin/bash

DIR=`dirname "$0"`
DIR=`exec 2>/dev/null;(cd -- "$DIR") && cd -- "$DIR"|| cd "$DIR"; unset PWD; /usr/bin/pwd || /bin/pwd || pwd`
# BW_VERSION=$(curl -sL https://go.btwrdn.co/bw-sh-versions | grep '^ *"'coreVersion'":' | awk -F\: '{ print $2 }' | sed -e 's/,$//' -e 's/^"//' -e 's/"$//')
BW_VERSION="2024.1.2"

echo "Building BitBetter for BitWarden version $BW_VERSION"

# If there aren't any keys, generate them first.
[ -e "$DIR/.keys/cert.cert" ] || "$DIR/.keys/generate-keys.sh"

[ -e "$DIR/src/bitBetter/.keys" ] || mkdir "$DIR/src/bitBetter/.keys"

cp "$DIR/.keys/cert.cert" "$DIR/src/bitBetter/.keys"

docker run --rm -v "$DIR/src/bitBetter:/bitBetter" -w=/bitBetter mcr.microsoft.com/dotnet/sdk:6.0 sh build.sh

docker build --no-cache --build-arg BITWARDEN_TAG=bitwarden/api:$BW_VERSION --label com.bitwarden.product="bitbetter" -t bitbetter/api "$DIR/src/bitBetter" # --squash
docker build --no-cache --build-arg BITWARDEN_TAG=bitwarden/identity:$BW_VERSION --label com.bitwarden.product="bitbetter" -t bitbetter/identity "$DIR/src/bitBetter" # --squash
docker build --no-cache -t bitbetter/licensegen "$DIR/src/licenseGen" # --squash

docker tag bitbetter/api bitbetter/api:latest
docker tag bitbetter/identity bitbetter/identity:latest
docker tag bitbetter/api bitbetter/api:$BW_VERSION
docker tag bitbetter/identity bitbetter/identity:$BW_VERSION

docker tag bitbetter/licensegen bitbetter/licensegen:latest
docker tag bitbetter/licensegen bitbetter/licensegen:0.1

# # Remove old instances of the image after a successful build.
# ids=$( docker images bitbetter/* | grep -E -v -- "CREATED|latest|${BW_VERSION}" | awk '{ print $3 }' )
# [ -n "$ids" ] && docker rmi $ids || true

# echo "Saving artifacts..."
# mkdir -p "$DIR/artifacts"
# # Save built dockers for upload as artifacts
# docker save bitbetter/api:$BW_VERSION | gzip > "$DIR/artifacts/bitbetter_api.tar.gz"
# docker save bitbetter/identity:$BW_VERSION | gzip > "$DIR/artifacts/bitbetter_identity.tar.gz"
echo "bw_version=$BW_VERSION" >> $GITHUB_ENV
