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
    # Keep the desktop package set on this flake's nixpkgs; nixGL's pinned
    # nixpkgs is used separately for its version-specific NVIDIA wrapper.
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
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
