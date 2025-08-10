import os
import subprocess
import time
from pathlib import Path

import pytest
import requests

ROOT = Path(__file__).resolve().parent.parent


def _has_docker() -> bool:
    """Return True if docker CLI is available and daemon is running."""
    try:
        subprocess.run(["docker", "info"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception:
        return False


@pytest.mark.skipif(not _has_docker(), reason="docker is required for this test")
def test_vllm_container_healthy():
    env = os.environ.copy()
    env.setdefault("VLLM_MODEL", "facebook/opt-125m")
    env.setdefault("VLLM_PORT", "8000")

    up_cmd = [
        "docker",
        "compose",
        "-f",
        "vllm/compose.yaml",
        "--profile",
        "cuda",
        "up",
        "-d",
        "gateway",
    ]
    down_cmd = [
        "docker",
        "compose",
        "-f",
        "vllm/compose.yaml",
        "--profile",
        "cuda",
        "down",
        "-v",
    ]

    try:
        subprocess.run(up_cmd, cwd=ROOT, env=env, check=True)
        url = "http://localhost:8080/healthz"
        for _ in range(60):
            try:
                resp = requests.get(url, timeout=1)
                if resp.status_code == 200:
                    break
            except requests.exceptions.RequestException:
                time.sleep(1)
        else:
            pytest.fail("gateway did not become healthy")
    finally:
        subprocess.run(down_cmd, cwd=ROOT, env=env, check=False)
