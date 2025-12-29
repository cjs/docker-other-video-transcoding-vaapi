# README

The goal here is to produce a Docker image that can be run on a NAS server to
transcode media files

spacecowboy/transcode_docker works perfectly if you want software encoding, but
this combines a version of [lisamelton/other_video_transcoding](https://github.com/lisamelton/other_video_transcoding)
with a batch script in the aforementioned repo's [wiki](https://github.com/lisamelton/other_video_transcoding/wiki/Batching)

## How to use

- Mount your volume with inputs to `/mnt/media`
- Mount your output location to `/output`
- Add a file named `queue.txt` with the full path to your files to transcode, one per line in the `/mnt/media/` directory.
- Run this container with your preferred `other-transcode` options. See [lisamelton/other_video_transcoding](https://github.com/lisamelton/other_video_transcoding) for options. 

## Example

```
docker run --rm  \
  --device /dev/dri:/dev/dri # add GPU to container
  -v /userdir/media:/mnt/media \
  -v /userdir/output:/output \
  ghcr.io/cjs/docker-other-video-transcoding-vaapi:latest --add-audio eng \
  --add-subtitle eng \
  --vaapi \
  --hevc \
  --10-bit 
```

## Credits

- [lisamelton/other_video_transcoding](https://github.com/lisamelton/other_video_transcoding)
- [spacecowboy/transcode_docker](https://github.com/spacecowboy/transcode_docker)
- [martinpickett/docker-other-transcode-mp](https://github.com/martinpickett/docker-other-transcode-mp)
- [joedefen/ffmpeg-vaapi-docker](https://github.com/joedefen/ffmpeg-vaapi-docker)
