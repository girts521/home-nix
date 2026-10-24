{
  description = "Girts' shared nix-config (home-manager flakes)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sqlmux = {
      url = "github:kackerx/sqlmux/v0.5.0";
      flake = false;      # repo has no flake — treat it as plain source
    };
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
  let
    # pkgs with the nixGL overlay so pkgs.nixgl.* wrappers exist (masterpc NVIDIA fix).
    # Overlay only ADDS the nixgl wrappers; nothing on the laptop references them,
    # so the laptop's build is unchanged.
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
      overlays = [ inputs.nixgl.overlay ];
    };
  in {
    homeConfigurations = {
      "masterpc" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home/shared.nix ./home/hosts/masterpc/masterpc.nix ./home/modules/quickshell.nix ];
      };
      "laptop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home/shared.nix ./home/hosts/laptop/laptop.nix ./home/modules/quickshell.nix ];
      };
    };
  };
}
