#ifndef AVUTIL_SHIM_H
#define AVUTIL_SHIM_H

#import <Libavutil/avutil.h>
#import <Libavutil/channel_layout.h>
#import <Libavutil/error.h>
#import <Libavutil/opt.h>
#import <Libavformat/avformat.h>
#import <Libavformat/avio.h>

/* libavformat internal (vpcc.c); linked via Libavformat. */
int ff_isom_write_vpcc(AVFormatContext *s, AVIOContext *pb,
                       const uint8_t *data, int len,
                       AVCodecParameters *par);

static const int64_t swift_AV_NOPTS_VALUE = AV_NOPTS_VALUE;

/* Audio channel layout (FFmpeg 8 removed AV_CH_LAYOUT_NATIVE) */
static const uint64_t swift_AV_CH_LAYOUT_MONO              = AV_CH_LAYOUT_MONO;
static const uint64_t swift_AV_CH_LAYOUT_STEREO            = AV_CH_LAYOUT_STEREO;
static const uint64_t swift_AV_CH_LAYOUT_2POINT1           = AV_CH_LAYOUT_2POINT1;
static const uint64_t swift_AV_CH_LAYOUT_2_1               = AV_CH_LAYOUT_2_1;
static const uint64_t swift_AV_CH_LAYOUT_SURROUND          = AV_CH_LAYOUT_SURROUND;
static const uint64_t swift_AV_CH_LAYOUT_3POINT1           = AV_CH_LAYOUT_3POINT1;
static const uint64_t swift_AV_CH_LAYOUT_4POINT0           = AV_CH_LAYOUT_4POINT0;
static const uint64_t swift_AV_CH_LAYOUT_4POINT1           = AV_CH_LAYOUT_4POINT1;
static const uint64_t swift_AV_CH_LAYOUT_2_2               = AV_CH_LAYOUT_2_2;
static const uint64_t swift_AV_CH_LAYOUT_QUAD              = AV_CH_LAYOUT_QUAD;
static const uint64_t swift_AV_CH_LAYOUT_5POINT0           = AV_CH_LAYOUT_5POINT0;
static const uint64_t swift_AV_CH_LAYOUT_5POINT1           = AV_CH_LAYOUT_5POINT1;
static const uint64_t swift_AV_CH_LAYOUT_5POINT0_BACK      = AV_CH_LAYOUT_5POINT0_BACK;
static const uint64_t swift_AV_CH_LAYOUT_5POINT1_BACK      = AV_CH_LAYOUT_5POINT1_BACK;
static const uint64_t swift_AV_CH_LAYOUT_6POINT0           = AV_CH_LAYOUT_6POINT0;
static const uint64_t swift_AV_CH_LAYOUT_6POINT0_FRONT     = AV_CH_LAYOUT_6POINT0_FRONT;
static const uint64_t swift_AV_CH_LAYOUT_HEXAGONAL         = AV_CH_LAYOUT_HEXAGONAL;
static const uint64_t swift_AV_CH_LAYOUT_6POINT1           = AV_CH_LAYOUT_6POINT1;
static const uint64_t swift_AV_CH_LAYOUT_6POINT1_BACK      = AV_CH_LAYOUT_6POINT1_BACK;
static const uint64_t swift_AV_CH_LAYOUT_6POINT1_FRONT     = AV_CH_LAYOUT_6POINT1_FRONT;
static const uint64_t swift_AV_CH_LAYOUT_7POINT0           = AV_CH_LAYOUT_7POINT0;
static const uint64_t swift_AV_CH_LAYOUT_7POINT0_FRONT     = AV_CH_LAYOUT_7POINT0_FRONT;
static const uint64_t swift_AV_CH_LAYOUT_7POINT1           = AV_CH_LAYOUT_7POINT1;
static const uint64_t swift_AV_CH_LAYOUT_7POINT1_WIDE      = AV_CH_LAYOUT_7POINT1_WIDE;
static const uint64_t swift_AV_CH_LAYOUT_7POINT1_WIDE_BACK = AV_CH_LAYOUT_7POINT1_WIDE_BACK;
static const uint64_t swift_AV_CH_LAYOUT_OCTAGONAL         = AV_CH_LAYOUT_OCTAGONAL;
static const uint64_t swift_AV_CH_LAYOUT_HEXADECAGONAL     = AV_CH_LAYOUT_HEXADECAGONAL;
static const uint64_t swift_AV_CH_LAYOUT_STEREO_DOWNMIX    = AV_CH_LAYOUT_STEREO_DOWNMIX;
static const uint64_t swift_AV_OPT_SEARCH_CHILDREN         = AV_OPT_SEARCH_CHILDREN;
static const uint64_t swift_AV_CH_LOW_FREQUENCY_2         = AV_CH_LOW_FREQUENCY_2;
static const uint64_t swift_AV_CH_FRONT_CENTER         = AV_CH_FRONT_CENTER;

static inline int swift_AVERROR(int errnum) {
  return AVERROR(errnum);
}

static inline int swift_AVUNERROR(int errnum) {
  return AVUNERROR(errnum);
}

static const int swift_AVERROR_BSF_NOT_FOUND      = AVERROR_BSF_NOT_FOUND;
static const int swift_AVERROR_BUG                = AVERROR_BUG;
static const int swift_AVERROR_BUFFER_TOO_SMALL   = AVERROR_BUFFER_TOO_SMALL;
static const int swift_AVERROR_DECODER_NOT_FOUND  = AVERROR_DECODER_NOT_FOUND;
static const int swift_AVERROR_DEMUXER_NOT_FOUND  = AVERROR_DEMUXER_NOT_FOUND;
static const int swift_AVERROR_ENCODER_NOT_FOUND  = AVERROR_ENCODER_NOT_FOUND;
static const int swift_AVERROR_EOF                = AVERROR_EOF;
static const int swift_AVERROR_EXIT               = AVERROR_EXIT;
static const int swift_AVERROR_EXTERNAL           = AVERROR_EXTERNAL;
static const int swift_AVERROR_FILTER_NOT_FOUND   = AVERROR_FILTER_NOT_FOUND;
static const int swift_AVERROR_INVALIDDATA        = AVERROR_INVALIDDATA;
static const int swift_AVERROR_MUXER_NOT_FOUND    = AVERROR_MUXER_NOT_FOUND;
static const int swift_AVERROR_OPTION_NOT_FOUND   = AVERROR_OPTION_NOT_FOUND;
static const int swift_AVERROR_PATCHWELCOME       = AVERROR_PATCHWELCOME;
static const int swift_AVERROR_PROTOCOL_NOT_FOUND = AVERROR_PROTOCOL_NOT_FOUND;
static const int swift_AVERROR_STREAM_NOT_FOUND   = AVERROR_STREAM_NOT_FOUND;
static const int swift_AVERROR_BUG2               = AVERROR_BUG2;
static const int swift_AVERROR_UNKNOWN            = AVERROR_UNKNOWN;
static const int swift_AVERROR_EXPERIMENTAL       = AVERROR_EXPERIMENTAL;
static const int swift_AVERROR_INPUT_CHANGED      = AVERROR_INPUT_CHANGED;
static const int swift_AVERROR_OUTPUT_CHANGED     = AVERROR_OUTPUT_CHANGED;
static const int swift_AVERROR_HTTP_BAD_REQUEST   = AVERROR_HTTP_BAD_REQUEST;
static const int swift_AVERROR_HTTP_UNAUTHORIZED  = AVERROR_HTTP_UNAUTHORIZED;
static const int swift_AVERROR_HTTP_FORBIDDEN     = AVERROR_HTTP_FORBIDDEN;
static const int swift_AVERROR_HTTP_NOT_FOUND     = AVERROR_HTTP_NOT_FOUND;
static const int swift_AVERROR_HTTP_OTHER_4XX     = AVERROR_HTTP_OTHER_4XX;
static const int swift_AVERROR_HTTP_SERVER_ERROR  = AVERROR_HTTP_SERVER_ERROR;

#endif /* AVUTIL_SHIM_H */
