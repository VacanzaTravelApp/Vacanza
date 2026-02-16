"""Run SQL migrations on application startup."""

import logging
from pathlib import Path

import psycopg2

logger = logging.getLogger(__name__)

MIGRATIONS_DIR = Path(__file__).resolve().parent.parent.parent / "migrations"


def run_migrations(database_url: str) -> None:
    """Execute SQL migration files in alphabetical order.

    Args:
        database_url: PostgreSQL connection string.
    """
    if not MIGRATIONS_DIR.exists():
        logger.warning("Migrations directory not found: %s", MIGRATIONS_DIR)
        return

    sql_files = sorted(MIGRATIONS_DIR.glob("*.sql"))
    if not sql_files:
        logger.info("No migration files found")
        return

    try:
        conn = psycopg2.connect(database_url)
        conn.autocommit = True
        cur = conn.cursor()

        for filepath in sql_files:
            logger.info("Running migration: %s", filepath.name)
            sql_content = filepath.read_text(encoding="utf-8")
            cur.execute(sql_content)

        cur.close()
        conn.close()
        logger.info("Migrations completed successfully")
    except psycopg2.Error as e:
        logger.error("Migration failed: %s", e)
        raise
