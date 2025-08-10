#!/usr/bin/env python3
"""Print configured model backends before launching services."""

from pathlib import Path
import yaml


def main() -> None:
    cfg_file = Path(__file__).resolve().parent.parent / "config" / "models.yaml"
    with cfg_file.open() as f:
        data = yaml.safe_load(f) or {}
    models = data.get("models", {})
    if not models:
        print("No models configured.")
        return
    print("Configured models:")
    for name, info in models.items():
        backend = info.get("backend", "unknown")
        url = info.get("backend_url", "unknown")
        print(f"- {name}: backend={backend} url={url}")


if __name__ == "__main__":
    main()
