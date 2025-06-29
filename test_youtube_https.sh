#!/bin/bash

# Test optimized FFmpeg with YouTube HTTPS URLs

echo "Testing Optimized FFmpeg with YouTube (HTTPS enabled)"
echo "===================================================="

COOKIES="/home/ai/Development/tlyt/tlyt_phoenix/priv/cookies.txt"

# Get fresh URL
echo "Getting YouTube direct URL..."
DIRECT_URL=$(yt-dlp --cookies "$COOKIES" -f best --get-url "https://www.youtube.com/watch?v=jNQXAC9IVRw" 2>/dev/null | head -1)

if [ -z "$DIRECT_URL" ] || [[ ! "$DIRECT_URL" =~ ^https?:// ]]; then
    echo "Failed to get direct URL"
    exit 1
fi

echo "Direct URL obtained successfully"
mkdir -p youtube_test

# Test with optimized FFmpeg
echo ""
echo "Extracting frames with optimized FFmpeg (HTTPS-enabled)..."
/usr/bin/time -f "Time: %e seconds, Memory: %M KB" \
    ./build/bin/ffmpeg -i "$DIRECT_URL" -frames:v 10 -q:v 2 youtube_test/frame_%03d.jpg -y

# Check results
FRAME_COUNT=$(ls youtube_test/*.jpg 2>/dev/null | wc -l)
echo ""
echo "Extracted $FRAME_COUNT frames"

if [ $FRAME_COUNT -eq 10 ]; then
    echo "✓ SUCCESS! FFmpeg with HTTPS support works with YouTube!"
    ls -lh youtube_test/*.jpg | head -5
    
    # Compare with vanilla FFmpeg
    if [ -f /usr/bin/ffmpeg ]; then
        echo ""
        echo "Comparing performance with vanilla FFmpeg..."
        mkdir -p youtube_test_vanilla
        /usr/bin/time -f "Time: %e seconds, Memory: %M KB" \
            /usr/bin/ffmpeg -i "$DIRECT_URL" -frames:v 10 -q:v 2 youtube_test_vanilla/frame_%03d.jpg -y -loglevel error
    fi
else
    echo "✗ Failed to extract expected number of frames"
fi

echo ""
echo "Binary info:"
ls -lh ./build/bin/ffmpeg
./build/bin/ffmpeg -version | head -3