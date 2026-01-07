# AGENTS.md

This repository builds a small Docker image that wraps Lisa Melton’s
[`other_video_transcoding`](https://github.com/lisamelton/other_video_transcoding) Ruby scripts
(specifically `other-transcode.rb`) and runs them in **batch mode** using a simple queue file.

The intent is: run on a NAS/always-on host, mount media + output volumes, pass through an Intel iGPU,
then let the container drain a queue of files to transcode.

## What gets built

### Dockerfile (image contents)

* Base image: `ubuntu:questing`
* Installs runtime dependencies:
  * `ffmpeg` (actual transcoding)
  * VA-API tooling/drivers: `vainfo`, `intel-media-va-driver-non-free`, `libvpl2`, `libvpl-dev`
  * `mkvtoolnix` (used by upstream scripts for container/metadata tasks)
  * `ruby` (upstream scripts are Ruby)
  * `git` + `ca-certificates` (to clone upstream at build time)
* Creates:
  * `/output` (working/output directory; also set as `WORKDIR`)
  * `/app` (scripts live here)
* Clones upstream at build time and copies `*.rb` into `/app`:
  * `git clone --depth 1 https://github.com/lisamelton/other_video_transcoding.git`
  * `cp /tmp/other_video_transcoding/*.rb /app/`

### Entrypoint

The image entrypoint is:

* `ENTRYPOINT ["/app/batch.rb"]`

So the container always runs the local `batch.rb` loop, passing any Docker arguments through as
arguments to `/app/other-transcode.rb`.

### Default transcoding options

The default `CMD` is:

```
--add-audio eng --vaapi --hevc --10-bit --add-subtitle eng
```

At runtime, you typically override/extend these by adding args to `docker run ... <args>`.

## How batch mode works

`batch.rb` reads a plain text file at:

* `/mnt/media/queue.txt`

Format: **one absolute path per line**.

Algorithm (high level):

1. Read `queue.txt`
2. Take the first line as the next input path
3. Rewrite `queue.txt` without that first line
4. Run: `/app/other-transcode.rb <your args> <input>`
5. Repeat until the queue is empty or a transcode fails

Notes for maintainers:

* The queue is rewritten **before** invoking the transcode command; if a transcode fails, the failed
  item will already have been removed from the queue.
* The script runs in the container as the configured non-root user (see UID/GID below).

## Runtime requirements

### Volumes

* Mount your media volume to `/mnt/media`
* Mount your output directory to `/output`

The queue file must be available at:

* `/mnt/media/queue.txt`

### Intel VA-API device passthrough

For VA-API hardware encoding you must pass the DRM device nodes through, typically:

* `--device /dev/dri:/dev/dri`

(Host specifics vary; on many systems `/dev/dri/renderD128` is what matters.)

### User mapping (UID/GID)

The Dockerfile supports build args:

* `UID` (default `99`)
* `GID` (default `100`)

The image `chown`s `/output` and `/app` to that UID/GID and runs as that user.
This is mainly to avoid permission issues on NAS-mounted volumes.

## Typical usage

1. Create `/mnt/media/queue.txt` on the host (mounted into the container).
2. Put one absolute input path per line.
3. Run the container with the GPU device and your preferred upstream options.

Example (from README):

```sh
docker run --rm \
  --device /dev/dri:/dev/dri \
  -v /userdir/media:/mnt/media \
  -v /userdir/output:/output \
  ghcr.io/cjs/docker-other-video-transcoding-vaapi:latest \
  --add-audio eng --add-subtitle eng --vaapi --hevc --10-bit
```

## Relationship to upstream (`other_video_transcoding`)

Upstream provides the actual transcoding logic and CLI options (e.g. codec choice, language track
selection, subtitle handling). This repository:

* does **not** vendor upstream source in git;
* pulls upstream at **image build time**;
* exposes upstream behavior through Docker args.

When adding new features, prefer changing the container wrapper (dependencies, entrypoint behavior,
volume conventions) rather than forking upstream scripts.

## Making changes safely

### Updating upstream version

Because the Dockerfile uses a shallow clone of the default branch, rebuilds will automatically pick
up upstream changes.

If you need reproducible builds, pin to a commit SHA by changing the clone step to fetch and
checkout a specific revision.

### Adding dependencies

If upstream gains a new dependency, add it to the `apt install` list in `Dockerfile`.
Keep installs minimal (`--no-install-recommends`) to avoid bloating the image.

### Local testing

Build:

```sh
docker build -t local/other-video-transcoding-vaapi .
```

Run (with a small queue file):

```sh
docker run --rm \
  --device /dev/dri:/dev/dri \
  -v "$PWD/media":/mnt/media \
  -v "$PWD/output":/output \
  local/other-video-transcoding-vaapi --vaapi --hevc
```

## Repository oddities

* `package-lock.json` exists but is not used by the image build (there is no Node-based component).
  It can be ignored unless a future change introduces JS tooling.
