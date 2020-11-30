#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
REPO_DIR=$(cd "${SCRIPT_DIR}/../.."; pwd -P)

REPO_SLUG="$1"
if [[ -z "${REPO_SLUG}" ]]; then
  REPO_SLUG="ibmgaragecloud/developer-dashboard"
fi

set -e

LATEST_TAG=$(curl https://quay.io/api/v1/repository/${REPO_SLUG}/tag/ -s | jq -r '.tags | .[] | select(.name != "latest" and .name != "dev" and .name != "main" and .name != "master") | .name' | sort -Vr | head -1)
echo "Latest tag: ${LATEST_TAG}"

CURRENT_TAG=$(cat "${REPO_DIR}/variables.tf" | grep "image_tag" -A 4 | grep default | sed -E "s/ +default += \"(.*)\"/\1/")
echo "Current tag: ${CURRENT_TAG}"

echo "Updating variables.tf with latest tag "

if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' -E "s/${CURRENT_TAG}/${LATEST_TAG}/" "${REPO_DIR}/variables.tf"
else
  sed -i -E "s/${CURRENT_TAG}/${LATEST_TAG}/" "${REPO_DIR}/variables.tf"
fi
