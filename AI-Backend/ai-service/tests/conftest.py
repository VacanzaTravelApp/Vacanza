"""Pytest configuration."""

import os

# Skip migrations when running tests (no DB required)
# Must run before app is imported
os.environ.setdefault("RUN_MIGRATIONS", "false")
# Allow /ai/test and /ai/embed in tests (defaults to off in production)
os.environ.setdefault("EXPOSE_AI_DEBUG_ROUTES", "true")
