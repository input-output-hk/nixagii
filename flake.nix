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
  in (flake-utils.lib.eachDefaultSystem (
    system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      # --- Nixagii Pebbles ---------------------------------------------
      treefmt = {
        configData = import ./treefmt.nix;
        output = "treefmt.toml";
        format = "toml";
        packages = [pkgs.alejandra pkgs.nodePackages.prettier pkgs.nodePackages.prettier-plugin-toml pkgs.shfmt pkgs.treefmt];
        commands = [{package = treefmt;}];
        inherit __functor;
      };
      editorconfig = {
        configData = import ./editorconfig.nix;
        output = ".editorconfig";
        format = "ini";
        hook.mode = "copy";
        packages = [pkgs.editorconfig-checker];
        commands = [];
        inherit __functor;
      };
      jira = project: {
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
        inherit __functor;
      };
      gh-jira-integration = project: {
        configData = import ./gh-jira-integration.nix project;
        output = ".github/workflow/jira-integration.yml";
        format = "yaml";
        packages = [];
        commands = [{package = pkgs.gh;}];
        inherit __functor;
      };
      gitattributes = {
        configData = import ./gitattributes.nix;
        output = ".gitattributes";
        format = "ignore";
        hook.mode = "copy";
        packages = [];
        commands = [];
        inherit __functor;
      };
      ghsettings =
        {
          packages = [];
          commands = [];
        }
        // (nixago-exts.ghsettings.${system} (import ./github.nix));
      conform =
        {
          packages = [pkgs.conform];
          commands = [];
        }
        // (nixago-exts.conform.${system} (import ./conform.nix));
      lefthook =
        {
          packages = [pkgs.lefthook];
          commands = [];
        }
        // (nixago-exts.lefthook.${system} (import ./lefthook.nix));
      # -----------------------------------------------------------------

      # --- Auxiliary Outputs -------------------------------------------
      inherit (nixago.lib.${system}) makeAll;

      devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
        inherit
          (makeAll [
            treefmt
            editorconfig
            (ghsettings {
              repository = {
                name = "nixagii";
                description = "Nixago Pebbles for IOG";
                topics = "devshell, devx, sre";
                default_branch = "main";
              };
            })
            (conform {
              commit.conventional.scopes = data-merge.append (builtins.attrNames (
                builtins.removeAttrs self ((builtins.attrNames self.sourceInfo) ++ ["sourceInfo" "outputs" "inputs"])
              ));
            })
            lefthook
          ])
          shellHook
          ;
        packages =
          []
          ++ treefmt.packages
          ++ editorconfig.packages
          ++ conform.packages
          ++ ghsettings.packages
          ++ lefthook.packages;
      };
      # -----------------------------------------------------------------
    }
  ));
}
