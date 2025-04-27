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

python3 -c "
import os
import shutil
import sys

input_dir = sys.argv[1]
output_dir = sys.argv[2]
max_depth = int(sys.argv[3]) if len(sys.argv) > 3 else 0

def copy_with_depth():
    for root, dirs, files in os.walk(input_dir):
        dirs.sort()
        files.sort()
        rel_path = os.path.relpath(root, input_dir)
        if rel_path == '.':
            current_depth = 0
        else:
            current_depth = rel_path.count(os.sep) + 1

        if max_depth > 0 and current_depth > max_depth:
            continue

        for file in files:
            src = os.path.join(root, file)
            base_name = os.path.basename(src)
            dest = os.path.join(output_dir, base_name)

            counter = 1
            while os.path.exists(dest):
                name, ext = os.path.splitext(base_name)
                dest = os.path.join(output_dir, f'{name}_{counter}{ext}')
                counter += 1

            shutil.copy2(src, dest)

copy_with_depth()
" "$input_dir" "$output_dir" "$max_depth"