#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

INCLUDE_DIR="/usr/local/include/"

LIB_LIST=("SDL3" "SDL3_image" "SDL3_mixer" "SDL3_ttf")
LIB_EXISTS=()

SELECTED=()

# Check if a library exists in the include directory
lib_exists() {
  local lib_name=$1
  if [ -d "${INCLUDE_DIR}${lib_name}" ]; then
    return 0
  else
    return 1
  fi
}

# Display available libraries and handle user selection
lib_selection() {
  for lib in "${LIB_LIST[@]}"; do
      if lib_exists "$lib"; then
        LIB_EXISTS+=("$lib")
      fi
  done
  echo -e "${BLUE}Here are all the SDL libraries installed on your system:${NC}"
  for i in "${!LIB_EXISTS[@]}"; do
    echo -e "${GREEN}$((i+1)). ${LIB_EXISTS[$i]}${NC}"
  done
  SIZE=${#LIB_EXISTS[@]}
  if [ $SIZE -eq 0 ]; then
    echo -e "${RED}No SDL libraries found. Please install at least SDL3.${NC}"
    exit 1
  fi
  echo -e "${BLUE}Select the libraries to include in the CMake file by numbers"
  echo -e "You can type 'all' to include all libraries.${NC}"
  read -p "Your selection: " SELECTION
  if [ "$SELECTION" == "all" ]; then
    for i in "${!LIB_EXISTS[@]}"; do
      SELECTED+=("$i")
    done
    return 0
  fi

  read -ra choices <<< "$SELECTION"
  for choice in "${choices[@]}"; do
    if ! [[ "$choice" =~ ^[1-$((SIZE))]$ ]]; then
      echo -e "${RED}Invalid selection: $choice. Please select valid numbers.${NC}"
      exit 1
    fi
    if [[ ! " ${SELECTED[*]} " =~ " $choice " ]]; then
          SELECTED+=("$choice")
    fi
  done
}

# Create the CMakeLists.txt file
create_cmake_file() {
  local project_dir=$1
  local project_name=$2
  local c_version=$3
  local cmake_file="${project_dir}/CMakeLists.txt"
  echo -e "${BLUE}Creating CMakeLists.txt in ${project_dir}${NC}"
  {
    echo "cmake_minimum_required(VERSION 4.0)"
    echo "project(${project_name} C)"
    echo "set(CMAKE_C_STANDARD ${c_version})"
    echo ""

    for index in "${SELECTED[@]}"; do
      lib="${LIB_EXISTS[$index]}"
      echo "find_package(${lib} REQUIRED)"
    done
    echo ""
    echo "add_executable(${PROJECT_NAME} main.c)"
    echo ""
    for index in "${SELECTED[@]}"; do
      lib="${LIB_EXISTS[$index]}"
      echo "target_link_libraries(${PROJECT_NAME} PRIVATE ${lib}::${lib})"
    done
  } > "$cmake_file"
  echo -e "${GREEN}CMakeLists.txt created successfully at ${cmake_file}${NC}"
}

echo -e "${BLUE}=======SDL CMake File Creator=======${NC}"

read -p "Enter the project directory path (default is current directory): " PROJECT_DIR
PROJECT_DIR=${PROJECT_DIR:-$(pwd)}
if [ ! -d "$PROJECT_DIR" ]; then
  echo -e "${RED}Directory does not exist. Please create it first.${NC}"
  exit 1
fi
echo -e "${GREEN}Using project directory: ${PROJECT_DIR}${NC}"

read -p "Enter the project name: " PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}Project name cannot be empty. Exiting...${NC}"
  exit 1
fi

read -p "Enter the C Version (default is 11): " C_VERSION
C_VERSION=${C_VERSION:-11}

lib_selection
echo -e "${BLUE} You have selected the following libraries:${NC}"
for index in "${SELECTED[@]}"; do
  echo -e "${GREEN}- ${LIB_EXISTS[$index]}${NC}"
done

read -p "Proceed to create CMakeLists.txt? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[oOyY]$ ]]; then
  echo -e "${RED}Operation cancelled by user. Exiting...${NC}"
  exit 1
fi

create_cmake_file "$PROJECT_DIR" "$PROJECT_NAME" "$C_VERSION"

