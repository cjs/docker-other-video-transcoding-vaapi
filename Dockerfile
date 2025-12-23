FROM joedefen/ffmpeg-vaapi-docker:latest

ARG UID=99
ARG GID=100

# Update and install required packages
RUN apt-get update && apt-get install -y \
    ruby \
    git \
    mkvtoolnix \
    ca-certificates \
    --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create output directory and app directory
RUN mkdir -p /output && mkdir -p /app

# Clone the latest version of the other_video_transcoding scripts
RUN git clone --depth 1 https://github.com/lisamelton/other_video_transcoding.git /tmp/other_video_transcoding \
    && cp /tmp/other_video_transcoding/*.rb /app/ \
    && rm -rf /tmp/other_video_transcoding \
    && chmod +x /app/*.rb \
    && chown -R ${UID}:${GID} /output /app

# Switch to non-root user specified by UID/GID
USER ${UID}:${GID}

# Set working directory to output directory
WORKDIR /output

ENTRYPOINT ["/app/other-transcode.rb"]

# Default command (can be overridden at runtime)
CMD []
