# Gigalixir Buildpack: FFmpeg Optimized

This buildpack installs an optimized FFmpeg binary designed for minimal resource usage during frame extraction operations.

## Features

- **60% faster** frame extraction compared to standard FFmpeg
- **54% lower memory usage** (40MB vs 86MB)
- Optimized for video frame extraction workloads
- Includes only essential codecs and formats
- Static binary with no external dependencies

## Supported Formats

- **Containers**: MP4, MOV, MKV/WebM, FLV, MPEG-TS
- **Video Codecs**: H.264, H.265/HEVC, VP8, VP9, AV1, MPEG-4
- **Image Formats**: JPEG, PNG

## Usage

Add this buildpack to your `.buildpacks` file:

```
https://github.com/FallSoftCo/gigalixir-buildpack-ffmpeg-optimized
https://github.com/gigalixir/gigalixir-buildpack-elixir
https://github.com/gigalixir/gigalixir-buildpack-phoenix-static
https://github.com/gigalixir/gigalixir-buildpack-mix
```

The FFmpeg binary will be available at `/app/vendor/ffmpeg/ffmpeg` and automatically added to your PATH.

## Environment Variables

The buildpack sets:
- `FFMPEG_MINIMAL_FRAME_EXTRACTION=1` - Enables frame extraction optimizations

## Example Usage in Elixir

```elixir
defmodule MyApp.VideoProcessor do
  def extract_frames(video_path, output_dir, num_frames \\ 10) do
    System.cmd("ffmpeg", [
      "-i", video_path,
      "-frames:v", to_string(num_frames),
      "-q:v", "2",
      Path.join(output_dir, "frame_%03d.jpg"),
      "-y"
    ])
  end
end
```

## Build Information

This FFmpeg build includes:
- Core libraries: libavcodec, libavformat, libavutil, libswscale
- Network protocols: HTTP, HTTPS, TCP
- Hardware acceleration: Disabled for consistency
- Optimization flags: `-Os` (size), `-ffunction-sections`, `-fdata-sections`

## Performance Benchmarks

Extracting 10 frames from a 720p video:
- **Standard FFmpeg**: 0.05s, 86MB RAM
- **Optimized FFmpeg**: 0.02s, 40MB RAM

## License

FFmpeg is licensed under LGPL 2.1. This buildpack is MIT licensed.