{ pkgs, lib, config, inputs, ... }:

let
  connect-iq-sdk-manager = pkgs.stdenv.mkDerivation {
    pname = "connect-iq-sdk-manager";
    version = "0.8.4";
    src = pkgs.fetchurl {
      url = "https://github.com/lindell/connect-iq-sdk-manager-cli/releases/download/v0.8.4/connect-iq-sdk-manager-cli_0.8.4_Linux_x86_64.tar.gz";
      sha256 = "5d57b8f9cfcd02d3b3f48e19d6daca0480e4c6f627926f15d8617ef8a6f57e0b";
    };
    sourceRoot = ".";
    installPhase = ''
      install -Dm755 connect-iq-sdk-manager $out/bin/connect-iq-sdk-manager
    '';
  };
in
{
  packages = [
    pkgs.jdk17
    pkgs.openssl
    pkgs.unzip
    pkgs.jq
    pkgs.curl
    connect-iq-sdk-manager
  ];

  env = {
    GARMIN_HOME = "$HOME/.Garmin/ConnectIQ";
  };

  scripts = {
    generate-key = {
      description = "Generate Garmin Connect IQ 4096-bit RSA developer key (developer_key.der)";
      exec = ''
        set -euo pipefail
        KEY_PATH="''${1:-$DEVENV_ROOT/developer_key.der}"
        PEM_PATH="''${KEY_PATH%.der}.pem"
        if [ -f "$KEY_PATH" ]; then
          echo "Developer key already exists at: $KEY_PATH"
          exit 0
        fi
        echo "Generating 4096-bit RSA private key..."
        openssl genpkey -algorithm RSA -out "$PEM_PATH" -pkeyopt rsa_keygen_bits:4096 2>/dev/null
        openssl pkcs8 -topk8 -inform PEM -outform DER -in "$PEM_PATH" -out "$KEY_PATH" -nocrypt
        chmod 600 "$KEY_PATH" "$PEM_PATH"
        echo "Successfully created developer key: $KEY_PATH"
      '';
    };

    ciq-login = {
      description = "Log in to Garmin SSO via connect-iq-sdk-manager (required to download device definitions)";
      exec = ''
        connect-iq-sdk-manager login "$@"
      '';
    };

    download-devices = {
      description = "Download device definitions required by project manifests";
      exec = ''
        set -euo pipefail
        echo "=== Downloading devices for OneR remote ==="
        connect-iq-sdk-manager device download -m "$DEVENV_ROOT/OneR remote/manifest.xml" || true

        echo "=== Downloading devices for OneR remote DF ==="
        connect-iq-sdk-manager device download -m "$DEVENV_ROOT/OneR remote DF/manifest.xml" || true

        echo "=== Downloading devices for BLE Barrel ==="
        BARREL_DEVICES=$(grep -oP '<iq:product id="\K[^"]+' "$DEVENV_ROOT/BLE Barrel/manifest.xml" | paste -sd, -)
        if [ -n "$BARREL_DEVICES" ]; then
          connect-iq-sdk-manager device download -d "$BARREL_DEVICES" || true
        fi

        echo "Device download step complete."
      '';
    };

    build-barrel = {
      description = "Compile the BLE Barrel library (BLE Barrel-1.0.0.barrel)";
      exec = ''
        set -euo pipefail
        cd "$DEVENV_ROOT/BLE Barrel"
        echo "Building BLE Barrel..."
        barrelbuild -f monkey.jungle -o "BLE Barrel-1.0.0.barrel"
        echo "Successfully built: BLE Barrel/BLE Barrel-1.0.0.barrel"
      '';
    };

    build-widget = {
      description = "Build OneR remote widget for target device (default: DEVICE=fenix7)";
      exec = ''
        set -euo pipefail
        DEVICE="''${DEVICE:-fenix7}"
        KEY="''${PRIVATE_KEY:-$DEVENV_ROOT/developer_key.der}"
        if [ ! -f "$KEY" ]; then
          echo "No developer key found at $KEY. Generating one..."
          generate-key "$KEY"
        fi
        mkdir -p "$DEVENV_ROOT/OneR remote/bin"
        cd "$DEVENV_ROOT/OneR remote"
        echo "Building OneR remote for device: $DEVICE..."
        monkeyc -f "monkey.jungle;barrels.jungle" -d "$DEVICE" -o "bin/OneRremote.prg" -y "$KEY" -l 0
        echo "Successfully built: OneR remote/bin/OneRremote.prg"
      '';
    };

    build-datafield = {
      description = "Build OneR remote DF datafield for target device (default: DEVICE=edge1030)";
      exec = ''
        set -euo pipefail
        DEVICE="''${DEVICE:-edge1030}"
        KEY="''${PRIVATE_KEY:-$DEVENV_ROOT/developer_key.der}"
        if [ ! -f "$KEY" ]; then
          echo "No developer key found at $KEY. Generating one..."
          generate-key "$KEY"
        fi
        mkdir -p "$DEVENV_ROOT/OneR remote DF/bin"
        cd "$DEVENV_ROOT/OneR remote DF"
        echo "Building OneR remote DF for device: $DEVICE..."
        monkeyc -f "monkey.jungle;barrels.jungle" -d "$DEVICE" -o "bin/OneRremoteDF.prg" -y "$KEY" -l 0
        echo "Successfully built: OneR remote DF/bin/OneRremoteDF.prg"
      '';
    };

    package-widget = {
      description = "Package OneR remote widget into .iq release package";
      exec = ''
        set -euo pipefail
        KEY="''${PRIVATE_KEY:-$DEVENV_ROOT/developer_key.der}"
        if [ ! -f "$KEY" ]; then
          echo "No developer key found at $KEY. Generating one..."
          generate-key "$KEY"
        fi
        mkdir -p "$DEVENV_ROOT/OneR remote/bin"
        cd "$DEVENV_ROOT/OneR remote"
        echo "Packaging OneR remote widget (.iq)..."
        monkeyc -e -r -f "monkey.jungle;barrels.jungle" -o "bin/OneRremote.iq" -y "$KEY" -l 0
        echo "Successfully packaged: OneR remote/bin/OneRremote.iq"
      '';
    };

    package-datafield = {
      description = "Package OneR remote DF datafield into .iq release package";
      exec = ''
        set -euo pipefail
        KEY="''${PRIVATE_KEY:-$DEVENV_ROOT/developer_key.der}"
        if [ ! -f "$KEY" ]; then
          echo "No developer key found at $KEY. Generating one..."
          generate-key "$KEY"
        fi
        mkdir -p "$DEVENV_ROOT/OneR remote DF/bin"
        cd "$DEVENV_ROOT/OneR remote DF"
        echo "Packaging OneR remote DF datafield (.iq)..."
        monkeyc -e -r -f "monkey.jungle;barrels.jungle" -o "bin/OneRremoteDF.iq" -y "$KEY" -l 0
        echo "Successfully packaged: OneR remote DF/bin/OneRremoteDF.iq"
      '';
    };

    build-all = {
      description = "Build BLE Barrel, OneR remote widget, and OneR remote DF datafield";
      exec = ''
        set -euo pipefail
        build-barrel
        build-widget
        build-datafield
      '';
    };
  };

  enterShell = ''
    mkdir -p "$HOME/.Garmin/ConnectIQ/Sdks" "$HOME/.Garmin/ConnectIQ/Devices"

    connect-iq-sdk-manager agreement accept 2>/dev/null || true

    CFG="$HOME/.Garmin/ConnectIQ/current-sdk.cfg"
    if [ ! -f "$CFG" ] || [ ! -d "$(cat "$CFG" 2>/dev/null)" ]; then
      echo "No Connect IQ SDK found. Downloading SDK 9.2.0..."
      connect-iq-sdk-manager sdk set 9.2.0
    fi

    if [ -f "$CFG" ]; then
      SDK_PATH="$(cat "$CFG")"
      export SDK_HOME="$SDK_PATH"
      export PATH="$SDK_HOME/bin:$PATH"

      # Patch scripts in SDK bin for NixOS compatibility (NixOS does not have /bin/bash)
      find "$SDK_HOME/bin" -maxdepth 1 -type f -exec sed -i '1s|^#!/bin/bash|#!/usr/bin/env bash|' {} + 2>/dev/null || true
    fi

    echo ""
    echo "=========================================================="
    echo "  Garmin Connect IQ Development Environment (devenv)     "
    echo "=========================================================="
    echo "  Active SDK : ''${SDK_HOME:-None}"
    echo "  Java       : $(java -version 2>&1 | head -n 1)"
    echo "  Compiler   : $(monkeyc -v 2>&1 | head -n 1)"
    echo ""
    echo "  Available Commands:"
    echo "    ciq-login         - Log in to Garmin SSO (to download devices)"
    echo "    download-devices  - Download device definitions"
    echo "    generate-key      - Generate a developer key (developer_key.der)"
    echo "    build-barrel      - Build BLE Barrel library"
    echo "    build-widget      - Build OneR remote widget"
    echo "    build-datafield   - Build OneR remote DF datafield"
    echo "    package-widget    - Package OneR remote widget (.iq)"
    echo "    package-datafield - Package OneR remote DF datafield (.iq)"
    echo "    build-all         - Build barrel, widget, and datafield"
    echo "=========================================================="
    if [ ! -f "$DEVENV_ROOT/developer_key.der" ]; then
      echo "Tip: Run 'generate-key' to create developer_key.der for signing builds."
    fi
    echo ""
  '';

  enterTest = ''
    echo "Verifying toolchain..."
    java -version
    openssl version
    connect-iq-sdk-manager version
    monkeyc -v
    barrelbuild --help >/dev/null
    echo "Toolchain verification successful!"
  '';
}
