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
            shift
            max_depth="$1"
            shift
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir="$1"
            elif [[ -z "$output_dir" ]]; then
                output_dir="$1"
            else
                echo "Unknown argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Usage: $0 input_dir output_dir [--max_depth=N]" >&2
    exit 1
fi

if [[ ! -d "$input_dir" ]]; then
    echo "Input directory does not exist: $input_dir" >&2
    exit 1
fi

mkdir -p "$output_dir"

python3 - "$input_dir" "$output_dir" "$max_depth" <<'EOF'
import os
import shutil
import sys

input_dir = sys.argv[1]
output_dir = sys.argv[2]
try:
    max_depth = int(sys.argv[3])
except (IndexError, ValueError):
    max_depth = 0

for root, dirs, files in os.walk(input_dir):
    rel_path = os.path.relpath(root, input_dir)
    depth = 0 if rel_path == "." else rel_path.count(os.sep) + 1

    if max_depth > 0 and depth > max_depth:
        dirs.clear()  # Don't go deeper
        continue

    if rel_path != ".":
        dest_dir = os.path.join(output_dir, rel_path)
    else:
        dest_dir = output_dir

    os.makedirs(dest_dir, exist_ok=True)

    for file in files:
        src_file = os.path.join(root, file)
        dest_file = os.path.join(dest_dir, file)

        base, ext = os.path.splitext(file)
        counter = 1
        while os.path.exists(dest_file):
            dest_file = os.path.join(dest_dir, f"{base}_{counter}{ext}")
            counter += 1

        shutil.copy2(src_file, dest_file)
EOF
