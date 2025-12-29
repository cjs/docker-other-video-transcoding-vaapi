FROM ubuntu:questing

ARG UID=99
ARG GID=100

# Update and install required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    ffmpeg \
    vainfo \
    intel-media-va-driver-non-free \
    libvpl2 \
    libvpl-dev \
    ruby \
    git \
    mkvtoolnix \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create output directory and app directory
RUN mkdir -p /output && mkdir -p /app

# Copy batch script
COPY batch.rb /app

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

ENTRYPOINT ["/app/batch.rb"]

# Default command (can be overridden at runtime)
CMD ["--add-audio eng --vaapi --hevc --10-bit --add-subtitle eng"]
