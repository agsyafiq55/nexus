# Work Assistant (Claude Code + Skills)

This repository is a personal work assistant setup for Claude Code.  
It helps you capture and organize work across email, Slack, calendar, and meeting notes into a simple file-based task system under `memory/`.

## Important First Step

Before using this repo, update your profile and channels in `CLAUDE.md`:

- `## About Me`
- `### Slack Channels`

These sections are user-specific and should reflect your own identity, team context, and channel IDs.

## What This Assistant Does

- Tracks tasks in markdown files (`memory/tasks/TASK-*.md`)
- Keeps project context in `memory/projects/`
- Keeps people context in `memory/people/`
- Syncs context from multiple sources and turns it into actionable follow-ups
- Uses Claude Code skills for repeatable workflows

## Included Skills (Repo)

These are the core skills in `.claude/skills/`:

| Skill | What it does |
|---|---|
| `read-email` | Uses `gog` to search/read Gmail threads, summarize senders/subjects, and surface action items. |
| `read-calendar` | Uses `gog` to view calendar events, availability, conflicts, and meeting details. |
| `read-slack` | Uses `slack-cli.js` with Slack Web API to list channels, read messages/threads, and send messages. |
| `read-granola` | Uses `granola-cli.py` to read/search local Granola meeting notes and transcripts. |
| `work-sync` | Main aggregation workflow: reads all sources, updates `memory/tasks/`, and maintains `projects/` and `people/` context. |
| `work-tasks` | Displays pending tasks with optional filtering (priority, status views, quick summaries). |

## Repository Structure

```text
.
├── CLAUDE.md
├── .claude/
│   └── skills/
│       ├── read-calendar/
│       ├── read-email/
│       ├── read-granola/
│       ├── read-slack/
│       ├── work-sync/
│       └── work-tasks/
└── memory/
    ├── MEMORY.md
    ├── tasks/
    ├── projects/
    └── people/
```

## Prerequisites

- Claude Code / Cursor setup
- macOS (current setup target)
- `node` (for Slack CLI helper)
- Slack Web API package (required by `.claude/skills/read-slack/slack-cli.js`):
  - `npm install @slack/web-api`
- `python3` (for Granola CLI helper)
- `gog` CLI for Gmail/Calendar:
  - `brew install gogcli`
- Auth configured for each source:
  - Google (`gog auth ...`)
  - Slack user token (`SLACK_TOKEN`, usually starts with `xoxp-`)

## Typical Workflow

1. Run `/work-sync` to pull latest context from all sources.
2. Review current priorities with `/work-tasks`.
3. Focus on high-priority tasks (`/work-tasks high`).
4. Repeat sync after key meetings or message bursts.

## Notes

- Task files are intentionally plain markdown for easy review and git history.
- Calendar is treated as context (events/deadlines), not an automatic task generator.
- Completed tasks can be archived by the sync workflow into `memory/tasks/completed/`.
