/* hal2027-rec: records speech for HAL 2027 on the Nokia N9.
 * Usage: hal2027-rec OUT.wav [MAX_SECONDS]
 * Records 16 kHz mono 16-bit PCM through PulseAudio (libpulse-simple) into a WAV file.
 * Prints "level N" (0-100) about ten times a second and "done SECONDS" at the end.
 * Stops when a line arrives on standard input (e.g. "q"), on SIGTERM/SIGINT or after
 * MAX_SECONDS (default 30). The WAV header is kept valid while recording, so even a killed
 * recording can be used. At the end, silence before and after the speech is cut off
 * (less to send). Exit 2 = cannot open the microphone.
 * MIT licence, part of HAL 2027 (github.com/smyhu/hal2027-n9). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

/* the few libpulse-simple declarations we need (PulseAudio 0.9.19 ABI) */
typedef struct pa_simple pa_simple;
typedef struct { int format; uint32_t rate; uint8_t channels; } pa_sample_spec;
typedef struct { uint32_t maxlength, tlength, prebuf, minreq, fragsize; } pa_buffer_attr;
pa_simple *pa_simple_new(const char *server, const char *name, int dir, const char *dev,
                         const char *stream_name, const pa_sample_spec *ss, const void *map,
                         const pa_buffer_attr *attr, int *error);
int pa_simple_read(pa_simple *s, void *data, size_t bytes, int *error);
void pa_simple_free(pa_simple *s);
const char *pa_strerror(int error);
#define PA_STREAM_RECORD 2
#define PA_SAMPLE_S16LE 3

#define RATE 16000
#define CHUNKS 1200                     /* 0.1 s chunks, up to 120 s */
static unsigned char levels[CHUNKS];
static volatile sig_atomic_t stop = 0;
static void on_signal(int s) { (void)s; stop = 1; }

static void put32(unsigned char *p, uint32_t v) { p[0] = v; p[1] = v >> 8; p[2] = v >> 16; p[3] = v >> 24; }
static void put16(unsigned char *p, uint16_t v) { p[0] = v; p[1] = v >> 8; }

static void header(unsigned char *h, uint32_t bytes)
{
    memcpy(h, "RIFF", 4); put32(h + 4, 36 + bytes); memcpy(h + 8, "WAVEfmt ", 8);
    put32(h + 16, 16); put16(h + 20, 1); put16(h + 22, 1); put32(h + 24, RATE);
    put32(h + 28, RATE * 2); put16(h + 32, 2); put16(h + 34, 16);
    memcpy(h + 36, "data", 4); put32(h + 40, bytes);
}

/* Cuts the quiet start and end: the quietest 0.1 s is taken as the room noise,
 * speech is what is clearly louder. Keeps 0.3 s before and 0.4 s after it. */
static uint32_t trim(const char *name, uint32_t total)
{
    uint32_t n = total / (RATE / 10 * 2), i, first = 0, last = 0, from, to;
    int noise = 100, thr, found = 0;
    FILE *f;
    unsigned char h[44], *data;
    if (n < 10 || n > CHUNKS) return total;
    for (i = 0; i < n; i++) if (levels[i] < noise) noise = levels[i];
    thr = noise * 5 / 2 + 3;
    for (i = 0; i < n; i++) if (levels[i] > thr) { if (!found) first = i; last = i; found = 1; }
    if (!found) return total;
    from = first > 3 ? first - 3 : 0;
    to = last + 5 < n ? last + 5 : n;
    if (from == 0 && to == n) return total;
    f = fopen(name, "r+b");
    if (!f) return total;
    data = malloc((to - from) * (RATE / 10 * 2));
    if (!data) { fclose(f); return total; }
    fseek(f, 44 + from * (RATE / 10 * 2), SEEK_SET);
    total = fread(data, 1, (to - from) * (RATE / 10 * 2), f);
    header(h, total);
    fseek(f, 0, SEEK_SET);
    fwrite(h, 1, 44, f);
    fwrite(data, 1, total, f);
    fflush(f);
    ftruncate(fileno(f), 44 + total);
    fclose(f);
    free(data);
    return total;
}

int main(int argc, char **argv)
{
    pa_sample_spec ss;
    pa_buffer_attr ba;
    pa_simple *s;
    FILE *f;
    unsigned char h[44];
    int16_t buf[RATE / 10];
    uint32_t total = 0, limit;
    int err = 0, max = 30;

    if (argc < 2) { fprintf(stderr, "usage: hal2027-rec OUT.wav [MAX_SECONDS]\n"); return 1; }
    if (argc > 2) max = atoi(argv[2]);
    if (max < 1 || max > 300) max = 30;
    limit = (uint32_t)max * RATE * 2;

    {   /* signals must interrupt the blocking read, not restart it */
        struct sigaction sa;
        memset(&sa, 0, sizeof(sa));
        sa.sa_handler = on_signal;
        sigaction(SIGTERM, &sa, NULL);
        sigaction(SIGINT, &sa, NULL);
    }
    fcntl(0, F_SETFL, fcntl(0, F_GETFL) | O_NONBLOCK);

    ss.format = PA_SAMPLE_S16LE; ss.rate = RATE; ss.channels = 1;
    ba.maxlength = (uint32_t)-1; ba.tlength = (uint32_t)-1; ba.prebuf = (uint32_t)-1;
    ba.minreq = (uint32_t)-1; ba.fragsize = sizeof(buf);
    s = pa_simple_new(NULL, "HAL 2027", PA_STREAM_RECORD, NULL, "speech", &ss, NULL, &ba, &err);
    if (!s) { printf("error %s\n", pa_strerror(err)); fflush(stdout); return 2; }

    f = fopen(argv[1], "wb");
    if (!f) { printf("error cannot write %s\n", argv[1]); fflush(stdout); pa_simple_free(s); return 3; }
    header(h, 0);
    fwrite(h, 1, 44, f);

    printf("recording\n"); fflush(stdout);
    while (!stop && total < limit) {
        long sum = 0; int i, peak = 0, level;
        if (pa_simple_read(s, buf, sizeof(buf), &err) < 0) {
            printf("error %s\n", pa_strerror(err)); fflush(stdout); break;
        }
        fwrite(buf, 1, sizeof(buf), f);
        total += sizeof(buf);
        if (total % (RATE * 2) == 0) {      /* keep the header valid every second */
            long pos = ftell(f);
            header(h, total);
            fseek(f, 0, SEEK_SET); fwrite(h, 1, 44, f); fseek(f, pos, SEEK_SET);
        }
        {   /* any input on stdin = stop (HAL writes "q") */
            char c;
            if (read(0, &c, 1) == 1) stop = 1;
        }
        for (i = 0; i < RATE / 10; i++) { int v = buf[i] < 0 ? -buf[i] : buf[i]; sum += v; if (v > peak) peak = v; }
        level = (int)(sum / (RATE / 10) * 400 / 32768);
        if (level > 100) level = 100;
        if (total / sizeof(buf) <= CHUNKS) levels[total / sizeof(buf) - 1] = level;
        printf("level %d\n", level); fflush(stdout);
    }
    pa_simple_free(s);
    header(h, total);
    fseek(f, 0, SEEK_SET);
    fwrite(h, 1, 44, f);
    fclose(f);
    total = trim(argv[1], total);
    printf("done %.1f\n", total / (RATE * 2.0)); fflush(stdout);
    return 0;
}
