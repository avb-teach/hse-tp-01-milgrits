#!/bin/bash

if ! command -v python3 &> /dev/null; then
    echo "Ошибка: Python3 не установлен" >&2
    exit 1
fi

max_depth=0
input_dir=""
output_dir=""

if [[ "$1" == --max_depth=* ]]; then
    max_depth="${1#--max_depth=}"
    if [[ ! "$max_depth" =~ ^[0-9]+$ ]]; then
        echo "Ошибка: значение max_depth должно быть целым числом" >&2
        exit 1
    fi
    shift
fi

if [[ $# -ne 2 ]]; then
    echo "Использование: $0 [--max_depth=N] исходная_директория целевая_директория" >&2
    exit 1
fi

input_dir="$1"
output_dir="$2"

if [[ ! -d "$input_dir" ]]; then
    echo "Ошибка: исходная директория не существует" >&2
    exit 1
fi

mkdir -p "$output_dir"

python3 - "$input_dir" "$output_dir" "$max_depth" <<'END_PYTHON'
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