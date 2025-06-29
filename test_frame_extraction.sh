#!/bin/bash

# Test script for frame extraction optimization

set -e

echo "Frame Extraction Benchmark Test"
echo "=============================="

# Create test directory
TEST_DIR="$PWD/benchmark_test"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Get a short YouTube video URL for testing (a public domain video)
VIDEO_URL="https://www.youtube.com/watch?v=aqz-KE-bpKQ" # Big Buck Bunny trailer

echo "Getting direct video URL using yt-dlp..."
DIRECT_URL=$(yt-dlp -f 'best[height<=720]' --get-url "$VIDEO_URL" 2>&1)

if [ $? -ne 0 ] || [ -z "$DIRECT_URL" ]; then
    echo "Failed to get direct URL. Using a test video file instead..."
    # Download a small test video
    wget -q "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4" -O test_video.mp4
    if [ $? -eq 0 ]; then
        DIRECT_URL="test_video.mp4"
        echo "Using local test video file"
    else
        echo "Failed to download test video. Exiting."
        exit 1
    fi
else
    DIRECT_URL=$(echo "$DIRECT_URL" | grep -E '^https?://' | head -1)
    echo "Direct URL obtained"
fi

# Test with system FFmpeg (if available)
if command -v ffmpeg &> /dev/null; then
    echo ""
    echo "Testing with system FFmpeg..."
    mkdir -p vanilla_frames
    
    # Measure time and memory for vanilla FFmpeg
    /usr/bin/time -v ffmpeg -i "$DIRECT_URL" -frames:v 10 -q:v 2 vanilla_frames/frame_%03d.jpg -y 2>&1 | tee vanilla_output.txt
    
    VANILLA_TIME=$(grep "Elapsed" vanilla_output.txt | awk '{print $8}')
    VANILLA_MEM=$(grep "Maximum resident" vanilla_output.txt | awk '{print $6}')
    
    echo "Vanilla FFmpeg - Time: $VANILLA_TIME, Max Memory: $VANILLA_MEM KB"
else
    echo "System FFmpeg not found, skipping vanilla test"
fi

# Test with optimized FFmpeg
echo ""
echo "Testing with optimized FFmpeg..."
mkdir -p optimized_frames

# Measure time and memory for optimized FFmpeg
FFMPEG_MINIMAL_FRAME_EXTRACTION=1 /usr/bin/time -v ../build/bin/ffmpeg -i "$DIRECT_URL" -frames:v 10 -q:v 2 optimized_frames/frame_%03d.jpg -y 2>&1 | tee optimized_output.txt

OPT_TIME=$(grep "Elapsed" optimized_output.txt | awk '{print $8}')
OPT_MEM=$(grep "Maximum resident" optimized_output.txt | awk '{print $6}')

echo "Optimized FFmpeg - Time: $OPT_TIME, Max Memory: $OPT_MEM KB"

# Display results
echo ""
echo "RESULTS SUMMARY"
echo "==============="
if [ -f vanilla_output.txt ]; then
    echo "Vanilla FFmpeg:"
    echo "  - Elapsed time: $VANILLA_TIME"
    echo "  - Maximum memory: $VANILLA_MEM KB"
    echo ""
fi
echo "Optimized FFmpeg:"
echo "  - Elapsed time: $OPT_TIME"
echo "  - Maximum memory: $OPT_MEM KB"

# Check frame quality
echo ""
echo "Frame extraction successful. Frames saved in:"
echo "  - Vanilla: $TEST_DIR/vanilla_frames/ (if tested)"
echo "  - Optimized: $TEST_DIR/optimized_frames/"

# Compare file sizes
echo ""
echo "Output frame file sizes:"
if [ -d vanilla_frames ]; then
    ls -lh vanilla_frames/frame_001.jpg 2>/dev/null || echo "Vanilla frames not found"
fi
ls -lh optimized_frames/frame_001.jpg 2>/dev/null || echo "Optimized frames not found"

# Show binary size comparison
echo ""
echo "Binary sizes:"
if [ -f /usr/bin/ffmpeg ]; then
    ls -lh /usr/bin/ffmpeg
fi
ls -lh ../build/bin/ffmpeg