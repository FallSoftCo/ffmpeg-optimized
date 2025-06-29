#!/bin/bash

# Simple benchmark test for frame extraction

set -e

echo "Frame Extraction Performance Test"
echo "================================="

# Create test directory
TEST_DIR="$PWD/benchmark_test"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Download a small test video
echo "Downloading test video..."
wget -q "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4" -O test_video.mp4

if [ ! -f test_video.mp4 ]; then
    echo "Failed to download test video"
    exit 1
fi

echo "Test video downloaded successfully"

# Test with system FFmpeg (if available)
if [ -f /usr/bin/ffmpeg ]; then
    echo ""
    echo "Testing VANILLA FFmpeg..."
    mkdir -p vanilla_frames
    
    # Clear page cache
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true
    
    # Run vanilla FFmpeg
    /usr/bin/time -f "Time: %e seconds\nMemory: %M KB" \
        /usr/bin/ffmpeg -i test_video.mp4 -frames:v 10 -q:v 2 vanilla_frames/frame_%03d.jpg -y 2>&1 | \
        grep -E "(Time:|Memory:)" | tee vanilla_stats.txt
fi

echo ""
echo "Testing OPTIMIZED FFmpeg..."
mkdir -p optimized_frames

# Clear page cache
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1 || true

# Run optimized FFmpeg
/usr/bin/time -f "Time: %e seconds\nMemory: %M KB" \
    ../build/bin/ffmpeg -i test_video.mp4 -frames:v 10 -q:v 2 optimized_frames/frame_%03d.jpg -y 2>&1 | \
    grep -E "(Time:|Memory:)" | tee optimized_stats.txt

echo ""
echo "================================="
echo "BENCHMARK RESULTS:"
echo "================================="

if [ -f vanilla_stats.txt ]; then
    echo "VANILLA FFmpeg:"
    cat vanilla_stats.txt
    echo ""
fi

echo "OPTIMIZED FFmpeg:"
cat optimized_stats.txt

echo ""
echo "Binary sizes:"
ls -lh /usr/bin/ffmpeg 2>/dev/null || echo "System FFmpeg not found"
ls -lh ../build/bin/ffmpeg

echo ""
echo "Frames extracted successfully!"
echo "Check quality in:"
ls -d */