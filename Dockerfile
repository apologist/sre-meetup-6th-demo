FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

WORKDIR /server

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project

ENV PATH="/server/.venv/bin:$PATH"

RUN python -c "import argostranslate.package; argostranslate.package.update_package_index()"
RUN python -c "import argostranslate.package; en_es = next((pkg for pkg in argostranslate.package.get_available_packages() if pkg.from_code == 'en' and pkg.to_code == 'es'), None); argostranslate.package.install_from_path(en_es.download()) if en_es else print('Package not found')"
RUN python -c "import argostranslate.package; es_en = next((pkg for pkg in argostranslate.package.get_available_packages() if pkg.from_code == 'es' and pkg.to_code == 'en'), None); argostranslate.package.install_from_path(es_en.download()) if es_en else print('Package not found')"

ADD . /server

CMD ["watchmedo", "auto-restart", \
    "--patterns=*.py", \
    "--recursive", \
    "--directory=.", \
    "--", \
    "uvicorn", \
    "app:app", \
    "--host", "0.0.0.0", \
    "--workers", "3", \
    "--loop", "uvloop"]
