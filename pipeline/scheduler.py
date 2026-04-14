"""
Pipeline scheduler.

Schedule:
  - Chrono24 + index build: daily at 02:00 UTC
  - Phillips auction scrape: daily at 03:00 UTC
  - Watchlist alert digests: daily at 04:00 UTC
"""
import logging
import subprocess
import sys
from pathlib import Path

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

logger = logging.getLogger(__name__)
scheduler = AsyncIOScheduler(timezone="UTC")
PROJECT_ROOT = Path(__file__).resolve().parent.parent


def _run_script(module: str) -> None:
    result = subprocess.run(
        [sys.executable, "-m", module],
        cwd=str(PROJECT_ROOT),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        logger.error("Pipeline module %s failed:\n%s", module, result.stderr)
    else:
        logger.info("Pipeline module %s completed:\n%s", module, result.stdout)


async def _run_chrono24_pipeline() -> None:
    logger.info("Scheduled: starting Chrono24 pipeline")
    try:
        _run_script("pipeline.run_pipeline")
        _run_script("pipeline.index.build_watch_index")
        _run_script("pipeline.index.build_brand_index")
        _run_script("pipeline.index.build_market_index")
        logger.info("Scheduled: Chrono24 pipeline complete")
    except Exception as exc:
        logger.error("Scheduled pipeline error: %s", exc)


async def _run_phillips_scrape() -> None:
    logger.info("Scheduled: starting Phillips scrape")
    try:
        _run_script("pipeline.collectors.phillips")
        logger.info("Scheduled: Phillips scrape complete")
    except Exception as exc:
        logger.error("Scheduled Phillips scrape error: %s", exc)


async def _run_alerts() -> None:
    logger.info("Scheduled: sending watchlist alert digests")
    try:
        _run_script("pipeline.alerts")
        logger.info("Scheduled: alert digests complete")
    except Exception as exc:
        logger.error("Scheduled alert error: %s", exc)


def start_scheduler() -> None:
    scheduler.add_job(_run_chrono24_pipeline, CronTrigger(hour=2, minute=0),
                      id="chrono24_pipeline", name="Daily Chrono24 pipeline", replace_existing=True)
    scheduler.add_job(_run_phillips_scrape, CronTrigger(hour=3, minute=0),
                      id="phillips_scrape", name="Daily Phillips scrape", replace_existing=True)
    scheduler.add_job(_run_alerts, CronTrigger(hour=4, minute=0),
                      id="watchlist_alerts", name="Daily watchlist alert digests", replace_existing=True)
    scheduler.start()
    logger.info("Pipeline scheduler started — Chrono24 02:00, Phillips 03:00, Alerts 04:00 UTC")


def stop_scheduler() -> None:
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("Pipeline scheduler stopped")
