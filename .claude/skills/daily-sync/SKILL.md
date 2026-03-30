---
name: daily-sync
description: Collect 3 daily standup answers and post them as a reply in the correct team thread.
tools: [Bash, question]
---

# Skill: daily-sync

Post a structured daily update to the active daily thread in `<DAILY_SYNC_CHANNEL_NAME>`.

## Channel

- Channel: `<DAILY_SYNC_CHANNEL_NAME>`
- Channel ID: `<DAILY_SYNC_CHANNEL_ID>`

## Required Questions (ask exactly these 3)

1. What did you complete since the last update?
2. What are you focusing on today?
3. Any blockers or dependencies?

Ask these one-by-one (or as one 3-part prompt), collect answers, then post once all 3 are answered.

## Thread Selection ("correct thread")

Use the Slack CLI from `read-slack` skill:

1. Get recent parent-thread candidates:
```bash
node .claude/skills/read-slack/slack-cli.js threads <DAILY_SYNC_CHANNEL_ID> --days 2 --limit 50 --json
```
2. Optionally validate recent reply style from your prior updates:
```bash
node .claude/skills/read-slack/slack-cli.js thread-scan <DAILY_SYNC_CHANNEL_ID> --parent-pattern "daily standup" --reply-user <YOUR_SLACK_USER_ID> --reply-pattern ":white_check_mark:|:hammer:|:construction:" --days 14 --json
```
3. Choose the best match in this order:
   - Text matches `daily sync`, `standup`, or `daily update`
   - Posted today
   - Highest reply activity
4. If multiple candidates are still ambiguous, ask the user to choose one.
5. If no suitable thread is found, ask user for thread link/ts and do not post blindly.

## Posting Format

Post this structure as one threaded reply:

```text
:white_check_mark: Yesterday: 
<answer 1>

:hammer: Today: 
<answer 2>

:construction: Blockers: 
<answer 3 or "None">
```

Then send using:

```bash
node .claude/skills/read-slack/slack-cli.js send <DAILY_SYNC_CHANNEL_ID> "<formatted message>" --thread-ts <thread_ts>
```

## Response Back to User

After posting, report:
- Thread used (`thread_ts`)
- Message timestamp returned by Slack
- A short confirmation that the update was posted successfully
