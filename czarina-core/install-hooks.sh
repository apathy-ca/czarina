#!/bin/bash
# Install git hooks in worker worktrees

CZARINA_DIR="${1:-.czarina}"
PROJECT_ROOT="${2:-.}"

for worktree in "${CZARINA_DIR}/worktrees/"*/; do
    if [ -d "$worktree/.git" ]; then
        cp "${PROJECT_ROOT}/czarina-core/hooks/post-commit" "${worktree}/.git/hooks/"
        chmod +x "${worktree}/.git/hooks/post-commit"
        echo "✅ Installed hooks in $(basename $worktree)"
    fi
done
