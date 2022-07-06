/*
 
 This file implements GH workflows for the unidirectional synchornization
 from GitHub to Jira.
 
 The TL;DR; docs at time of writing are:
 ---------------------------------------
 
 Contexts -> Events -> [Issues|Pulls|Commits]
 
 Contexts: https://docs.github.com/en/actions/learn-github-actions/contexts
 -> Events: https://docs.github.com/en/developers/webhooks-and-events/webhooks/webhook-events-and-payloads
   -> Issues: https://docs.github.com/en/rest/issues/issues
   -> Pulls: https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request
   -> Commits: https://docs.github.com/en/rest/commits/commits#get-a-commit
 
 Synopsis:
 
 Accessor event:   `github.event`
 Accessor issue:   `github.event.issue`
 Accessor pull:    `github.event.pull`
 Accessor commits: `github.event.commits`
 
 The mapping strategy is explained on each job for issue|pull|commit events.
 */
project: let
  # the current environment
  JIRA_BASE_URL = "https://iog-uat.atlassian.net/";
  mappings = import ./gh-jira-integration-maps.nix;

  login-step = {
    name = "🔑 Login";
    uses = "atlassian/gajira-login@master";
    env = {
      inherit JIRA_BASE_URL;
      JIRA_USER_EMAIL = "\${{ secrets.JIRA_USER_EMAIL }}";
      JIRA_API_TOKEN = "\${{ secrets.JIRA_API_TOKEN }}";
    };
  };
  find-issue-key-within = expr: {
    id = "detect";
    continue-on-error = true;
    name = "🔍 Find Textual Issue Reference";
    uses = "atlassian/gajira-find-issue-key@master";
    "with" = {
      string = "\${{ ${expr} }}";
      from = "";
    };
  };
  create-issue-for = labels: args: {
    id = "create";
    "if" = "!steps.detect.outputs.issue";
    name = "🏗️  Create New Issue";
    uses = "atlassian/gajira-create@master";
    "with" =
      args
      // {
        issuetype = "\${{ ${builtins.concatStringsSep " || " (
          (builtins.map (
              t: let
                gh = builtins.elemAt t 0;
                ji = builtins.elemAt t 1;
              in "(contains(${labels}, '${gh}') && '${ji}')"
            )
            mappings.types)
          ++ ["'Story'"]
        )} }}";
        inherit project;
      };
  };
  transition-to = status: {
    id = "transition";
    name = "🚂 Transition to '${status}'";
    uses = "atlassian/gajira-transition@master";
    "with" = {
      issue = "\${{ steps.detect.outputs.issue || steps.create.outputs.issue }}";
      transition = status;
    };
  };
  reference-jira-issue-in = {
    url,
    title,
  }: {
    id = "reference";
    name = "🪴 Update Title with Jira Issue";
    "if" = "steps.create.outputs.issue";
    run = ''gh api --silent "''${{ ${url} }}" -f title="[''${{ steps.create.outputs.issue }}]: ''${{ ${title} }}"'';
    env.GITHUB_TOKEN = "\${{ secrets.GITHUB_TOKEN }}";
  };
  comment-with = comment: {
    id = "comment";
    name = "📝 Comment on issue";
    "if" = "steps.detect.outputs.issue || steps.create.outputs.issue";
    uses = "atlassian/gajira-comment@master";
    "with" = {
      issue = "\${{ steps.detect.outputs.issue || steps.create.outputs.issue }}";
      inherit comment;
    };
  };

  runs-on = "ubuntu-latest";

  openClose = ["opened" "closed"];
  openClose' = openClose ++ ["reopened"];
  labeledUnlabeled = ["labeled" "unlabeled"];
  milestonedUnmilestoned = ["labeled" "unlabeled"];

  isIssue = "github.event_name == 'issues'";
  isPull = "github.event_name == 'pull_request'";
  isMilestone = "github.event_name == 'milestone'";
  isPush = "github.event_name == 'push'";

  isCreated = "github.event.action == 'created'";

  isOpened = "github.event.action == 'opened'";
  isClosed = "github.event.action == 'closed'";

  isReopened = "github.event.action == 'reopened'";
  isLabeled = "github.event.action == 'labeled'";
  isMilestoned = "github.event.action == 'milestoned'";
  isDemilestoned = "github.event.action == 'demilestoned'";
in {
  # --------
  # Push
  # --------
  push = {
    on.push = {};
    name = "Jira Sync (push)";
    jobs = {
      "push" = {
        inherit runs-on;
        name = "Push Sync";
        "if" = "${isPush}";
        steps = [
          login-step
          (find-issue-key-within "join(github.event.commits.*.message, ' ')")
          (comment-with ''
            📝 - *''${{ github.event.pusher.name }}* mentioned this issue in a push to *''${{ github.event.repository.full_name }}*.
            🔍 - ''${{ github.event.compare }}
          '')
        ];
      };
    };
  };

  # --------
  # Issues
  # --------
  issues = {
    on.issues.types =
      openClose'
      # ++ labeledUnlabeled
      # ++ milestonedUnmilestoned
      ;
    name = "Jira Sync (issues)";
    jobs = {
      "issue-opened" = {
        inherit runs-on;
        name = "Issue Sync: opened";
        "if" = "${isIssue} && ${isOpened}";
        steps = [
          login-step
          # either ...
          (find-issue-key-within "github.event.issue.title")
          # or ...
          (create-issue-for "github.event.issue.labels.*.name" {
            summary = "\${{ github.event.issue.title }}";
            description = ''
              *Autocreated*
                - _Repo:_ ''${{ github.event.repository.html_url }}
                - _Link:_ ''${{ github.event.issue.html_url }}
            '';
          })
          (transition-to "In Progress")
          (reference-jira-issue-in {
            url = "github.event.issue.url";
            title = "github.event.issue.title";
          })
        ];
      };
      "issue-closed" = {
        inherit runs-on;
        name = "Issue Sync: closed";
        "if" = "${isIssue} && ${isClosed}";
        steps = [
          login-step
          (find-issue-key-within "github.event.issue.title")
          (transition-to "Done")
        ];
      };
      "issue-reopened" = {
        inherit runs-on;
        name = "Issue Sync: reopened";
        "if" = "${isIssue} && ${isReopened}";
        steps = [
          login-step
          (find-issue-key-within "github.event.issue.title")
          (transition-to "In Progress")
        ];
      };
    };
  };

  # --------
  # Pulls
  # --------
  pulls = {
    on.pull_request.types =
      openClose'
      # ++ labeledUnlabeled
      # ++ [
      #   "convert_to_draft"
      #   "ready_for_review"
      #   "review_requested"
      # ]
      ;
    name = "Jira Sync (pulls)";
    jobs = {
      "pull-opened" = {
        inherit runs-on;
        name = "Pull Sync: opened";
        "if" = "${isPull} && ${isOpened}";
        steps = [
          login-step
          # either ...
          (find-issue-key-within "github.event.pull_request.title")
          # or ...
          (create-issue-for "'Pull'" {
            summary = "\${{ github.event.pull_request.title }}";
            description = ''
              *Autocreated*
                - _Repo:_ ''${{ github.event.repository.html_url }}
                - _Link:_ ''${{ github.event.pull_request.html_url }}
            '';
          })
          (transition-to "In Progress")
          (reference-jira-issue-in {
            url = "github.event.pull_request.url";
            title = "github.event.pull_request.title";
          })
        ];
      };
      "pull-closed" = {
        inherit runs-on;
        name = "Pull Sync: closed";
        "if" = "${isPull} && ${isClosed}";
        steps = [
          login-step
          (find-issue-key-within "github.event.pull_request.title")
          (transition-to "Done")
        ];
      };
      "pull-reopened" = {
        inherit runs-on;
        name = "Pull Sync: reopened";
        "if" = "${isPull} && ${isReopened}";
        steps = [
          login-step
          (find-issue-key-within "github.event.pull_request.title")
          (transition-to "In Progress")
        ];
      };
    };
  };

  # --------
  # Milestones
  # --------
  milestones = {
    on.milestone.types = openClose ++ ["created"];
    name = "Jira Sync (milestone)";
    jobs = {
      "milestone-created" = {
        inherit runs-on;
        name = "Milestone Sync: created";
        "if" = "${isMilestone} && ${isCreated}";
        steps = [
          login-step
          # either ...
          (find-issue-key-within "github.event.milestone.title")
          # or ...
          (create-issue-for "'Milestone'" {
            summary = "\${{ github.event.milestone.title }}";
            description = ''
              *Autocreated*
                - _Repo:_ ''${{ github.event.repository.html_url }}
                - _Link:_ ''${{ github.event.milestone.html_url }}

              ---

              ''${{ github.event.milestone.title }}
            '';
            fields = builtins.toJSON {
              customfield_10011 = "\${{ github.event.milestone.title }}";
            };
          })
          (transition-to "In Progress")
          (reference-jira-issue-in {
            url = "github.event.milestone.url";
            title = "github.event.milestone.title";
          })
        ];
      };
      "milestone-closed" = {
        inherit runs-on;
        name = "Milestone Sync: closed";
        "if" = "${isMilestone} && ${isClosed}";
        steps = [
          login-step
          (find-issue-key-within "github.event.milestone.title")
          (transition-to "Done")
        ];
      };
    };
  };
}
