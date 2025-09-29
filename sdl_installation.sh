#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

INCLUDE_DIR="/usr/local/include/"
LIB_DIR="/usr/local/lib/"
CONFIG_DIR="/usr/local/lib/cmake/"

OPTIONS=("SDL3" "SDL3_image" "SDL3_mixer" "SDL3_ttf")
SELECTED=()

TEMP_DIR=$(mktemp -d)

# Function to clean up temporary directory on exit
cleanup() {
  if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

trap cleanup EXIT

# Check if a library exists in the include directory
lib_exists() {
  local lib_name=$1
  if [ -d "${INCLUDE_DIR}${lib_name}" ]; then
    return 0
  else
    return 1
  fi
}

# Display menu
show_menu() {
  echo "Select the SDL components to install:"
  echo "Select the components by numbers (e.g., 1 3 for SDL3 and SDL3_mixer)"
  echo "Or type 'all' to select all components."
  echo "Type 'clean' to remove all installed SDL components."
  echo "Type 'verify' to check installed components."
  echo "Type 'quit' or 'q' to exit the program."
  for i in "${!OPTIONS[@]}"; do
    echo "$((i+1)). ${OPTIONS[$i]}"
  done
  echo ""
}

# Clean up installed libraries
clean_installations() {
  echo -e "${BLUE}Cleaning installed SDL Lib...${NC}"
  for lib in "${OPTIONS[@]}"; do
    if lib_exists "$lib"; then
      echo -e "${BLUE}Removing ${lib}...${NC}"
      sudo rm -rf "${INCLUDE_DIR}${lib}"
      sudo rm -rf ${LIB_DIR}lib${lib}.*
      if [[ "$lib" == "SDL3" ]]; then
        sudo rm -rf ${LIB_DIR}libSDL3_test.*
      fi
      sudo rm -rf "${CONFIG_DIR}${lib}"
      echo -e "${GREEN}${lib} removed successfully.${NC}"
    else
      echo -e "${RED}${lib} is not installed. Skipping...${NC}"
    fi
  done
  echo -e "${GREEN}Cleanup finished.${NC}"
}

# Verify installed libraries
verify_installations() {
  echo -e "${BLUE}Verifying installed SDL Lib...${NC}"
  for lib in "${OPTIONS[@]}"; do
    if lib_exists "$lib"; then
      echo -e "${GREEN}${lib} is installed.${NC}"
    else
      echo -e "${RED}${lib} is not installed.${NC}"
    fi
  done
}

# Validate user selection
validate_selection() {
  local input=$1
  if [[ "$input" == "all" ]]; then
    SELECTED=(1 2 3 4)
    return 0
  fi

  if [[ "$input" == "quit" || "$input" == "q" ]]; then
    echo -e "${GREEN}Exiting the installation program.${NC}"
    exit 0
  fi

  if [[ "$input" == "clean" ]]; then
    clean_installations
    exit 0
  fi

  if [[ "$input" == "verify" ]]; then
    verify_installations
    exit 0
  fi

  read -ra choices <<< "$input"

  if [ ${#choices[@]} -eq 0 ]; then
    echo -e "${RED}No selection made. Please select at least one component.${NC}"
    return 1
  fi

  for choice in "${choices[@]}"; do
    if ! [[ "$choice" =~ ^[1-4]$ ]]; then
      echo -e "${RED}Invalid selection: $choice. Please select numbers between 1 and 4.${NC}"
      return 1
    fi
    if lib_exists "${OPTIONS[$((choice-1))]}"; then
      echo -e "${RED}${OPTIONS[$((choice-1))]} is already installed. Please select another component.${NC}"
      return 1
    fi
    if [[ ! " ${SELECTED[*]} " =~ " $choice " ]]; then
      SELECTED+=("$choice")
    fi
  done

  return 0
}

# Install selected library
install_lib() {
  local lib_name=$1
  if lib_exists "$lib_name"; then
    echo -e "${RED}${lib_name} is already installed. Skipping...${NC}"
    return
  fi
  echo -e "${BLUE}Installing ${lib_name}...${NC}"
  lib_name="${lib_name/3/}"
  GIT_URL="https://github.com/libsdl-org/${lib_name}.git"
  cd "$TEMP_DIR"
  if ! git clone "$GIT_URL"; then
    echo -e "${RED}Failed to clone ${lib_name} repository.${NC}"
    exit 1
  fi
  cd "$lib_name"
  mkdir build && cd build
  if ! cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local; then
    echo -e "${RED}CMake configuration failed for ${lib_name}.${NC}"
    exit 1
  fi
  if ! make -j"$(sysctl -n hw.ncpu)"; then
    echo -e "${RED}Build failed for ${lib_name}.${NC}"
    exit 1
  fi
  if ! sudo make install; then
    echo -e "${RED}Installation failed for ${lib_name}.${NC}"
    exit 1
  fi
  echo -e "${GREEN}${lib_name} installed successfully.${NC}"
}

# Check if Git is installed
if ! command -v git >/dev/null 2>&1; then
  echo -e "${RED}Git is not installed. Please install Git and try again.${NC}"
  exit 1
fi

# Check if CMake is installed
if ! command -v cmake >/dev/null 2>&1; then
  echo -e "${RED}CMake is not installed. Please install CMake and try again.${NC}"
  exit 1
fi

echo -e "${BLUE}=======Shell SDL Installation Program=======${NC}"

while true; do

  while true; do
    show_menu
    read -p "Enter your choice: " user_input
    if validate_selection "$user_input"; then
      break
    fi
    echo ""
  done

  IFS=$'\n' SELECTED=($(sort -n <<<"${SELECTED[*]}"))
  unset IFS

  echo -e "${BLUE} You have selected the following components for installation:${NC}"
  for choice in "${SELECTED[@]}"; do
    echo -e "${GREEN}- ${OPTIONS[$((choice-1))]}${NC}"
  done

  echo ""
  read -p "Do you want to proceed with the installation? (y/n): " confirm
  if [[ ! "$confirm" =~ ^[oOyY]$ ]]; then
      echo -e "${RED}Cancelling${NC}"
      exit 0
  fi

  echo -e "${BLUE}Starting installation...${NC}"

  for choice in "${SELECTED[@]}"; do
    install_lib "${OPTIONS[$((choice-1))]}"
  done

  echo -e "${GREEN}All selected components have been installed successfully.${NC}"
  echo -e "${GREEN}Thank you for using the SDL Installation Program!${NC}"
  cleanup

  read -p "Do you want to quit the program? (y/n): " exit_choice
  if [[ "$exit_choice" =~ ^[oOyY]$ ]]; then
    echo -e "${GREEN}Exiting the installation program.${NC}"
    break
  fi
done