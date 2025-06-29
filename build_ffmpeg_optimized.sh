#!/bin/bash

# Optimized FFmpeg build for frame extraction
# Includes necessary components for ffmpeg

set -e

echo "Building optimized FFmpeg with frame extraction capabilities..."

# Clean previous builds
make clean 2>/dev/null || true

# Configure with optimization and necessary components for ffmpeg
./configure \
    --prefix="$PWD/build" \
    --enable-small \
    --disable-debug \
    --disable-doc \
    --disable-avdevice \
    --disable-swresample \
    --enable-network \
    --disable-encoders \
    --enable-encoder=mjpeg \
    --enable-encoder=png \
    --disable-decoders \
    --enable-decoder=h264 \
    --enable-decoder=hevc \
    --enable-decoder=vp8 \
    --enable-decoder=vp9 \
    --enable-decoder=av1 \
    --enable-decoder=mpeg4 \
    --enable-decoder=mjpeg \
    --disable-muxers \
    --enable-muxer=image2 \
    --enable-muxer=mjpeg \
    --enable-muxer=singlejpeg \
    --disable-demuxers \
    --enable-demuxer=mov \
    --enable-demuxer=matroska \
    --enable-demuxer=flv \
    --enable-demuxer=mpegts \
    --enable-demuxer=concat \
    --disable-devices \
    --extra-cflags="-Os -ffunction-sections -fdata-sections -DMINIMAL_FFMPEG" \
    --extra-ldflags="-Wl,--gc-sections -Wl,--strip-all"

echo "Configuration complete. Building..."
make -j$(nproc)
make install

echo "Build complete! Binary installed to: $PWD/build/bin/ffmpeg"

# Create wrapper script
cat > "$PWD/build/bin/ffmpeg-minimal" << 'EOF'
#!/bin/bash
# Optimized wrapper for frame extraction
export FFMPEG_MINIMAL_FRAME_EXTRACTION=1
exec "$(dirname "$0")/ffmpeg" "$@"
EOF
chmod +x "$PWD/build/bin/ffmpeg-minimal"

echo "Wrapper script created at: $PWD/build/bin/ffmpeg-minimal"

# Check binary size
echo ""
echo "Binary sizes:"
ls -lh "$PWD/build/bin/ffmpeg" 2>/dev/null || echo "ffmpeg not built"
ls -lh "$PWD/build/bin/ffprobe" 2>/dev/null || echo "ffprobe not built"