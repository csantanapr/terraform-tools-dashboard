#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
REPO_DIR=$(cd "${SCRIPT_DIR}/../.."; pwd -P)

REPO_SLUG="$1"
if [[ -z "${REPO_SLUG}" ]]; then
  REPO_SLUG="ibmgaragecloud/developer-dashboard"
fi

set -e

LATEST_TAG=$(curl -s "https://registry.hub.docker.com/v1/repositories/${REPO_SLUG}/tags" | jq -r '[sort_by(.name) | reverse | .[] | select(.name != "latest" and .name != "dev") | .name] | .[0]' | sort -Vr | head -1)
echo "Latest tag: ${LATEST_TAG}"

CURRENT_TAG=$(cat "${REPO_DIR}/variables.tf" | grep "image_tag" -A 4 | grep default | sed -E "s/ +default += \"(.*)\"/\1/")
echo "Current tag: ${CURRENT_TAG}"

echo "Updating variables.tf with latest tag "
sed -i "" -E "s/${CURRENT_TAG}/${LATEST_TAG}/" "${REPO_DIR}/variables.tf"
