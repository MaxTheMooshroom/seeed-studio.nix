#!/usr/bin/env bash

set -euo pipefail

DTBS=/nix/store/b0dlv6wrzn294b4cnr4q15spvbpkd117-linux_rpi-bcm2711-6.18.33-stable_20260527/dtbs

BASE="$DTBS/broadcom/bcm2711-rpi-cm4.dtb"
OVERLAY="$DTBS/overlays/reTerminal-overlay.dtbo"

echo '=== Overlay external fixups ==='
fdtget -p "$OVERLAY" /__fixups__ | sort

echo
echo '=== Base DTB exported symbols ==='
fdtget -p "$BASE" /__symbols__ | sort

echo
echo '=== Unresolved external symbols ==='
comm -23 \
  <(fdtget -p "$OVERLAY" /__fixups__ | sort) \
  <(fdtget -p "$BASE" /__symbols__ | sort)

echo
echo '=== Overlay fragment targets ==='
dtc -I dtb -O dts "$OVERLAY" |
  grep -E 'fragment@[0-9]+|target(-path)? ='

echo
echo '=== Base DTB compatible ==='
fdtget -t s "$BASE" / compatible

echo
echo '=== Attempt overlay application ==='
fdtoverlay -i "$BASE" -o /tmp/reterminal-test.dtb "$OVERLAY"
