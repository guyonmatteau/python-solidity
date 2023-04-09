import toml


def get_config(file: str = None, path: str = None) -> dict:
    """Read config in .toml format)."""
    if file is not None:
        return toml.load(f"conf/{file}.toml")
    return toml.load(path)
