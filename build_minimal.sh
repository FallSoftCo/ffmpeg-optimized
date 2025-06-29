#!/bin/bash

# Minimal FFmpeg build for frame extraction
# Optimized for low memory and CPU usage

set -e

echo "Building minimal FFmpeg for frame extraction..."

# Clean previous builds
make clean 2>/dev/null || true

# Configure with minimal components
# --enable-small: optimize for size
# --disable-runtime-cpudetect: smaller binary, no runtime CPU detection
# --disable-everything: start with nothing enabled
# Then enable only what's needed for:
# - Network protocols (http/https)
# - Common demuxers (mp4, mov, matroska/webm)
# - Common decoders (h264, hevc, vp8, vp9)
# - Image encoder for frame output (mjpeg)

./configure \
    --prefix="$PWD/build" \
    --enable-small \
    --disable-runtime-cpudetect \
    --disable-debug \
    --disable-doc \
    --disable-htmlpages \
    --disable-manpages \
    --disable-podpages \
    --disable-txtpages \
    --disable-avdevice \
    --disable-swresample \
    --disable-avfilter \
    --disable-everything \
    --enable-protocol=file \
    --enable-protocol=http \
    --enable-protocol=https \
    --enable-protocol=tcp \
    --enable-protocol=tls \
    --enable-demuxer=mov \
    --enable-demuxer=mp4 \
    --enable-demuxer=matroska \
    --enable-demuxer=webm \
    --enable-demuxer=flv \
    --enable-demuxer=mpegts \
    --enable-decoder=h264 \
    --enable-decoder=hevc \
    --enable-decoder=vp8 \
    --enable-decoder=vp9 \
    --enable-decoder=av1 \
    --enable-decoder=mpeg4 \
    --enable-muxer=image2 \
    --enable-muxer=mjpeg \
    --enable-encoder=mjpeg \
    --enable-encoder=png \
    --enable-bsf=extract_extradata \
    --enable-parser=h264 \
    --enable-parser=hevc \
    --disable-autodetect \
    --disable-network \
    --enable-network \
    --extra-cflags="-Os -ffunction-sections -fdata-sections" \
    --extra-ldflags="-Wl,--gc-sections"

echo "Configuration complete. Building..."
make -j$(nproc)
make install

echo "Build complete! Binary installed to: $PWD/build/bin/ffmpeg"

# Create wrapper script that sets optimization flags
cat > "$PWD/build/bin/ffmpeg-minimal" << 'EOF'
#!/bin/bash
# Wrapper script for optimized frame extraction
export FFMPEG_MINIMAL_FRAME_EXTRACTION=1
exec "$(dirname "$0")/ffmpeg" "$@"
EOF
chmod +x "$PWD/build/bin/ffmpeg-minimal"

echo "Also created optimized wrapper at: $PWD/build/bin/ffmpeg-minimal"