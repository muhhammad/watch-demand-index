"""Local dev entry point: uvicorn api.main:app --reload --port 8000"""
from api.app import app  # noqa: F401