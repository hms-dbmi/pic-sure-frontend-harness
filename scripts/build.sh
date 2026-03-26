#!/usr/bin/env bash

# --- Move out of script dir ---
pushd ../
docker buildx bake $1
popd