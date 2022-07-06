let
  s = import ./github-bis.nix;
in {
  types = [
    # in GH = in Jira
    ["${s.types.bug.name}" "Bug"]
    ["${s.types.story.name}" "Story"]
    ["${s.types.maintenance.name}" "Maintenance"]
    ["${s.types.question.name}" "Question"]
    ["${s.types.security.name}" "Security"]
    # Pull request
    ["Pull" "Task"]
    # Milestone
    ["Milestone" "Epic"]
  ];
}
