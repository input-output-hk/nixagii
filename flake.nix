{
  inputs = {
    std.url = "github:divnix/std";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs: (inputs.flake-utils.lib.eachDefaultSystem (
    system: let
      std = inputs.std.deSystemize system inputs.std;
      pkgs = inputs.std.deSystemize system inputs.nixpkgs.legacyPackages;
    in rec {
      # --- Nixagii Pebbles ---------------------------------------------
      jira = project:
        std.std.lib.mkNixago {
          configData = import ./jira.nix project;
          output = ".jira.d/config.yml";
          format = "yaml";
          packages = [];
          commands = [
            {
              package = pkgs.go-jira;
              name = "jira";
            }
          ];
        };
      gh-jira-integration = project: event:
        std.std.lib.mkNixago {
          configData = (import ./gh-jira-integration.nix project).${event};
          output = ".github/workflows/jira-integration-${event}.yml";
          format = "yaml";
          hook.mode = "copy";
          packages = [];
          commands = [{package = pkgs.gh;}];
        };
      gitattributes = std.std.lib.mkNixago {
        configData = import ./gitattributes.nix;
        output = ".gitattributes";
        format = "ignore";
        hook.mode = "copy";
        packages = [];
        commands = [];
      };
      ghsettings = std.std.lib.mkNixago {
        configData = import ./github.nix;
        format = "yaml";
        output = ".github/settings.yml";
        hook.mode = "copy";
        packages = [];
        commands = [];
      };
      # -----------------------------------------------------------------

      # --- Auxiliary Outputs -------------------------------------------

      devShells.default = std.std.lib.mkShell {
        name = "Nixagii";
        nixago = [
          std.std.nixago.treefmt
          std.std.nixago.editorconfig
          std.std.nixago.conform
          std.std.nixago.lefthook
          (ghsettings {
            configData.repository = {
              name = "nixagii";
              description = "Nixago Pebbles for IOG";
              topics = "devshell, devx, sre";
              default_branch = "main";
            };
          })
        ];
      };
      # -----------------------------------------------------------------
    }
  ));
}
