{
    description = "Edrakon – OpenXR → SteamLink OSC bridge";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    outputs =
        { self, nixpkgs }:
        let
            systems = [ "x86_64-linux" ];
            forAll =
                f:
                builtins.listToAttrs (
                    map (system: {
                        name = system;
                        value = f system;
                    }) systems
                );
        in
        {
            packages = forAll (
                system:
                let
                    pkgs = import nixpkgs { inherit system; };
                in
                {
                    default = pkgs.callPackage ./package.nix { };
                }
            );

            devShells = forAll (
                system:
                let
                    pkgs = import nixpkgs { inherit system; };

                    dotnetSdk = pkgs.dotnetCorePackages.sdk_9_0;

                    libPath = pkgs.lib.makeLibraryPath [
                        pkgs.openxr-loader
                        pkgs.libglvnd
                        pkgs.vulkan-loader
                        (pkgs.libx11 or pkgs.xorg.libX11)
                        (pkgs.libxext or pkgs.xorg.libXext)
                        (pkgs.libxfixes or pkgs.xorg.libXfixes)
                        (pkgs.libxrandr or pkgs.xorg.libXrandr)
                        (pkgs.libxcursor or pkgs.xorg.libXcursor)
                        (pkgs.libxinerama or pkgs.xorg.libXinerama)
                        pkgs.libdrm
                        pkgs.udev
                        pkgs.dbus
                        pkgs.libuuid
                    ];
                in
                {
                    default = pkgs.mkShell {
                        buildInputs = [
                            dotnetSdk
                            pkgs.nuget-to-json
                            pkgs.openxr-loader
                            pkgs.monado
                            pkgs.icu
                            pkgs.zlib
                            pkgs.libkrb5
                            pkgs.pkg-config
                        ];

                        DOTNET_CLI_TELEMETRY_OPTOUT = "1";

                        shellHook = ''
                            export LD_LIBRARY_PATH="${libPath}:$LD_LIBRARY_PATH"
                            if [ -d /run/opengl-driver/lib ]; then
                              export LD_LIBRARY_PATH="/run/opengl-driver/lib:$LD_LIBRARY_PATH"
                            fi
                            if [ -d /run/opengl-driver-32/lib ]; then
                              export LD_LIBRARY_PATH="/run/opengl-driver-32/lib:$LD_LIBRARY_PATH"
                            fi
                            if [ -z "$XR_RUNTIME_JSON" ]; then
                              ACTIVE_RUNTIME="$HOME/.config/openxr/1/active_runtime.json"
                              if [ -f "$ACTIVE_RUNTIME" ]; then
                                export XR_RUNTIME_JSON="$ACTIVE_RUNTIME"
                              else
                                export XR_RUNTIME_JSON=${pkgs.monado}/share/openxr/1/openxr_monado.json
                              fi
                            fi
                        '';
                    };
                }
            );
        };
}
