from __future__ import annotations

import os
from pathlib import Path
from typing import Dict

import yaml
from pydantic import BaseModel, Field, ValidationError


class ModelConfig(BaseModel):
    """Configuration for a single model backend."""

    service_url: str
    embeddings: bool = False
    headers: Dict[str, str] = Field(default_factory=dict)
    env: Dict[str, str] = Field(default_factory=dict)
    limits: Dict[str, int] = Field(default_factory=dict)


class ModelsConfig(BaseModel):
    models: Dict[str, ModelConfig] = Field(default_factory=dict)


class Registry:
    """Hot-reloading model registry backed by a YAML file."""

    def __init__(self, path: str) -> None:
        self.path = Path(path)
        self.mtime: float = 0.0
        self.models: Dict[str, ModelConfig] = {}
        self.load()

    def load(self) -> None:
        """Load and validate the config file."""
        data = yaml.safe_load(self.path.read_text()) if self.path.exists() else {}
        cfg = ModelsConfig(**data)
        self.models = cfg.models
        self.mtime = self.path.stat().st_mtime
        # Apply environment variables defined under each model.
        for model in self.models.values():
            for key, value in model.env.items():
                os.environ.setdefault(key, value)

    def maybe_reload(self) -> None:
        """Reload the config file if it has changed."""
        if not self.path.exists():
            return
        mtime = self.path.stat().st_mtime
        if mtime <= self.mtime:
            return
        try:
            self.load()
        except ValidationError as exc:  # keep old config on error
            # re-raise to allow caller to log or handle if desired
            raise exc


__all__ = ["ModelConfig", "Registry"]
