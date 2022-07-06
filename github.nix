let
  s = import ./github-bis.nix;
  l = builtins;
in {
  labels =
    []
    ++ (l.attrValues s.statuses)
    ++ (l.attrValues s.types)
    ++ (l.attrValues s.priorities)
    ++ (l.attrValues s.effort);
}
