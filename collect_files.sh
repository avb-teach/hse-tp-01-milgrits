#!/bin/bash

max_depth=0
input_dir=""
output_dir=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max_depth)
            max_depth="$2"
            if [[ ! "$max_depth" =~ ^[0-9]+$ ]]; then
                echo "Error: max_depth must be a positive integer" >&2
                exit 1
            fi
            shift 2
            ;;
        --max_depth=*)
            max_depth="${1#*=}"
            if [[ ! "$max_depth" =~ ^[0-9]+$ ]]; then
                echo "Error: max_depth must be a positive integer" >&2
                exit 1
            fi
            shift
            ;;
        *)
            if [[ -z "$input_dir" ]]; then
                input_dir="$1"
            elif [[ -z "$output_dir" ]]; then
                output_dir="$1"
            else
                echo "Error: Too many arguments" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
    echo "Usage: $0 [--max_depth N] input_dir output_dir" >&2
    exit 1
fi

if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory '$input_dir' does not exist" >&2
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

def copy_file(src, dst_dir):
    base = os.path.basename(src)
    dst_path = os.path.join(dst_dir, base)
    counter = 1

    while os.path.exists(dst_path):
        name, ext = os.path.splitext(base)
        dst_path = os.path.join(dst_dir, f'{name}_{counter}{ext}')
        counter += 1

    shutil.copy2(src, dst_path)

def process_dir(current_dir, current_depth):
    try:
        for item in os.listdir(current_dir):
            path = os.path.join(current_dir, item)
            if os.path.isfile(path):
                copy_file(path, output_dir)
            elif os.path.isdir(path):
                if max_depth == 0 or current_depth < max_depth:
                    process_dir(path, current_depth + 1)
    except Exception as e:
        print(f'Error: {str(e)}', file=sys.stderr)
        sys.exit(1)

try:
    process_dir(input_dir, 0)
except KeyboardInterrupt:
    sys.exit(1)
" "$input_dir" "$output_dir" "$max_depth"

exit 0