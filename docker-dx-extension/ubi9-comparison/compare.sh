#!/usr/bin/env bash
set -euo pipefail

# compare.sh – quick comparison of Red Hat UBI images
# ---------------------------------------------------
# Usage: ./compare.sh
# It will:
#   1. Pull the three UBI images (if not present).
#   2. Print their sizes.
#   3. List installed packages and diff them.
#   4. Optionally dump a small filesystem listing.

IMAGES=(
  "registry.access.redhat.com/ubi9:latest"
  "registry.access.redhat.com/ubi9-minimal:latest"
  "registry.access.redhat.com/ubi9-micro:latest"
)

pull_images(){
  echo "Pulling images..."
  for img in "${IMAGES[@]}"; do
    docker pull "$img" > /dev/null
  done
}

size_info(){
  echo -e "\n=== Image Sizes ==="
  for img in "${IMAGES[@]}"; do
    size=$(docker image inspect "$img" | jq -r '.[0].Size')
    # Convert bytes to MB
    mb=$(awk "BEGIN {printf \"%.1f\", $size/1024/1024}")
    echo "$img – $mb MB"
  done
}

list_packages(){
  echo -e "\n=== Package Lists (sorted) ==="
  for img in "${IMAGES[@]}"; do
    tag=$(basename "$img" | cut -d: -f1)
    out="${tag}-packages.txt"
    docker run --rm "$img" rpm -qa | sort > "$out"
    echo "$tag packages saved to $out"
  done
  echo "\nDiff between full and minimal:"
  diff -u ubi9-packages.txt ubi9-minimal-packages.txt || true
  echo "\nDiff between minimal and micro:"
  diff -u ubi9-minimal-packages.txt ubi9-micro-packages.txt || true
}

filesystem_snapshot(){
  echo -e "\n=== Filesystem Snapshots (first 20 entries) ==="
  for img in "${IMAGES[@]}"; do
    tag=$(basename "$img" | cut -d: -f1)
    out="${tag}-fs.txt"
    docker run --rm "$img" tar -c . | tar -tv | head -n 20 > "$out"
    echo "$tag filesystem snapshot saved to $out"
  done
}

main(){
  pull_images
  size_info
  list_packages
  filesystem_snapshot
  echo -e "\nComparison complete. See the *.txt files for details."
}

main "$@"
