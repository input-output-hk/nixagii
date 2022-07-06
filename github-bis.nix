let
  colors = {
    black = "#000000";
    blue = "#1565C0";
    lightBlue = "#64B5F6";
    green = "#4CAF50";
    grey = "#A6A6A6";
    lightGreen = "#81C784";
    gold = "#FDD835";
    orange = "#FB8C00";
    purple = "#AB47BC";
    red = "#F44336";
    yellow = "#FFEE58";
  };
in {
  statuses = {
    abandoned = {
      name = "Status: Abdandoned";
      description = "This issue has been abdandoned";
      color = colors.black;
    };
    accepted = {
      name = "Status: Accepted";
      description = "This issue has been accepted";
      color = colors.green;
    };
    available = {
      name = "Status: Available";
      description = "This issue is available for assignment";
      color = colors.lightGreen;
    };
    blocked = {
      name = "Status: Blocked";
      description = "This issue is in a blocking state";
      color = colors.red;
    };
    inProgress = {
      name = "Status: In Progress";
      description = "This issue is actively being worked on";
      color = colors.grey;
    };
    onHold = {
      name = "Status: On Hold";
      description = "This issue is not currently being worked on";
      color = colors.red;
    };
    pending = {
      name = "Status: Pending";
      description = "This issue is in a pending state";
      color = colors.yellow;
    };
    reviewNeeded = {
      name = "Status: Review Needed";
      description = "This issue is pending a review";
      color = colors.gold;
    };
  };
  types = {
    bug = {
      name = "Type: Bug";
      description = "This issue targets a bug";
      color = colors.red;
    };
    story = {
      name = "Type: Story";
      description = "This issue targets a new feature through a story";
      color = colors.lightBlue;
    };
    maintenance = {
      name = "Type: Maintenance";
      description = "This issue targets general maintenance";
      color = colors.orange;
    };
    question = {
      name = "Type: Question";
      description = "This issue contains a question";
      color = colors.purple;
    };
    security = {
      name = "Type: Security";
      description = "This issue targets a security vulnerability";
      color = colors.red;
    };
  };
  priorities = {
    critical = {
      name = "Priority: Critical";
      description = "This issue is prioritized as critical";
      color = colors.red;
    };
    high = {
      name = "Priority: High";
      description = "This issue is prioritized as high";
      color = colors.orange;
    };
    medium = {
      name = "Priority: Medium";
      description = "This issue is prioritized as medium";
      color = colors.yellow;
    };
    low = {
      name = "Priority: Low";
      description = "This issue is prioritized as low";
      color = colors.green;
    };
  };
  effort = {
    "1" = {
      name = "Effort: 1";
      description = "This issue is of low complexity or very well understood";
      color = colors.green;
    };
    "2" = {
      name = "Effort: 2";
      description = "This issue is still almost of low complexity or still almost well understood";
      color = colors.lightGreen;
    };
    "3" = {
      name = "Effort: 3";
      description = "This issue is of medium complexity or only partly well understood";
      color = colors.yellow;
    };
    "4" = {
      name = "Effort: 4";
      description = "This issue is still almost of medium complexity or only partly understood";
      color = colors.orange;
    };
    "5" = {
      name = "Effort: 5";
      description = "This issue is of high complexity or just not yet well understood";
      color = colors.red;
    };
  };
}
