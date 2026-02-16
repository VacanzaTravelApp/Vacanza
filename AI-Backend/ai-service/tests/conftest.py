"""Pytest configuration."""

import os

# Skip migrations when running tests (no DB required)
# Must run before app is imported
os.environ.setdefault("RUN_MIGRATIONS", "false")
