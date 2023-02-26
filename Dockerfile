FROM python:3.11-slim-bullseye as wheel-builder

COPY src /src
COPY README.md /
COPY poetry.lock /poetry.lock
COPY pyproject.toml /pyproject.toml
COPY constraints.txt /constraints.txt

# build the wheel
RUN --mount=type=cache,target=/root/.cache/pip pip install --upgrade pip twine build --constraint /constraints.txt
RUN --mount=type=cache,target=/root/.cache/pip python -m build --sdist --wheel --outdir /dist/
RUN twine check /dist/*



FROM python:3.11-slim AS builder
WORKDIR /app

# install build requirements
RUN apt-get update && apt-get install -y binutils patchelf upx build-essential scons
RUN pip install --no-warn-script-location --upgrade pyinstaller staticx

# copy the app
COPY src ./src
COPY README.md ./
COPY poetry.lock ./
COPY pyproject.toml ./
COPY constraints.txt ./

## build the app
# install requirements
RUN pip install -r constraints.txt
RUN poetry export -f requirements.txt > requirements.txt
RUN pip install -r requirements.txt

# pyinstaller package the app
RUN python -OO -m PyInstaller -F src/auto_annotator/auto_annotator.py --name auto-annotator
# static link the repo-manager binary
RUN cd ./dist && \
    staticx auto-annotator auto-annotator-static
# will be copied over to the scratch container, pyinstaller needs a /tmp to exist
RUN mkdir /app/tmp


FROM scratch

ENTRYPOINT ["/auto-annotator"]

COPY --from=builder /app/dist/auto-annotator-static /auto-annotator
COPY --from=builder /app/tmp /tmp
