import time

import pytest
from pydantic import ValidationError

from api.registry import Registry


def test_registry_reload(tmp_path):
    cfg = tmp_path / "models.yaml"
    cfg.write_text("models:\n  a:\n    service_url: http://one\n")
    reg = Registry(str(cfg))
    assert "a" in reg.models
    time.sleep(0.1)
    cfg.write_text("models:\n  b:\n    service_url: http://two\n")
    reg.maybe_reload()
    assert "b" in reg.models
    assert "a" not in reg.models


def test_registry_invalid(tmp_path):
    cfg = tmp_path / "models.yaml"
    cfg.write_text("models:\n  a:\n    service_url: http://one\n")
    reg = Registry(str(cfg))
    time.sleep(0.1)
    cfg.write_text("models:\n  bad:\n    foo: bar\n")
    with pytest.raises(ValidationError):
        reg.maybe_reload()
    assert "a" in reg.models
