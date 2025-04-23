#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "██████╗ ██╗    ██╗███╗   ██╗    ███████╗███╗   ██╗██╗   ██╗"
echo "██╔══██╗██║    ██║████╗  ██║    ██╔════╝████╗  ██║██║   ██║"
echo "██████╔╝██║ █╗ ██║██╔██╗ ██║    █████╗  ██╔██╗ ██║██║   ██║"
echo "██╔═══╝ ██║███╗██║██║╚██╗██║    ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝"
echo "██║     ╚███╔███╔╝██║ ╚████║    ███████╗██║ ╚████║ ╚████╔╝ "
echo "╚═╝      ╚══╝╚══╝ ╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═══╝  ╚═══╝  "
echo -e "${NC}"
echo -e "${GREEN}Setting up your PWN environment for binary exploitation...${NC}"
echo

# Check if Docker is installed
echo -e "${YELLOW}Checking if Docker is installed...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Would you like to install it? (y/N)${NC}"
    read -r install_docker
    if [[ "$install_docker" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${YELLOW}Installing Docker...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker "$USER"
        echo -e "${GREEN}Docker installed. You may need to log out and back in for group changes to take effect.${NC}"
    else
        echo -e "${RED}Docker is required. Please install Docker and run this script again.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}Docker is installed.${NC}"

# Create directory structure
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p docker
mkdir -p docker/config
mkdir -p exercises/active
mkdir -p exercises/retired
mkdir -p scripts
mkdir -p tools/config
mkdir -p tools/bin

# Create GDB configuration
echo -e "${YELLOW}Creating GDB configuration...${NC}"
cat > docker/config/gdbinit << 'EOF'
set disassembly-flavor intel
set follow-fork-mode child
set backtrace past-main on
set print pretty on
set history save on
set confirm off

# Load pwndbg
source /opt/pwndbg/gdbinit.py

# Customize pwndbg
set context-code-lines 15
set context-source-code-lines 15
set context-sections "regs disasm code stack backtrace"

# Define useful functions
define xinfo
  info proc mappings
end
document xinfo
  Print memory mappings for the current process
end

define ropgadget
  shell ROPgadget --binary $arg0
end
document ropgadget
  Find ROP gadgets in a binary using ROPgadget
  Usage: ropgadget binary_path
end

define checksec
  shell checksec --file=$arg0
end
document checksec
  Check security features of a binary
  Usage: checksec binary_path
end

# Hook for binary load
define hook-file
  echo Loading binary...\n
  checksec $arg0
end
EOF

# Create Vim configuration
echo -e "${YELLOW}Creating Vim configuration...${NC}"
cat > docker/config/vimrc << 'EOF'
syntax on
set number
set relativenumber
set autoindent
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab
set hlsearch
set incsearch
set ignorecase
set smartcase
set showcmd
set showmatch
set showmode
set history=1000
set wildmenu
set wildmode=list:longest
set backspace=indent,eol,start
set ruler
set laststatus=2
set encoding=utf8
set fileformats=unix,dos,mac
set background=dark
set title

" Enable specific settings for Python files
autocmd FileType python setlocal tabstop=4 shiftwidth=4 expandtab

" Enable specific settings for C/C++ files
autocmd FileType c,cpp setlocal tabstop=2 shiftwidth=2 expandtab

" Color 80th column for better code formatting
set colorcolumn=80
highlight ColorColumn ctermbg=235 guibg=#2c2d27

" Highlight trailing whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
EOF

# Create Dockerfile
echo -e "${YELLOW}Creating Dockerfile...${NC}"
cat > docker/Dockerfile << 'EOF'
FROM debian:latest

LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Binary Exploitation Environment for CTF and Course Exercises"

# Avoid prompts during package installations
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /pwn

# Install essential packages
RUN apt update && apt install -y \
    build-essential \
    python3 \
    python3-pip \
    python3-dev \
    git \
    wget \
    curl \
    gdb \
    gcc-multilib \
    g++-multilib \
    nasm \
    netcat-openbsd \
    ltrace \
    strace \
    binutils \
    file \
    openssh-client \
    lsb-release \
    ruby \
    ruby-dev \
    rubygems \
    libc6-dbg \
    libffi-dev \
    libssl-dev \
    zsh \
    unzip \
    vim \
    tmux \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Set up locale
RUN apt update && apt install -y locales && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install checksec properly
RUN git clone https://github.com/slimm609/checksec.sh.git /opt/checksec && \
    cd /opt/checksec && \
    if [ -f "checksec" ]; then \
        ln -sf /opt/checksec/checksec /usr/local/bin/checksec; \
    else \
        echo "Checksec script not found in expected location"; \
        find /opt/checksec -name "checksec*" -type f -executable | head -1 | xargs -I{} ln -sf {} /usr/local/bin/checksec; \
    fi && \
    chmod +x $(readlink -f /usr/local/bin/checksec)

# Install Python packages in a virtual environment
RUN apt update && apt install -y python3-venv python3-pip && \
    python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip3 install --no-cache-dir pwntools capstone unicorn keystone-engine ropper z3-solver angr r2pipe prompt_toolkit ipython pygments numpy matplotlib scapy requests pycryptodome

# Add the virtual environment to PATH
ENV PATH="/opt/venv/bin:${PATH}"


# Install pwndbg
RUN git clone https://github.com/pwndbg/pwndbg.git /opt/pwndbg \
    && cd /opt/pwndbg \
    && ./setup.sh

# Install Ghidra
RUN mkdir -p /opt/ghidra && \
    wget -q -O /tmp/ghidra.zip https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_10.3.2_build/ghidra_10.3.2_PUBLIC_20230711.zip && \
    unzip /tmp/ghidra.zip -d /opt && \
    rm /tmp/ghidra.zip && \
    mv /opt/ghidra_* /opt/ghidra

# Set up SSH directory for Git access
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Install CTFMate directly
RUN git clone https://github.com/X3eRo0/CTFMate.git /opt/CTFMate && \
    chmod +x /opt/CTFMate/ctfmate.py && \
    ln -s /opt/CTFMate/ctfmate.py /usr/local/bin/ctfmate && \
    chmod +x /usr/local/bin/ctfmate

# Install radare2
RUN git clone https://github.com/radareorg/radare2.git /opt/radare2 \
    && cd /opt/radare2 \
    && sys/install.sh

# Install one_gadget
RUN gem install one_gadget

# Install ROPgadget
RUN pip3 install --no-cache-dir ROPgadget

# Setup gdb with pwndbg
COPY config/gdbinit /root/.gdbinit

# Setup vim configuration
COPY config/vimrc /root/.vimrc

# Set up zsh as default shell with oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    && chsh -s $(which zsh)

# Add custom tools directory to PATH
ENV PATH="/pwn/tools/bin:${PATH}"

# Create necessary directories
RUN mkdir -p /pwn/exercises/active /pwn/exercises/retired /pwn/tools/bin

# Set bash as default shell for compatibility
SHELL ["/bin/bash", "-c"]

# Keep container running
ENTRYPOINT ["/bin/zsh"]
EOF

echo "Rebuilding with fixed Dockerfile..."
docker compose build
docker compose up -d

# Create docker-compose.yml
echo -e "${YELLOW}Creating docker-compose.yml...${NC}"
cat > docker-compose.yml << 'EOF'
services:
  pwn_env:
    build:
      context: ./docker
      dockerfile: Dockerfile
    container_name: pwn_env
    security_opt:
      - seccomp:unconfined  # Needed for debugging with gdb
    cap_add:
      - SYS_PTRACE  # Required for debugging
    volumes:
      - ./exercises:/pwn/exercises
      - ./tools:/pwn/tools
      - ./scripts:/pwn/scripts
    ports:
      - "1337:1337"  # Common port for pwn challenges
    environment:
      - DISPLAY=${DISPLAY}  # For GUI applications if needed
    tty: true
    stdin_open: true
    restart: unless-stopped
    networks:
      - pwn_network

networks:
  pwn_network:
    driver: bridge
EOF

# Create retire.sh script
echo -e "${YELLOW}Creating retire.sh script...${NC}"
cat > scripts/retire.sh << 'EOF'
#!/bin/bash

# Script to move an exercise from active to retired

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 exercise_name"
    exit 1
fi

EXERCISE_NAME="$1"
ACTIVE_DIR="exercises/active"
RETIRED_DIR="exercises/retired"

if [ ! -d "$ACTIVE_DIR/$EXERCISE_NAME" ]; then
    echo "Error: Exercise $EXERCISE_NAME does not exist in active directory."
    exit 1
fi

# Create retired directory if it doesn't exist
mkdir -p "$RETIRED_DIR"

# Add timestamp to README.md
if [ -f "$ACTIVE_DIR/$EXERCISE_NAME/README.md" ]; then
    echo -e "\n## Completed\nRetired on: $(date)" >> "$ACTIVE_DIR/$EXERCISE_NAME/README.md"
fi

# Move the exercise
mv "$ACTIVE_DIR/$EXERCISE_NAME" "$RETIRED_DIR/"

echo "Exercise $EXERCISE_NAME has been retired."
echo "You can activate it again with: ./scripts/activate.sh $EXERCISE_NAME"
EOF
chmod +x scripts/retire.sh

# Create activate.sh script
echo -e "${YELLOW}Creating activate.sh script...${NC}"
cat > scripts/activate.sh << 'EOF'
#!/bin/bash

# Script to move an exercise from retired to active

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 exercise_name"
    exit 1
fi

EXERCISE_NAME="$1"
ACTIVE_DIR="exercises/active"
RETIRED_DIR="exercises/retired"

if [ ! -d "$RETIRED_DIR/$EXERCISE_NAME" ]; then
    echo "Error: Exercise $EXERCISE_NAME does not exist in retired directory."
    exit 1
fi

# Create active directory if it doesn't exist
mkdir -p "$ACTIVE_DIR"

# Add reactivation note to README.md
if [ -f "$RETIRED_DIR/$EXERCISE_NAME/README.md" ]; then
    echo -e "\n## Reactivated\nReactivated on: $(date)" >> "$RETIRED_DIR/$EXERCISE_NAME/README.md"
fi

# Move the exercise
mv "$RETIRED_DIR/$EXERCISE_NAME" "$ACTIVE_DIR/"

echo "Exercise $EXERCISE_NAME has been activated."
echo "You can retire it again with: ./scripts/retire.sh $EXERCISE_NAME"
EOF
chmod +x scripts/activate.sh

# Create new_exercise.sh script
echo -e "${YELLOW}Creating new_exercise.sh script...${NC}"
cat > scripts/new_exercise.sh << 'EOF'
#!/bin/bash

# Script to create a new exercise

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 exercise_name [template]"
    echo "Templates: basic, buffer_overflow, rop, format_string, heap"
    exit 1
fi

EXERCISE_NAME="$1"
TEMPLATE="${2:-basic}"
ACTIVE_DIR="exercises/active"

# Check if exercise already exists
if [ -d "$ACTIVE_DIR/$EXERCISE_NAME" ]; then
    echo "Error: Exercise $EXERCISE_NAME already exists."
    exit 1
fi

# Create exercise directory
mkdir -p "$ACTIVE_DIR/$EXERCISE_NAME"

# Create README.md
cat > "$ACTIVE_DIR/$EXERCISE_NAME/README.md" << EOL
# $EXERCISE_NAME

## Description
Brief description of the exercise goes here.

## Objective
What the student needs to accomplish.

## Hints
- Hint 1
- Hint 2

## Solution
Brief explanation of the solution approach.

## Created
Date: $(date)
Template: $TEMPLATE
EOL

# Based on template, create additional files
case "$TEMPLATE" in
    basic)
        # Create a simple challenge.c file
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/challenge.c" << EOL
#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("Hello, pwn!\n");
    return 0;
}
EOL
        ;;
        
    buffer_overflow)
        # Create a buffer overflow challenge
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/challenge.c" << EOL
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void win() {
    printf("Congratulations! You've successfully exploited the buffer overflow vulnerability.\n");
    system("/bin/sh");
}

void vulnerable_function() {
    char buffer[64];
    gets(buffer);
    printf("You entered: %s\n", buffer);
}

int main() {
    printf("Enter some text: ");
    vulnerable_function();
    return 0;
}
EOL
        # Create a Makefile
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/Makefile" << EOL
CC = gcc
CFLAGS = -fno-stack-protector -no-pie -z execstack

all: challenge

challenge: challenge.c
	\$(CC) \$(CFLAGS) -o challenge challenge.c

clean:
	rm -f challenge
EOL
        # Create an exploit template
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/exploit.py" << EOL
#!/usr/bin/env python3
from pwn import *
import ctfmate

# Set up the environment
context.arch = 'amd64'
context.terminal = ['tmux', 'splitw', '-h']

# Choose local or remote target
LOCAL = True
if LOCAL:
    p = process('./challenge')
    if args.GDB:
        gdb.attach(p, '''
        break win
        break main
        continue
        ''')
else:
    p = remote('localhost', 1337)

# Exploit
payload = b'A' * 64  # Padding
payload += b'B' * 8   # Saved RBP
payload += p64(0x00000000004011xx)  # Address of win function

# Send the payload
p.sendlineafter(b'Enter some text: ', payload)

# Get the shell
p.interactive()
EOL
        chmod +x "$ACTIVE_DIR/$EXERCISE_NAME/exploit.py"
        ;;
        
    rop)
        # Create a ROP challenge
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/challenge.c" << EOL
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

void read_input() {
    char buffer[64];
    read(0, buffer, 200);
}

int main() {
    printf("ROP Challenge - Can you get a shell?\n");
    read_input();
    return 0;
}
EOL
        # Create a Makefile
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/Makefile" << EOL
CC = gcc
CFLAGS = -fno-stack-protector -no-pie

all: challenge

challenge: challenge.c
	\$(CC) \$(CFLAGS) -o challenge challenge.c

clean:
	rm -f challenge
EOL
        # Create an exploit template
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/exploit.py" << EOL
#!/usr/bin/env python3
from pwn import *
import ctfmate

# Set up the environment
context.arch = 'amd64'
context.terminal = ['tmux', 'splitw', '-h']

# Choose local or remote target
LOCAL = True
if LOCAL:
    p = process('./challenge')
    elf = ELF('./challenge')
    libc = ELF('/lib/x86_64-linux-gnu/libc.so.6')  # Adjust path as needed
    if args.GDB:
        gdb.attach(p, '''
        break main
        continue
        ''')
else:
    p = remote('localhost', 1337)
    elf = ELF('./challenge')
    libc = ELF('./libc.so.6')  # Provided libc

# ROP chain
rop = ROP(elf)
# Add your ROP gadgets here

# Exploit
payload = b'A' * 72  # Padding
payload += rop.chain()

# Send the payload
p.recvuntil(b'Can you get a shell?\n')
p.send(payload)

# Get the shell
p.interactive()
EOL
        chmod +x "$ACTIVE_DIR/$EXERCISE_NAME/exploit.py"
        ;;
        
    format_string)
        # Create a format string challenge
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/challenge.c" << EOL
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int secret = 0;

void win() {
    if (secret == 0x1337) {
        printf("Congratulations! You've successfully exploited the format string vulnerability.\n");
        system("/bin/sh");
    } else {
        printf("Nice try, but secret is %d, not 0x1337.\n", secret);
    }
}

int main() {
    char buffer[100];
    
    printf("Enter format string: ");
    fgets(buffer, sizeof(buffer), stdin);
    printf(buffer);  // Format string vulnerability!
    
    printf("Secret value: %d\n", secret);
    printf("Can you change it to 0x1337?\n");
    
    printf("Try again: ");
    fgets(buffer, sizeof(buffer), stdin);
    printf(buffer);  // Format string vulnerability!
    
    win();
    return 0;
}
EOL
        # Create a Makefile
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/Makefile" << EOL
CC = gcc
CFLAGS = -fno-stack-protector -no-pie

all: challenge

challenge: challenge.c
	\$(CC) \$(CFLAGS) -o challenge challenge.c

clean:
	rm -f challenge
EOL
        # Create an exploit template
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/exploit.py" << EOL
#!/usr/bin/env python3
from pwn import *
import ctfmate

# Set up the environment
context.arch = 'amd64'
context.terminal = ['tmux', 'splitw', '-h']

# Choose local or remote target
LOCAL = True
if LOCAL:
    p = process('./challenge')
    if args.GDB:
        gdb.attach(p, '''
        break main
        continue
        ''')
else:
    p = remote('localhost', 1337)

# Get address of secret variable
# You can use: objdump -t challenge | grep secret

# Exploit format string vulnerability
p.recvuntil(b'Enter format string: ')
payload1 = b'%p %p %p %p'  # Example to leak addresses
p.sendline(payload1)

# Parse the output
p.recvuntil(b'Try again: ')

# Send format string to change secret value to 0x1337 (4919)
payload2 = f'%4919c%10$n'.encode()  # Adjust the offset as needed
p.sendline(payload2)

# Get the shell
p.interactive()
EOL
        chmod +x "$ACTIVE_DIR/$EXERCISE_NAME/exploit.py"
        ;;
        
    heap)
        # Create a heap exploitation challenge
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/challenge.c" << EOL
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

struct chunk {
    char data[32];
};

struct chunk *chunks[10];
int chunk_count = 0;

void win() {
    printf("Congratulations! You've successfully exploited the heap vulnerability.\n");
    system("/bin/sh");
}

void add_chunk() {
    if (chunk_count >= 10) {
        printf("Maximum number of chunks reached.\n");
        return;
    }
    
    chunks[chunk_count] = malloc(sizeof(struct chunk));
    if (!chunks[chunk_count]) {
        printf("Malloc failed.\n");
        return;
    }
    
    printf("Chunk %d created. Enter data: ", chunk_count);
    read(0, chunks[chunk_count]->data, 40); // Overflow!
    
    chunk_count++;
}

void delete_chunk() {
    int index;
    printf("Enter chunk index to delete: ");
    scanf("%d", &index);
    
    if (index < 0 || index >= chunk_count || !chunks[index]) {
        printf("Invalid index.\n");
        return;
    }
    
    free(chunks[index]);
    // Use-after-free vulnerability! We don't set chunks[index] to NULL
}

void view_chunk() {
    int index;
    printf("Enter chunk index to view: ");
    scanf("%d", &index);
    
    if (index < 0 || index >= chunk_count || !chunks[index]) {
        printf("Invalid index.\n");
        return;
    }
    
    printf("Chunk %d data: %s\n", index, chunks[index]->data);
}

void menu() {
    printf("\n--- Heap Challenge Menu ---\n");
    printf("1. Add chunk\n");
    printf("2. Delete chunk\n");
    printf("3. View chunk\n");
    printf("4. Exit\n");
    printf("Choice: ");
}

int main() {
    int choice;
    
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stdin, NULL, _IONBF, 0);
    
    printf("Heap Exploitation Challenge\n");
    
    while (1) {
        menu();
        scanf("%d", &choice);
        getchar(); // Consume newline
        
        switch (choice) {
            case 1:
                add_chunk();
                break;
            case 2:
                delete_chunk();
                break;
            case 3:
                view_chunk();
                break;
            case 4:
                printf("Goodbye!\n");
                return 0;
            default:
                printf("Invalid choice.\n");
        }
    }
    
    return 0;
}
EOL
        # Create a Makefile
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/Makefile" << EOL
CC = gcc
CFLAGS = -no-pie

all: challenge

challenge: challenge.c
	\$(CC) \$(CFLAGS) -o challenge challenge.c

clean:
	rm -f challenge
EOL
        # Create an exploit template
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/exploit.py" << EOL
#!/usr/bin/env python3
from pwn import *
import ctfmate

# Set up the environment
context.arch = 'amd64'
context.terminal = ['tmux', 'splitw', '-h']

# Choose local or remote target
LOCAL = True
if LOCAL:
    p = process('./challenge')
    elf = ELF('./challenge')
    if args.GDB:
        gdb.attach(p, '''
        break main
        continue
        ''')
else:
    p = remote('localhost', 1337)
    elf = ELF('./challenge')

win_addr = elf.symbols['win']
log.info(f"Win function at: {hex(win_addr)}")

def add_chunk(data):
    p.sendlineafter(b'Choice: ', b'1')
    p.sendafter(b'Enter data: ', data)
    
def delete_chunk(index):
    p.sendlineafter(b'Choice: ', b'2')
    p.sendlineafter(b'Enter chunk index to delete: ', str(index).encode())
    
def view_chunk(index):
    p.sendlineafter(b'Choice: ', b'3')
    p.sendlineafter(b'Enter chunk index to view: ', str(index).encode())
    p.recvuntil(b'Chunk ' + str(index).encode() + b' data: ')
    return p.recvline().strip()

# Exploit strategy:
# 1. Create chunks
# 2. Trigger double-free or use-after-free
# 3. Overwrite function pointer
# 4. Trigger win function

# Start your exploit here
# ...

p.interactive()
EOL
        chmod +x "$ACTIVE_DIR/$EXERCISE_NAME/exploit.py"
        ;;
        
    *)
        echo "Unknown template: $TEMPLATE"
        echo "Using basic template instead."
        # Create a simple challenge.c file
        cat > "$ACTIVE_DIR/$EXERCISE_NAME/challenge.c" << EOL
#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("Hello, pwn!\n");
    return 0;
}
EOL
        ;;
esac

echo "Created new exercise: $EXERCISE_NAME with template: $TEMPLATE"
echo "Files are located in: $ACTIVE_DIR/$EXERCISE_NAME/"
EOF
chmod +x scripts/new_exercise.sh

# Create README.md
echo -e "${YELLOW}Creating README.md...${NC}"
cat > README.md << 'EOF'
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
EOF

# Build and start Docker container
echo -e "${YELLOW}Building Docker image...${NC}"
docker compose build && docker compose up -d

# Wait for container to be ready
echo -e "${YELLOW}Waiting for container to be ready...${NC}"
sleep 5

# Check if container is running
if docker ps | grep -q pwn_env; then
    echo -e "${GREEN}Container is running successfully!${NC}"
    
    # Setup SSH key for GitHub
    echo -e "${YELLOW}Do you want to set up SSH access to GitHub? (y/N)${NC}"
    read -r setup_ssh
    if [[ "$setup_ssh" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${YELLOW}Setting up SSH key for GitHub authentication${NC}"
        echo
        
        # Get user info
        read -p "Enter your GitHub email: " github_email
        read -p "Enter your Git username: " git_username
        
        # Set git global config
        docker exec -it pwn_env bash -c "git config --global user.email \"$github_email\""
        docker exec -it pwn_env bash -c "git config --global user.name \"$git_username\""
        
        # Generate SSH key
        docker exec -it pwn_env bash -c "ssh-keygen -t ed25519 -C \"$github_email\" -f /root/.ssh/id_ed25519 -N \"\""
        
        # Display the public key
        echo
        echo -e "${BLUE}Add this SSH key to your GitHub account:${NC}"
        docker exec -it pwn_env bash -c "cat /root/.ssh/id_ed25519.pub"
        echo
        echo -e "${YELLOW}Add this key at: https://github.com/settings/keys${NC}"
        
        # Ask user to confirm key was added
        read -p "Press Enter once you've added the key to GitHub..."
        
        # Test SSH connection
        echo -e "${YELLOW}Testing SSH connection to GitHub...${NC}"
        docker exec -it pwn_env bash -c "ssh -o StrictHostKeyChecking=no -T git@github.com"
        
        echo -e "${GREEN}SSH setup complete!${NC}"
    fi
    
    echo -e "${GREEN}Environment setup complete! You can now access your PWN environment with:${NC}"
    echo -e "${BLUE}docker exec -it pwn_env zsh${NC}"
    echo
    echo -e "${GREEN}Try creating your first exercise with:${NC}"
    echo -e "${BLUE}./scripts/new_exercise.sh my_first_exploit buffer_overflow${NC}"
else
    echo -e "${RED}Container failed to start. Check logs with: docker compose logs${NC}"
fi