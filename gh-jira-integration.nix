project: {
  on = "push";

  name = "Jira Sync";

  jobs = {
    build = {
      runs-on = "ubuntu-latest";
      name = "Jira Example";
      steps = [
        {
          name = "Login";
          uses = "atlassian/gajira-login@master";
          env = {
            JIRA_BASE_URL = "\${{ secrets.JIRA_BASE_URL }}";
            JIRA_USER_EMAIL = "\${{ secrets.JIRA_USER_EMAIL }}";
            JIRA_API_TOKEN = "\${{ secrets.JIRA_API_TOKEN }}";
          };
        }
        {
          name = "Jira TODO";
          uses = "atlassian/gajira-todo@master";
          "with" = {
            inherit project;
            issuetype = "Task";
            description = "Created automatically via GitHub Actions";
          };
          env = {
            GITHUB_TOKEN = "\${{ secrets.GITHUB_TOKEN }}";
          };
        }
        {
          name = "Create";
          id = "create";
          uses = "atlassian/gajira-create@master";
          "with" = {
            inherit project;
            issuetype = "Build";
            summary = "Build completed for \${{ github.repository }}";
            description = "Compare branch";
            fields = builtins.toJSON {
              customfield_10171 = "test";
            };
          };
        }
        {
          name = "Log created issue";
          run = ''echo "Issue ''${{ steps.create.outputs.issue }} was created"'';
        }
        {
          name = "Transition issue";
          id = "transition";
          uses = "atlassian/gajira-transition@master";
          "with" = {
            issue = "\${{ steps.create.outputs.issue }}";
            transition = "In progress";
          };
        }
      ];
    };
  };
}
