#!/bin/bash

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 /path/to/input_dir /path/to/output_dir [--max_depth N]"
  exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR=$2
MAX_DEPTH_FLAG=false
MAX_DEPTH=0

if [ "$#" -eq 4 ] && [ "$3" == "--max_depth" ]; then
  MAX_DEPTH_FLAG=true
  MAX_DEPTH=$4
fi

if [ ! -d "$INPUT_DIR" ]; then
  echo "Input directory does not exist."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

python3 - <<EOF
import os
import shutil
import sys

input_dir = "$INPUT_DIR"
output_dir = "$OUTPUT_DIR"
max_depth_flag = $MAX_DEPTH_FLAG
max_depth = int("$MAX_DEPTH")

def copy_files(src_dir, dest_dir, current_depth=0):
    if max_depth_flag and current_depth > max_depth:
        return

    for root, _, files in os.walk(src_dir):
        depth = root[len(src_dir):].count(os.sep)
        if max_depth_flag and depth > max_depth:
            continue

        for file in files:
            src_file = os.path.join(root, file)
            dest_file = os.path.join(dest_dir, file)
            counter = 1
            while os.path.exists(dest_file):
                name, ext = os.path.splitext(file)
                dest_file = os.path.join(dest_dir, f"{name}{counter}{ext}")
                counter += 1

            shutil.copy2(src_file, dest_file)

copy_files(input_dir, output_dir)
EOF