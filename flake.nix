{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    data-merge.url = "github:divnix/data-merge";
    nixago.url = "github:nix-community/nixago";
    nixago.inputs.flake-utils.follows = "flake-utils";
    nixago.inputs.nixpkgs.follows = "nixpkgs";
    nixago-exts.url = "github:blaggacao/nixago-extensions";
    nixago-exts.inputs.nixpkgs.follows = "nixpkgs";
    nixago-exts.inputs.flake-utils.follows = "flake-utils";
    nixago-exts.inputs.data-merge.follows = "data-merge";
  };
  outputs = {
    data-merge,
    flake-utils,
    nixago,
    nixago-exts,
    nixpkgs,
    self,
  }: let
    __functor = self: extra:
      self
      // {
        configData = data-merge.merge self.configData extra;
      };
  in
    {
      treefmt = system:
        with nixpkgs.legacyPackages.${system}; {
          configData = import ./treefmt.nix;
          output = "treefmt.toml";
          format = "toml";
          packages = [alejandra nodePackages.prettier nodePackages.prettier-plugin-toml shfmt treefmt];
          commands = [{package = treefmt;}];
          inherit __functor;
        };
      editorconfig = system:
        with nixpkgs.legacyPackages.${system}; {
          configData = import ./editorconfig.nix;
          output = ".editorconfig";
          format = "ini";
          hook.mode = "copy";
          packages = [editorconfig-checker];
          commands = [];
          inherit __functor;
        };
      jira = system: project:
        with nixpkgs.legacyPackages.${system}; {
          configData = import ./jira.nix project;
          output = ".jira.d/config.yml";
          format = "yaml";
          packages = [];
          commands = [
            {
              package = go-jira;
              name = "jira";
            }
          ];
          inherit __functor;
        };
      gitattributes = system:
        with nixpkgs.legacyPackages.${system}; {
          configData = import ./gitattributes.nix;
          output = ".gitattributes";
          format = "ignore";
          hook.mode = "copy";
          packages = [];
          commands = [];
          inherit __functor;
        };
      ghsettings = system:
        with nixpkgs.legacyPackages.${system};
          {
            packages = [];
            commands = [];
          }
          // (nixago-exts.ghsettings.${system} (import ./github.nix));
      conform = system:
        with nixpkgs.legacyPackages.${system};
          {
            packages = [conform];
            commands = [];
          }
          // (nixago-exts.conform.${system} (import ./conform.nix));
      lefthook = system:
        with nixpkgs.legacyPackages.${system};
          {
            packages = [lefthook];
            commands = [];
          }
          // (nixago-exts.lefthook.${system} (import ./lefthook.nix));
    }
    // (flake-utils.lib.eachDefaultSystem (
      system: {
        # Configure local development shell
        devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
          shellHook =
            (nixago.lib.${system}.makeAll [
              (self.treefmt system)
              (self.editorconfig system)
              (self.ghsettings system {
                repository = {
                  name = "nixagii";
                  description = "Nixago Pebbles for IOG";
                  topics = "devshell, devx, sre";
                  default_branch = "main";
                };
              })
              (self.conform system {
                commit.conventional.scopes = data-merge.append (builtins.attrNames (
                  builtins.removeAttrs self ((builtins.attrNames self.sourceInfo) ++ ["sourceInfo" "outputs" "inputs"])
                ));
              })
              (self.lefthook system)
            ])
            .shellHook;
          packages =
            []
            ++ (self.treefmt system).packages
            ++ (self.editorconfig system).packages
            ++ (self.conform system).packages
            ++ (self.ghsettings system).packages
            ++ (self.lefthook system).packages;
        };
      }
    ));
}
