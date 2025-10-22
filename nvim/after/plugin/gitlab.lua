
local wk = require("which-key")
local gitlab = require("gitlab")
local gitlab_server = require("gitlab.server")

-- Register the keymaps under the "<leader>g" prefix
wk.register({
  g = {
    name = " GitLab", -- Group name
    -- Merge Request Actions
    m = {
      name = "Merge Request",
      c = { gitlab.create_mr, "Create MR" },
      s = { gitlab.summary, "View Summary" },
      o = { gitlab.choose_merge_request, "Open/Choose MR" },
      r = { gitlab.review, "Start Review" },
      a = { gitlab.approve, "Approve MR" },
      R = { gitlab.revoke, "Revoke Approval" },
      M = { gitlab.merge, "Merge MR" },
      b = { gitlab.open_in_browser, "Open in Browser" },
      y = { gitlab.copy_mr_url, "Copy (Yank) MR URL" },
    },
    -- Discussions and Notes
    d = {
      name = "󰭻 Discussions",
      d = { gitlab.toggle_discussions, "Toggle Discussions Panel" },
      n = { gitlab.create_note, "Create Note" },
      t = { gitlab.toggle_draft_mode, "Toggle Draft Mode" },
      P = { gitlab.publish_all_drafts, "Publish All Drafts" },
    },
    -- Users: Assignees and Reviewers
    u = {
      name = "Users",
      a = { gitlab.add_assignee, "Add Assignee" },
      d = { gitlab.delete_assignee, "Delete Assignee" },
      r = { gitlab.add_reviewer, "Add Reviewer" },
      R = { gitlab.delete_reviewer, "Delete Reviewer" },
    },
    -- Labels
    l = {
      name = " Labels",
      a = { gitlab.add_label, "Add Label" },
      d = { gitlab.delete_label, "Delete Label" },
    },
    -- Pipeline
    p = { gitlab.pipeline, "View Pipeline" },
    -- Plugin/Server Management
    S = {
      name = " Server/Plugin",
      r = { gitlab_server.restart, "Restart Go Server" },
      p = { gitlab.print_settings, "Print Settings" },
    },
  },
}, { prefix = "<leader>" })
