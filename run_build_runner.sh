#!/bin/bash

# Main project directory
MAIN_PROJECT_DIR=$(pwd)

# Function to run build_runner commands
invoke_build_runner() {
    local dir=$1
    local name=$2
    
    echo -e "\033[0;36mProcessing $name at $dir\033[0m"
    cd "$dir" || return

    # json_serializable >=6.9 emits null-aware-elements (requires Dart >=3.8).
    # The submodule/project may declare a lower minimum; bump it so the generator proceeds.
    if [ -f "pubspec.yaml" ]; then
        sed -i 's/sdk: ">=3\.0\.0 <4\.0\.0"/sdk: ">=3.8.0 <4.0.0"/' "pubspec.yaml"
    fi

    echo -e "\033[0;32mRunning 'flutter pub get' for $name\033[0m"
    flutter pub get

    echo -e "\033[0;32mRunning 'dart run build_runner clean' for $name\033[0m"
    dart run build_runner clean

    echo -e "\033[0;32mRunning 'dart run build_runner build --delete-conflicting-outputs' for $name\033[0m"
    dart run build_runner build --delete-conflicting-outputs
}

# Extract submodule paths from .gitmodules
if [ -f .gitmodules ]; then
    # Extracts the path value from lines like "submodule.path.name value"
    submodule_paths=$(git config --file .gitmodules --get-regexp '\.path$' | sed 's/^[^ ]* //')
else
    submodule_paths=""
fi

# Run build_runner for each submodule
if [ -n "$submodule_paths" ]; then
    for submodule_dir_name in $submodule_paths; do
        submodule_path="$MAIN_PROJECT_DIR/$submodule_dir_name"
        if [ -d "$submodule_path" ]; then
            invoke_build_runner "$submodule_path" "submodule $submodule_dir_name"
        else
            echo -e "\033[0;33mSubmodule path $submodule_path not found, skipping.\033[0m"
        fi
    done
fi

# Clean and then run build_runner for the main project
cd "$MAIN_PROJECT_DIR" || exit
echo -e "\033[0;33mRunning 'flutter clean' for the main project before build\033[0m"
flutter clean

# Run build_runner for the main project
invoke_build_runner "$MAIN_PROJECT_DIR" "main project"
