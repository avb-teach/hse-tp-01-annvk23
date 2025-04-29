#!/bin/bash

check_args() {
    local max_depth=-1
    local input_dir=""
    local output_dir=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max_depth)
                shift
                max_depth=$1
                shift
                ;;
            *)
                if [ -z "$input_dir" ]; then
                    input_dir=$1
                elif [ -z "$output_dir" ]; then
                    output_dir=$1
                else
                    exit 1
                fi
                shift
                ;;
        esac
    done
    mkdir -p "$output_dir"
    
    echo "$input_dir" "$output_dir" "$max_depth"
}

copy_files() {
    local src_dir=$1
    local dst_dir=$2
    local max_depth=$3
    local current_depth=$4
    if [ "$max_depth" -ge 0 ] && [ "$current_depth" -gt "$max_depth" ]; then
        local rel_path=${src_dir#$5/}
        local target_dir="$dst_dir/$rel_path"
        mkdir -p "$target_dir"
        cp -r "$src_dir"/* "$target_dir"/ 2>/dev/null || true
        return
    fi
    for item in "$src_dir"/*; do
        if [ -f "$item" ]; then
            filename=$(basename "$item")
            base=${filename%.*}
            ext=${filename##*.}
            if [ "$base" = "$ext" ]; then
                ext=""
            else
                ext=".$ext"
            fi
            
            counter=1
            target_file="$dst_dir/$base$ext"
            while [ -f "$target_file" ]; do
                target_file="$dst_dir/$base$counter$ext"
                counter=$((counter + 1))
            done
            
            cp "$item" "$target_file"
        elif [ -d "$item" ]; then
            if [ "$max_depth" -ge 0 ] && [ "$current_depth" -ge "$max_depth" ]; then
                local dir_name=$(basename "$item")
                mkdir -p "$dst_dir/$dir_name"                
                copy_files "$item" "$dst_dir" "$max_depth" $((current_depth + 1)) "$5"
            else
                copy_files "$item" "$dst_dir" "$max_depth" $((current_depth + 1)) "$5"
            fi
        fi
    done
}

args=$(check_args "$@")
read input_dir output_dir max_depth <<< "$args"
copy_files "$input_dir" "$output_dir" "$max_depth" 1 "$input_dir"