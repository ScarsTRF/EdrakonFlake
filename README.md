# Edrakon Flake

Flake for [BlueCyro's Edrakon](https://github.com/BlueCyro/Edrakon) program for simulating SteamLinkVR OSC face tracking endpoint for OpenXR headsets.

This flake was something I honestly slapped together and will continue to try and work on it with my small patches here.

## Quickstart

Add to your `flake.nix`:

```nix
# flake.nix
{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        edrakon = {
            url= "github:ScarsTRF/EdrakonFlake";
            # Adding this input override here will reduce nix store usage
            # BUT CAN cause issues with getting deps for the app building
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # ...
    };
    # ...
}
```

Add the package to your `environment.systemPackages`:

```nix
{inputs, pkgs, ...}:
{
    environment.systemPackages = [
        inputs.edrakon.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    # ...
}
```

or to `home.packages` for home manager:

```nix
{inputs, pkgs, ...}:
{
    home.packages = [
        inputs.edrakon.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    # ...
}
```

Run Edrakon in your terminal with either `Edrakon` `export EDRAKON_PORT=9015 Edrakon` or `Edrakon 9015` while 9015 is the port Edrakon will expose the OSC messages to. Read below for more information why that might be important for VRCFT users.

## Notes

This currently is patching some stuff for the port that Edrakon is outputting, I added ENV support to this so if you wanna setup automations based off the app starting it or via the original args passthrough, you can, this doesn't change the original functionality but adds the ability to pass `EDRAKON_PORT` as a environment variable if you would like.

This also changes the default port it outputs from to be 9015 which is useful for other applications like VRCFT to be able to see it if you're using the SteamLinkVR module.

I'm also helping Edrakon to find the runtime for OpenXR, If XR_RUNTIME_JSON isn't available with a wrapper, it will look for it in `/etc/xdg/openxr` or `~/.config/openxr` automatically. This is especially needed for Monado or WiVRn users on NixOS which can use either `services.monado.defaultRuntime = true;` or for WiVRn users `services.wivrn.defaultRuntime = true;`

All rights are reserved to BlueCryo for both [Edrakon](https://github.com/BlueCyro/Edrakon) and [KoboldOSC](https://github.com/BlueCyro/KoboldOSC), a dependency for Edrakon. This flake only adds environment variable capabilities with a small patch and builds it for NixOS users.
