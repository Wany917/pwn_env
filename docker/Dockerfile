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
