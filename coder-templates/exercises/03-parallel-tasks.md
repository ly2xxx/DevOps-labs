# Exercise 3: Parallel Task Execution

## Objective
Learn how to run multiple Coder Tasks in parallel for faster development.

## Prerequisites
- Completed Exercises 1 and 2
- Understanding of workspace management

## Why Parallel Tasks?

Running tasks in parallel allows you to:
- Speed up code reviews
- Fix multiple issues simultaneously
- Build multiple features at once
- Run tests across different environments

## Steps

### 1. Create Worktrees for Each Task

When fixing multiple issues, use git worktrees for isolation:
```bash
# Create worktrees for different issues
git worktree add -b fix/issue-78 /tmp/issue-78 main
git worktree add -b fix/issue-99 /tmp/issue-99 main
```

### 2. Launch Multiple Tasks in Parallel
```bash
# Start task for issue 78 (in background)
coder tasks create \
  --workspace dev-lab \
  --preset "default" \
  "Fix issue #78: Implement user authentication module" &

# Start task for issue 99 (in background)
coder tasks create \
  --workspace dev-lab \
  --preset "default" \
  "Fix issue #99: Add error handling to API calls" &
```

### 3. Monitor All Tasks
```bash
# List all running tasks
coder tasks list

# Watch multiple logs
coder tasks logs task-78 &
coder tasks logs task-99 &
```

### 4. Review Results

```bash
# Check each task's output
coder tasks logs issue-78
coder tasks logs issue-99
```

### 5. Create Pull Requests

```bash
# Push fixes and create PRs
cd /tmp/issue-78
git push -u origin fix/issue-78
gh pr create --repo user/repo --head fix/issue-78 \
  --title "fix: User authentication module" \
  --body "Fixed issue #78"

cd /tmp/issue-99
git push -u origin fix/issue-99
gh pr create --repo user/repo --head fix/issue-99 \
  --title "fix: API error handling" \
  --body "Fixed issue #99"
```

### 6. Clean Up Worktrees
```bash
# Remove worktrees after use
git worktree remove /tmp/issue-78
git worktree remove /tmp/issue-99
```

## Practical Example: Code Review

```bash
# Fetch all PR refs
git fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*'

# Deploy agents to review PRs in parallel
coder tasks create --workspace review --preset "" \
  "Review PR #86: Check for security vulnerabilities"

coder tasks create --workspace review --preset "" \
  "Review PR #87: Verify tests pass"

coder tasks create --workspace review --preset "" \
  "Review PR #88: Check code style compliance"

# Monitor all
coder tasks list

# Collect reviews and post to GitHub
coder tasks logs pr-86 > review-86.txt
coder tasks logs pr-87 > review-87.txt
coder tasks logs pr-88 > review-88.txt

gh pr comment 86 --body "$(cat review-86.txt)"
gh pr comment 87 --body "$(cat review-87.txt)"
gh pr comment 88 --body "$(cat review-88.txt)"
```

## Best Practices

1. **Use worktrees**: Keep branches isolated
2. **Limit parallelism**: Don't overwhelm resources
3. **Track task names**: Use consistent naming
4. **Aggregate results**: Collect and summarize outputs
5. **Clean up**: Delete tasks and worktrees after use

## Troubleshooting

- **Resource exhaustion**: Limit parallel tasks to 3-5
- **Conflicting changes**: Use separate worktrees
- **Lost output**: Save logs to files

## Integration with OpenClaw

From OpenClaw, you can orchestrate this:

```bash
# In OpenClaw using exec
bash pty:true workdir:/tmp/issue-78 background:true command:"codex --yolo 'Fix issue #78'"
bash pty:true workdir:/tmp/issue-99 background:true command:"codex --yolo 'Fix issue #99'"

# Monitor
process action:list

# Check progress
process action:log sessionId:XXX
```