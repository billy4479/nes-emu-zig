{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          zls
        ];
        nativeBuildInputs = with pkgs; [
          zig_0_12
          SDL2
          SDL2_ttf
        ];

        SDL2_INCLUDE = "${pkgs.SDL2}/include";
      };
    });
}
