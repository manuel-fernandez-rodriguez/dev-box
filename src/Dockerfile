# See https://github.com/manuel-fernandez-rodriguez/xfce-rdp
FROM ghcr.io/manuel-fernandez-rodriguez/xfce-rdp:latest

# The base image `local/xfce-rdp:latest` already performs runtime configuration
# such as copying `startwm.sh`, installing the entrypoint, setting X defaults,
# configuring xrdp, PAM tweaks, exposing ports and creating the /home volume.
# This derived Dockerfile only installs additional packages and tools specific
# to the dev-box image (VS Code, .NET SDK, etc.).

ENV DEBIAN_FRONTEND=noninteractive

# Install packages from debian repos
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        firefox-esr \
        wget \
        curl \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

# BEGIN: Install Visual Studio Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list' && \
    apt-get update && \
    apt-get install -y --no-install-recommends code && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* microsoft.gpg /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

# Install c# extensions for Visual Studio Code (installed as root so they
# are available to any user created at runtime).
ENV DONT_PROMPT_WSL_INSTALL=1

# Make sure VS Code can find the .NET SDK by configuring the extension's settings to point to the system-wide dotnet path.
# The settings are copied to /etc/skel so they are present in any new user's home directory at runtime.
RUN mkdir -p /tmp/.vscode-root/User && \
    printf '{ "dotnetAcquisitionExtension.existingDotnetPath": [ { "extensionId": "ms-dotnettools.csdevkit", "path": "/usr/share/dotnet/dotnet" }, { "extensionId": "ms-dotnettools.csharp", "path": "/usr/share/dotnet/dotnet" } ] }' > /tmp/.vscode-root/User/settings.json && \
    mkdir -p /etc/skel/.config/Code/User && \
    cp /tmp/.vscode-root/User/settings.json /etc/skel/.config/Code/User/settings.json

# Install extensions into a global extensions directory so they are available
# to any user created at runtime. Running the `code` CLI as root requires
# a user-data-dir and --no-sandbox; install into `/usr/share/code/extensions`.
RUN mkdir -p /usr/share/code/extensions && \
    chown root:root /usr/share/code/extensions && \
    code --extensions-dir /usr/share/code/extensions --user-data-dir /tmp/.vscode-root --no-sandbox --install-extension ms-dotnettools.csdevkit --force

# Create wrapper for VS Code to disable Chromium sandbox inside container
RUN printf '#!/bin/sh\nexec /usr/bin/code --no-sandbox --disable-gpu "$@"\n' > /usr/local/bin/code && \
    chmod +x /usr/local/bin/code

# Ensure ELECTRON_DISABLE_SANDBOX is exported system-wide so desktop sessions
# inherit it, and place a wrapper in /usr/bin to reliably override packaged
# launcher when applications start VS Code from menus or shortcuts.
RUN printf 'export ELECTRON_DISABLE_SANDBOX=1\n' > /etc/profile.d/disable-electron-sandbox.sh && \
    chmod 644 /etc/profile.d/disable-electron-sandbox.sh && \
    printf '#!/bin/sh\nexec /usr/share/code/code --no-sandbox --disable-gpu "$@"\n' > /usr/bin/code && \
    chmod +x /usr/bin/code || true

# END: Install Visual Studio Code

# BEGIN: Install .NET 10 SDK via Microsoft's apt repository
RUN wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-10.0 && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="$PATH:/usr/share/dotnet"
# END: Install .NET 10 SDK via Microsoft's apt repository

# BEGIN: Install Bruno
RUN wget https://github.com/usebruno/bruno/releases/download/v3.2.2/bruno_3.2.2_amd64_linux.deb -O bruno.deb && \
    apt-get update && \
    apt-get install -y \
        libxss1 && \
    dpkg -i bruno.deb && \
    rm bruno.deb && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

# Create wrapper and update the desktop entry
RUN printf '#!/bin/sh\nexport ELECTRON_DISABLE_SANDBOX=1\nexec setsid /opt/Bruno/bruno --disable-gpu --disable-gpu-compositing --no-sandbox "$@" >/dev/null 2>&1 < /dev/null\n' > /usr/local/bin/bruno-wrapper && \
    chmod +x /usr/local/bin/bruno-wrapper || true && \
    mkdir -p /etc/skel/.local/share/applications && \
    if [ -f /usr/share/applications/bruno.desktop ]; then \
      sed 's|^Exec=.*|Exec=/usr/local/bin/bruno-wrapper %U|' /usr/share/applications/bruno.desktop > /etc/skel/.local/share/applications/bruno.desktop || true; \
      chmod 644 /etc/skel/.local/share/applications/bruno.desktop || true; \
    fi || true

# END: Install Bruno

# Copy the entry point hook
COPY 500-dev-box-container-start.sh /etc/xfce-rdp/hooks/container-start/main/500-dev-box-container-start.sh
RUN chmod 644 /etc/xfce-rdp/hooks/container-start/main/500-dev-box-container-start.sh || true

# Unset, so that it is not propagated to the container at runtime
ENV DEBIAN_FRONTEND=


