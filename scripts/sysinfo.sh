#!/usr/bin/env bash
set -euo pipefail

echo "User:            $(id -un) (effective UID $(id -u))"
echo "Hostname:        $(hostname)"
echo "Kernel release:  $(uname -r)"
echo "Date (ISO-8601): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo
echo "Disk usage:"
df -h /
echo
echo "Memory usage:"
free -h
echo
if docker info >/dev/null 2>&1; then
  echo "Docker daemon:   running"
else
  echo "Docker daemon:   not running or not reachable"
fi
