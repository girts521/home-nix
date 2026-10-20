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
  };

  outputs = { nixpkgs, home-manager, ... }@inputs: {
    homeConfigurations = {
      "masterpc" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home/shared.nix ./home/hosts/masterpc/masterpc.nix ];
      };
      "laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home/shared.nix ./home/hosts/laptop/laptop.nix ./home/modules/quickshell.nix ];
      };
    };
  };
}
