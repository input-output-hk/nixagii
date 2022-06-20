project: {
  inherit project;
  "custom-commands" = [
    {
      name = "ls-sre";
      help = "jira ls on 'Delivering Team = Resident SRE'";
      script = ''
        jira ls -q 'resolution = unresolved AND "Delivering Team[Dropdown]" = "Resident SRE" AND project = ${project} ORDER BY priority ASC, created'
      '';
    }
  ];
}
