{
    lib,
    fetchFromGitHub,
    buildDotnetModule,
    dotnetCorePackages,
    makeWrapper,
    # Runtime deps
    openxr-loader,
    libglvnd,
    vulkan-loader,
    libdrm,
    udev,
    dbus,
    libuuid,
    pkgs,
}:

let
    repoOwner = "BlueCyro";

    koboldSrc = fetchFromGitHub {
        owner = repoOwner;
        repo = "KoboldOSC";
        rev = "08de424420c7b52751cb9e8dfddffdbdeb1699c8";
        hash = "sha256-TRatrXgxSXiZZjV+7zR9BUXHjdV6+IrfQ+pQY36XUac=";
    };
in
buildDotnetModule rec {
    pname = "edrakon";
    version = "1.0.0";

    src = fetchFromGitHub {
        owner = repoOwner;
        repo = "Edrakon";
        rev = "0443dc24328666c6b03bc7569d6dfff28df49d76";
        hash = "sha256-JBEeF2fbt4WEArFYijrmlM4lJ1YHuLyowyIKfCHpO2Q=";
    };

    postUnpack = ''
        cp -r ${koboldSrc} $sourceRoot/../KoboldOSC
        chmod -R u+w $sourceRoot/../KoboldOSC
    '';

    patches = [
        ./env-port.patch
    ];

    projectFile = "Edrakon.csproj";
    nugetDeps = ./deps.json;

    dotnet-sdk = dotnetCorePackages.sdk_10_0;
    dotnet-runtime = dotnetCorePackages.runtime_10_0;

    nativeBuildInputs = [ makeWrapper ];

    runtimeDeps = [
        openxr-loader
        libglvnd
        vulkan-loader
        (pkgs.libx11 or pkgs.xorg.libX11)
        (pkgs.libxext or pkgs.xorg.libXext)
        (pkgs.libxfixes or pkgs.xorg.libXfixes)
        (pkgs.libxrandr or pkgs.xorg.libXrandr)
        (pkgs.libxcursor or pkgs.xorg.libXcursor)
        (pkgs.libxinerama or pkgs.xorg.libXinerama)
        libdrm
        udev
        dbus
        libuuid
    ];

    # TODO: replace with a arg helper to handle XR runtime.

    # NOTE: Leave out till port patch is ready
    # --set-default EDRAKON_PORT "9015" \
    postFixup = ''
        wrapProgram $out/bin/Edrakon \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeDeps}" \
          --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib" \
          --run '
              if [ -z "$XR_RUNTIME_JSON" ]; then
                  ACTIVE_RUNTIME="$HOME/.config/openxr/1/active_runtime.json"
                  if [ -f "$ACTIVE_RUNTIME" ]; then
                      export XR_RUNTIME_JSON="$ACTIVE_RUNTIME"
                  else
                      ACTIVE_RUNTIME="/etc/xdg/openxr/1/active_runtime.json"
                      if [ -f "$ACTIVE_RUNTIME" ]; then
                          export XR_RUNTIME_JSON="$ACTIVE_RUNTIME"
                      else
                          export XR_RUNTIME_JSON="${pkgs.wivrn}/share/openxr/1/openxr_monado.json"
                      fi
                  fi
              fi
          '
    '';

    meta = {
        description = "OpenXR to SteamLink OSC bridge";
        homepage = "https://github.com/OWNER/Edrakon";
        # Since Cyro doesn't provide a license for their code
        # Just leave it out for now
        # license = lib.licenses.unfree;
        mainProgram = "Edrakon";
        platforms = [ "x86_64-linux" ];
    };
}
