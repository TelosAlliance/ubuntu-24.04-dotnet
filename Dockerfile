FROM telosalliance/ubuntu-24.04:2026-01-29

RUN apt-get update && apt-get install -y wget && \
    wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet

ENV \
    # Unset ASPNETCORE_URLS from aspnet base image
    ASPNETCORE_URLS= \
    # Do not generate certificate
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # SDK version
    DOTNET_SDK_VERSION=10.0.102 \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetSDK-Ubuntu-24.04 \
    # Workaround for https://github.com/PowerShell/PowerShell/issues/20685
    DOTNET_ROLL_FORWARD=Major \
    DOTNET_ROOT=/usr/share/dotnet \
    PATH=$PATH:/usr/share/dotnet

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 291F9FF6FD385783 \
   && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 684BA42D \
   && apt-get update \
   && apt-get install -y --no-install-recommends \
     libguestfs-tools \
     extlinux \
     fakeroot \
     libelf-dev \
     libc6 \
     libgcc1 \
     libgssapi-krb5-2 \
     libicu-dev \
     liblttng-ust1t64 \
     libssl3 \
     libstdc++6 \
     zlib1g \
     uuid-runtime \
     nano \
     # required for ldap-python / openldap compiling \
     python3-dev \
     # python2.7-dev \
     libldap2-dev \
     libsasl2-dev \
     ldap-utils \
     tox \
     lcov \
     libatomic1 \
     wget \
     python3-six \
     python3-setuptools \
     # above for ldap-python \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/share/dotnet/dnx /usr/bin/dnx \
    # Trigger first run experience by running arbitrary cmd
    && dotnet help

# Install PowerShell global tool
RUN powershell_version=7.6.0-preview.4 \
    && curl --fail --show-error --location --output PowerShell.Linux.x64.$powershell_version.nupkg https://powershellinfraartifacts-gkhedzdeaghdezhr.z01.azurefd.net/tool/$powershell_version/PowerShell.Linux.x64.$powershell_version.nupkg \
    && powershell_sha512='92ba2a8344f13d1c640f73d61488a582bae3ea82e4d00aad02efece3475f852855fb6f8ac37f72b4a14cdc1975af9f253d59ce72e36f3653e6b1ee87dc273f8f' \
    && echo "$powershell_sha512  PowerShell.Linux.x64.$powershell_version.nupkg" | sha512sum -c - \
    && mkdir --parents /usr/share/powershell \
    && dotnet tool install --add-source / --tool-path /usr/share/powershell --version $powershell_version PowerShell.Linux.x64 \
    && dotnet nuget locals all --clear \
    && rm PowerShell.Linux.x64.$powershell_version.nupkg \
    && ln -s /usr/share/powershell/pwsh /usr/bin/pwsh \
    && chmod 755 /usr/share/powershell/pwsh \
    # To reduce image size, remove the copy nupkg that nuget keeps.
    && find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm

RUN curl -fLO https://builds.dotnet.microsoft.com/dotnet/Runtime/10.0.2/dotnet-runtime-10.0.2-linux-x64.tar.gz \
    && curl -fL https://aka.ms/dotnet-dump/linux-x64 -o dotnet-dump \
    && curl -fL https://aka.ms/dotnet-gcdump/linux-x64 -o dotnet-gcdump

RUN npm install -g npm@10.9.2
