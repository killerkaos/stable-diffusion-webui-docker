#!/bin/bash

set -Eeox pipefail

mkdir -p /repositories/"$1"
cd /repositories/"$1"
git init
git remote add origin "$2"

if [ -n "$3" ]; then
    git fetch origin "$3" --depth=1
    git reset --hard "$3"
fi

rm -rf .git
