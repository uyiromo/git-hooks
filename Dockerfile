# hadolint global ignore=DL3008,DL3013,DL3016,DL3059
# - DL3008: Pin versions in apt get install
# - DL3013: Pin versions in pip install
# - DL3016: Pin versions in npm install
# - DL3059: Multiple consecutive `RUN` instructions
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND noninteractive

SHELL [ "/bin/bash", "-o", "pipefail", "-c" ]

# common packages
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    apt-utils \
    curl \
    git \
    gnupg \
    software-properties-common \
    wget \
    tar \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# npm
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get install -y \
    --no-install-recommends \
    nodejs
ENV NODE_PATH "/usr/lib/node_modules"

# Rust
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH "/root/.cargo/bin:${PATH}"

# Haskell
RUN apt-get install -y \
    --no-install-recommends \
    cabal-install
ENV PATH "/root/.cabal/bin/:${PATH}"

# go
RUN apt-get install -y \
    --no-install-recommends \
    golang-go
ENV PATH "/root/go/bin/:${PATH}"

# python
RUN apt-get install -y \
    --no-install-recommends \
    python3 \
    python3-pip \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    liblzma-dev \
    libffi-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# hadolint ignore=DL3003
RUN curl -fsSL "https://www.python.org/ftp/python/3.13.2/Python-3.13.2.tgz" -o "Python-3.13.2.tgz" \
    && tar -xf "Python-3.13.2.tgz" \
    && cd "Python-3.13.2" \
    && ./configure --enable-optimizations --enable-shared \
    && make -j"$(nproc)" \
    && make install \
    && cd .. \
    && rm -rf "Python-3.13.2" "Python-3.13.2.tgz"
ENV LD_LIBRARY_PATH "/usr/local/lib:${LD_LIBRARY_PATH}"

# hadolint ignore=DL3009
RUN apt-get update

# .md
# - (formatter) markdownlint
# - (linter)    markdownlint
RUN npm install -g markdownlint-cli

# .py
# - (formatter) isort
# - (formatter) black
# - (linter)    flake8
# - (linter)    mypy
RUN pip3 install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir --break-system-package  isort black flake8 mypy
COPY ./requirements-types.txt /tmp/requirements-types.txt
# hadolint ignore=DL3002,SC2002
RUN grep -v "^#" /tmp/requirements-types.txt | xargs -n 1 pip3.13 install --no-cache-dir --break-system-package || true

# .sh
# - (formatter) shfmt
# - (linter)    shellcheck
RUN apt-get install -y \
    --no-install-recommends \
    shfmt \
    shellcheck
COPY ./requirements-types.txt /tmp/requirements-types.txt
COPY ./scripts/shchk.py /usr/local/bin/shchk
RUN chmod +x /usr/local/bin/shchk

# .toml
# - (formatter) taplo
# - (linter)    taplo
RUN cargo install taplo-cli

# .yaml
# - (formatter) yamlfmt
# - (linter)    yamllint
RUN go install github.com/google/yamlfmt/cmd/yamlfmt@latest
RUN apt-get install -y \
    --no-install-recommends \
    yamllint

# .json
# - (formatter) js-beautify
# - (linter)    eslint
RUN npm install -g js-beautify
RUN npm install -g eslint
RUN npm install -g @eslint/json


# .js
# - (formatter) eslint
# - (linter)    eslint
RUN npm install -g eslint
RUN npm install -g @stylistic/eslint-plugin-js

# Dockerfile
# - (formatter) -
# - (linter)    hadolint
RUN curl -fsSL https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint \
    && chmod +x /usr/local/bin/hadolint
ENV PATH "/usr/local/bin/:${PATH}"

# gitmoji
COPY ./commit-msg/check-commit-msg-emoji.py /usr/local/bin/check-commit-msg-emoji
COPY ./commit-msg/gitmojis.json /etc/gitmojis.json
RUN chmod +x /usr/local/bin/check-commit-msg-emoji

# sm-latest
COPY ./pre-push/sm-latest.sh /usr/local/bin/sm-latest
RUN chmod +x /usr/local/bin/sm-latest

# clean
RUN rm -rf /var/lib/apt/lists/*

# +x for node_modules
RUN chmod -R +x /usr/lib/node_modules/*

# check installed versions
RUN markdownlint --version
RUN isort --version
RUN black --version
RUN flake8 --version
RUN mypy --version
RUN shfmt --version
RUN shellcheck --version
RUN taplo --version
RUN yamlfmt --version
RUN yamllint --version
RUN js-beautify --version
RUN eslint --version
RUN hadolint --version

# open for all users
RUN chmod -R 777 /root

CMD ["/bin/bash"]
