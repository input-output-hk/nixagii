{
  commit-msg = {
    commands = {
      conform = {
        run = "conform enforce --commit-msg-file {1}";
      };
    };
  };
  pre-commit = {
    commands = {
      treefmt = {
        run = "treefmt {staged_files}";
        glob = "*";
      };
    };
  };
}
