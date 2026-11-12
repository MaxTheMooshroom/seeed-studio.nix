#!/usr/bin/env bash

nix build \
  --cores 8 \
  --print-build-logs \
  --keep-going \
  --show-trace

