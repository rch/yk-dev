{ pkgs, lib, config, inputs, ... }:

{
    # https://devenv.sh/packages/
  packages = [ pkgs.git ];

  # https://devenv.sh/languages/
  languages.go.enable = true;
  languages.go.package = pkgs.go;

  # See full reference at https://devenv.sh/reference/options/
}

