# PWN Environment

A modular, maintainable environment for binary exploitation exercises from pwn.college and other sources.

## Overview

This repository contains a Docker-based environment for practicing binary exploitation, memory corruption vulnerabilities, and CTF challenges. It includes all necessary tools and a structured approach to organizing exercises.

## Features

- Complete Docker environment for binary exploitation
- Pre-installed tools (pwndbg, CTFMate, pwntools, etc.)
- Exercise management system with templates
- Support for various exploitation techniques (buffer overflow, ROP, heap, etc.)

## Directory Structure

```
pwn_env/
├── docker/
│   ├── Dockerfile
│   └── config/
├── docker-compose.yml
├── exercises/
│   ├── active/      # Current exercises you're working on
│   └── retired/     # Completed exercises
├── scripts/
│   ├── retire.sh    # Move exercise to retired
│   ├── activate.sh  # Reactivate a retired exercise
│   └── new_exercise.sh # Create a new exercise from template
└── README.md
```

## Installation

1. Run the setup script:
   ```bash
   ./setup.sh
   ```

2. Start the environment:
   ```bash
   docker compose up -d
   ```

3. Access the environment:
   ```bash
   docker exec -it pwn_env zsh
   ```

## Using the Environment

### Creating a New Exercise

```bash
./scripts/new_exercise.sh exercise_name [template]
```

Available templates:
- `basic`: Simple C program
- `buffer_overflow`: Basic buffer overflow vulnerability
- `rop`: Return-oriented programming challenge
- `format_string`: Format string vulnerability
- `heap`: Heap exploitation challenge

### Managing Exercises

To retire (archive) a completed exercise:
```bash
./scripts/retire.sh exercise_name
```

To reactivate a retired exercise:
```bash
./scripts/activate.sh exercise_name
```

## Included Tools

- **GDB with pwndbg**: Enhanced debugging for exploits
- **CTFMate**: CTF exploitation helper
- **pwntools**: Python framework for exploit development
- **Ghidra**: Reverse engineering suite
- **radare2**: Disassembler and binary analysis
- **ROPgadget**: Find gadgets for ROP chains
- **one_gadget**: Find one-gadget RCE in libc

## Learning Resources

- [PWN College](https://pwn.college/): Comprehensive binary exploitation course
- [LiveOverflow](https://www.youtube.com/channel/UClcE-kVhqyiHCcjYwcpfj9w): Excellent YouTube channel for binary exploitation
- [CTF 101](https://ctf101.org/): Introduction to CTF concepts
