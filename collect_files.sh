#!/bin/bash

max_depth=0
input_dir=""
output_dir=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth=*)
            max_depth="${1#*=}"
            shift
            ;;
        --max_depth)
            max_depth="$2"
            shift 2
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir="$1"
            else
                output_dir="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Usage: $0 [--max_depth=N] input_dir output_dir" >&2
    exit 1
fi

if [[ ! -d "$input_dir" ]]; then
    echo "Input directory does not exist" >&2
    exit 1
fi

mkdir -p "$output_dir"

python3 - <<EOF
import os
import shutil
import sys

input_dir = sys.argv[1]
output_dir = sys.argv[2]
max_depth = int(sys.argv[3])

for root, dirs, files in os.walk(input_dir):
    rel_path = os.path.relpath(root, input_dir)
    current_depth = rel_path.count(os.sep)

    if max_depth > 0 and current_depth >= max_depth:
        # Don't go deeper
        dirs.clear()

    target_dir = os.path.normpath(os.path.join(output_dir, rel_path))
    os.makedirs(target_dir, exist_ok=True)

    for file in files:
        src_file = os.path.join(root, file)
        dest_file = os.path.join(target_dir, file)

        base, ext = os.path.splitext(file)
        counter = 1

        # Handle duplicate file names
        while os.path.exists(dest_file):
            dest_file = os.path.join(target_dir, f"{base}_{counter}{ext}")
            counter += 1

        shutil.copy2(src_file, dest_file)
EOF
