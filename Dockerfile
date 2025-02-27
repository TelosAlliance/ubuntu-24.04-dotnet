FROM telosalliance/ubuntu-24.04:2025-01-09

ENV \
    # Unset ASPNETCORE_URLS from aspnet base image
    ASPNETCORE_URLS= \
    # Do not generate certificate
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    # SDK version
    DOTNET_SDK_VERSION=8.0.406 \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetSDK-Ubuntu-24.04

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
     python3-six \
     python3-setuptools \
     # above for ldap-python \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
RUN curl -fSL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$DOTNET_SDK_VERSION/dotnet-sdk-$DOTNET_SDK_VERSION-linux-x64.tar.gz \
    && dotnet_sha512='d6fdcfebd0df46959f7857cfb3beac7de6c8843515ece28b24802765fd9cfb6c7e9701b320134cb4907322937ab89cae914ddc21bf48b9b6313e9a9af5c1f24a' \
    && echo "$dotnet_sha512  dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    # Trigger first run experience by running arbitrary cmd
    && dotnet help

# Install PowerShell global tool
RUN powershell_version=7.4.7 \
    && curl -fSL --output PowerShell.Linux.x64.$powershell_version.nupkg https://powershellinfraartifacts-gkhedzdeaghdezhr.z01.azurefd.net/tool/$powershell_version/PowerShell.Linux.x64.$powershell_version.nupkg \
    && powershell_sha512='3f4ff718b982b5cbcbc3ceef2602f681af8029e716aa00a65e60edd81c94fcea3d2e4d6c6f18b5f3cadfba2558f70dbe810397c6bf73757d132ec7bec77dfdba' \
    && echo "$powershell_sha512  PowerShell.Linux.x64.$powershell_version.nupkg" | sha512sum -c - \
    && mkdir -p /usr/share/powershell \
    && dotnet tool install --add-source / --tool-path /usr/share/powershell --version $powershell_version PowerShell.Linux.x64 \
    && dotnet nuget locals all --clear \
    && rm PowerShell.Linux.x64.$powershell_version.nupkg \
    && ln -s /usr/share/powershell/pwsh /usr/bin/pwsh \
    && chmod 755 /usr/share/powershell/pwsh \
    # To reduce image size, remove the copy nupkg that nuget keeps.
    && find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm

RUN npm install -g npm@8.19.2
