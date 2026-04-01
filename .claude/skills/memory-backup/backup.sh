#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0
if [[ "${1-}" == "--dry-run" ]]; then
  DRY_RUN=1
elif [[ $# -gt 0 ]]; then
  printf 'Unsupported argument: %s\n' "$1" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -f "$SOURCE_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  . "$SOURCE_DIR/.env"
  set +a
fi

BACKUP_DIR="${MEMORY_BACKUP_DIR:-}"

if [[ -z "$BACKUP_DIR" ]]; then
  printf 'MEMORY_BACKUP_DIR is not set. Add it to the environment or %s/.env\n' "$SOURCE_DIR" >&2
  exit 1
fi

resolve_path() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

SOURCE_DIR_REAL="$(resolve_path "$SOURCE_DIR")"
BACKUP_DIR_REAL="$(resolve_path "$BACKUP_DIR")"

if [[ ! -d "$BACKUP_DIR_REAL" ]]; then
  printf 'Backup directory does not exist: %s\n' "$BACKUP_DIR_REAL" >&2
  exit 1
fi

if [[ ! -d "$BACKUP_DIR_REAL/.git" ]]; then
  printf 'Backup directory is not a Git repo: %s\n' "$BACKUP_DIR_REAL" >&2
  exit 1
fi

if [[ -n "$(git -C "$BACKUP_DIR_REAL" status --porcelain)" ]]; then
  printf 'Backup repo has uncommitted changes: %s\n' "$BACKUP_DIR_REAL" >&2
  exit 1
fi

if [[ "$SOURCE_DIR_REAL" == "$BACKUP_DIR_REAL" ]]; then
  printf 'Backup directory must be different from the source workspace.\n' >&2
  exit 1
fi

case "$BACKUP_DIR_REAL" in
  "$SOURCE_DIR_REAL"/*)
    printf 'Backup directory cannot live inside the source workspace.\n' >&2
    exit 1
    ;;
esac

copy_path() {
  local relative_path="$1"
  local source_path="$SOURCE_DIR_REAL/$relative_path"
  local dest_path="$BACKUP_DIR_REAL/$relative_path"

  remove_path() {
    python3 - "$1" <<'PY'
import os
import shutil
import sys

path = sys.argv[1]
if os.path.isdir(path) and not os.path.islink(path):
    shutil.rmtree(path)
elif os.path.lexists(path):
    os.unlink(path)
PY
  }

  if [[ -d "$source_path" ]]; then
    if [[ -f "$dest_path" || -L "$dest_path" ]]; then
      remove_path "$dest_path"
    fi
    mkdir -p "$dest_path"
    rsync -a --delete "$source_path/" "$dest_path/"
    printf 'Synced %s\n' "$relative_path"
  elif [[ -f "$source_path" ]]; then
    if [[ -d "$dest_path" ]]; then
      remove_path "$dest_path"
    fi
    mkdir -p "$(dirname "$dest_path")"
    rsync -a "$source_path" "$dest_path"
    printf 'Synced %s\n' "$relative_path"
  else
    if [[ -e "$dest_path" || -L "$dest_path" ]]; then
      remove_path "$dest_path"
    fi
    printf 'Skipped missing %s\n' "$relative_path"
  fi
}

if [[ $DRY_RUN -eq 1 ]]; then
  printf 'Dry run only. No files will be changed.\n'
  printf 'Source: %s\n' "$SOURCE_DIR_REAL"
  printf 'Backup: %s\n' "$BACKUP_DIR_REAL"
  for path in CLAUDE.md TASKS.md memory; do
    if [[ -e "$SOURCE_DIR_REAL/$path" ]]; then
      printf 'Would sync %s\n' "$path"
    else
      printf 'Would skip missing %s\n' "$path"
    fi
  done
  exit 0
fi

copy_path "CLAUDE.md"
copy_path "TASKS.md"
copy_path "memory"

git -C "$BACKUP_DIR_REAL" add -A -- CLAUDE.md TASKS.md memory

if git -C "$BACKUP_DIR_REAL" diff --cached --quiet -- CLAUDE.md TASKS.md memory; then
  printf 'No backup changes to commit.\n'
  exit 0
fi

SOURCE_REV="no-git"
if git -C "$SOURCE_DIR_REAL" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  SOURCE_REV="$(git -C "$SOURCE_DIR_REAL" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %z')"
COMMIT_MSG="memory-backup: $TIMESTAMP from $SOURCE_REV"

git -C "$BACKUP_DIR_REAL" commit -m "$COMMIT_MSG"
git -C "$BACKUP_DIR_REAL" push

printf 'Backup complete.\n'
