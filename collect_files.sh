#!/bin/bash
max_depth=0
input_dir=""
output_dir=""

while [[ $# -gt 0 ]]; do
    case "$1" in
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
    echo "Usage: $0 [--max_depth=N] input_dir output_dir" >&2
    exit 1
fi

if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory does not exist" >&2
    exit 1
fi

mkdir -p "$output_dir"

python3 -c "
import sys
import os
import shutil

def main():
    input_dir = sys.argv[1]
    output_dir = sys.argv[2]
    max_depth = int(sys.argv[3]) if sys.argv[3] else 0

    if max_depth == 0:
        max_depth = float('inf')

    def copy_file(src_path):
        base_name = os.path.basename(src_path)
        dest_path = os.path.join(output_dir, base_name)

        counter = 1
        name, ext = os.path.splitext(base_name)
        while os.path.exists(dest_path):
            new_name = f"{name}_{counter}{ext}"
            dest_path = os.path.join(output_dir, new_name)
            counter += 1

        shutil.copy2(src_path, dest_path)

    for root, _, files in os.walk(input_dir):
        current_depth = root[len(input_dir):].count(os.sep)
        if current_depth > max_depth:
            continue

        for file in files:
            src_path = os.path.join(root, file)
            copy_file(src_path)

if __name__ == "__main__":
    main()
END_PYTHON

exit 0