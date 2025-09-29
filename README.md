# MacOS-SDL-Install-Script

This repository contains one scripts to help you install SDL3, SDL3_image, SDL3_mixer and SDL3_ttf on macOS without using Homebrew.

The other scripts create a basic CMakeFile to compile a simple SDL3 program.

## Usage

### Install SDL3 and its dependencies

#### With git clone
You can clone the repository and run the installation script as follows:

```bash
git clone https://github.com/TorisutanKholwes/MacOS-SDL-Install-Script.git
cd MacOS-SDL-Install-Script
bash sdl_installation.sh
```

#### With curl

You can also download and run the installation script directly using curl:
```bash
curl -fsSL https://raw.githubusercontent.com/TorisutanKholwes/MacOS-SDL-Install-Script/refs/heads/main/sdl_installation.sh -o script.sh
chmod +x script.sh
bash ./script.sh
```

When on the script, you can choose to install the SDL3 libs, check which libs are already installed and uninstall them.

### Create a CMakeFile for a simple SDL3 program

#### With git clone
First, clone the repository:
```bash
git clone https://github.com/TorisutanKholwes/MacOS-SDL-Install-Script.git
cd MacOS-SDL-Install-Script
bash cmake_file.sh
```

#### With curl
You can also download and run the CMake file creation script directly using curl:
```bash
curl -fsSL https://raw.githubusercontent.com/TorisutanKholwes/MacOS-SDL-Install-Script/refs/heads/main/cmake_file.sh -o script.sh
chmod +x script.sh
bash ./script.sh
```

This script will create a `CMakeLists.txt` file in the directory prompted by you and will include all the SDL libraries you want to use in your project.

## Requirements

- A macOS system
- Git
- CMake