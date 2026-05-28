import os
import yaml


def load_config(path: str = "config.yaml") -> dict:
    with open(path) as f:
        cfg = yaml.safe_load(f)

    overrides = {
        ("navidrome", "url"): "NAVIDROME_URL",
        ("navidrome", "username"): "NAVIDROME_USERNAME",
        ("navidrome", "password"): "NAVIDROME_PASSWORD",
        ("web", "secret_key"): "WEB_SECRET_KEY",
    }
    for (section, key), env_var in overrides.items():
        if env_var in os.environ:
            cfg[section][key] = os.environ[env_var]

    return cfg
