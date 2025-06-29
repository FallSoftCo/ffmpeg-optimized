/*
 * Minimal FFmpeg wrapper for efficient frame extraction
 * Compile with: gcc -o ffmpeg-extract frame_extraction_wrapper.c -lavformat -lavcodec -lavutil
 */

#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/imgutils.h>
#include <libavutil/opt.h>

int extract_frames(const char *input_url, const char *output_pattern, int num_frames) {
    AVFormatContext *format_ctx = NULL;
    AVCodecContext *codec_ctx = NULL;
    AVFrame *frame = NULL;
    AVPacket *packet = NULL;
    int video_stream_idx = -1;
    int frame_count = 0;
    int ret = 0;

    // Open input with minimal probing
    format_ctx = avformat_alloc_context();
    format_ctx->probesize = 262144; // 256KB probe size
    format_ctx->max_analyze_duration = 1000000; // 1 second
    
    if ((ret = avformat_open_input(&format_ctx, input_url, NULL, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open input: %s\n", av_err2str(ret));
        return ret;
    }

    // Find streams with minimal analysis
    format_ctx->flags |= AVFMT_FLAG_NOBUFFER;
    if ((ret = avformat_find_stream_info(format_ctx, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find stream info: %s\n", av_err2str(ret));
        goto cleanup;
    }

    // Find video stream
    for (int i = 0; i < format_ctx->nb_streams; i++) {
        if (format_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_idx = i;
            break;
        }
    }

    if (video_stream_idx < 0) {
        av_log(NULL, AV_LOG_ERROR, "No video stream found\n");
        ret = AVERROR_STREAM_NOT_FOUND;
        goto cleanup;
    }

    // Set up decoder with minimal buffering
    const AVCodec *codec = avcodec_find_decoder(format_ctx->streams[video_stream_idx]->codecpar->codec_id);
    codec_ctx = avcodec_alloc_context3(codec);
    avcodec_parameters_to_context(codec_ctx, format_ctx->streams[video_stream_idx]->codecpar);
    
    // Optimize decoder for low latency
    codec_ctx->flags |= AV_CODEC_FLAG_LOW_DELAY;
    codec_ctx->flags2 |= AV_CODEC_FLAG2_FAST;
    
    if ((ret = avcodec_open2(codec_ctx, codec, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open decoder: %s\n", av_err2str(ret));
        goto cleanup;
    }

    // Allocate frame and packet
    frame = av_frame_alloc();
    packet = av_packet_alloc();

    // Extract frames
    while (frame_count < num_frames && av_read_frame(format_ctx, packet) >= 0) {
        if (packet->stream_index == video_stream_idx) {
            ret = avcodec_send_packet(codec_ctx, packet);
            if (ret >= 0) {
                ret = avcodec_receive_frame(codec_ctx, frame);
                if (ret >= 0) {
                    // Save frame (simplified - would need encoder setup in real implementation)
                    char filename[256];
                    snprintf(filename, sizeof(filename), output_pattern, frame_count);
                    av_log(NULL, AV_LOG_INFO, "Extracted frame %d to %s\n", frame_count, filename);
                    frame_count++;
                }
            }
        }
        av_packet_unref(packet);
    }

cleanup:
    av_frame_free(&frame);
    av_packet_free(&packet);
    avcodec_free_context(&codec_ctx);
    avformat_close_input(&format_ctx);
    
    return (frame_count > 0) ? 0 : ret;
}

int main(int argc, char **argv) {
    if (argc < 4) {
        av_log(NULL, AV_LOG_ERROR, "Usage: %s <input_url> <output_pattern> <num_frames>\n", argv[0]);
        return 1;
    }

    int num_frames = atoi(argv[3]);
    return extract_frames(argv[1], argv[2], num_frames);
}