// HAL 2027 network helper for the Nokia N9.
// Usage: hal2027-fetch [options] URL
//   -H "Name: value"  extra request header (repeatable)
//   -d DATA           POST body given on the command line
//   -D FILE           POST body read from FILE
//   -c TYPE           Content-Type of the POST body
//                     (default application/x-www-form-urlencoded;charset=UTF-8)
//   -o FILE           write the body to FILE, otherwise to stdout
//   -t SECONDS        give up after this many seconds without data (default 30)
//   -a AGENT          User-Agent header (default "Mozilla/5.0")
// The body is written as it arrives and stdout is flushed after every chunk,
// so streamed answers (server-sent events) can be read line by line.
// On HTTP errors the error body is still written (APIs explain the problem
// there), "status NNN" goes to stderr and the exit code is 2.
// Exit codes: 0 ok, 1 usage, 2 HTTP/network error, 3 timeout, 4 redirects,
// 5 file error.
// Native Qt program: Python on the N9 carries the old OpenSSL 0.9.8, which
// crashes the TLS-patched QtNetwork (OpenSSL 1.0.x) in the same process.
// Built without moc: the reply is polled instead of connecting slots.
// Written by Claude (Anthropic) together with smyhu. MIT licence.

#include <QtCore/qcoreapplication.h>
#include <QtCore/qeventloop.h>
#include <QtCore/qelapsedtimer.h>
#include <QtCore/qfile.h>
#include <QtCore/qlist.h>
#include <QtCore/qurl.h>
#include <QtNetwork/qnetworkaccessmanager.h>
#include <QtNetwork/qnetworkrequest.h>
#include <QtNetwork/qnetworkreply.h>
#include <stdio.h>
#include <string.h>

static int usage()
{
    fprintf(stderr, "usage: hal2027-fetch [-H header]... [-d DATA | -D FILE] [-c TYPE] [-o FILE] [-t SECONDS] [-a AGENT] URL\n");
    return 1;
}

static int toInt(const char *s)
{
    int v = 0;
    while (*s >= '0' && *s <= '9')
        v = v * 10 + (*s++ - '0');
    return v;
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    QByteArray data, agent("Mozilla/5.0");
    QByteArray type("application/x-www-form-urlencoded;charset=UTF-8");
    QList<QByteArray> headers;
    const char *outName = 0;
    const char *url = 0;
    bool post = false;
    int idle = 30;
    for (int i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "-d") && i + 1 < argc) {
            data = argv[++i];
            post = true;
        } else if (!strcmp(argv[i], "-D") && i + 1 < argc) {
            QFile f(QString::fromLocal8Bit(argv[++i]));
            if (!f.open(QIODevice::ReadOnly)) {
                fprintf(stderr, "cannot read %s\n", argv[i]);
                return 5;
            }
            data = f.readAll();
            post = true;
        } else if (!strcmp(argv[i], "-H") && i + 1 < argc) {
            headers.append(QByteArray(argv[++i]));
        } else if (!strcmp(argv[i], "-c") && i + 1 < argc) {
            type = argv[++i];
        } else if (!strcmp(argv[i], "-o") && i + 1 < argc) {
            outName = argv[++i];
        } else if (!strcmp(argv[i], "-t") && i + 1 < argc) {
            idle = toInt(argv[++i]);
        } else if (!strcmp(argv[i], "-a") && i + 1 < argc) {
            agent = argv[++i];
        } else if (argv[i][0] != '-' && !url) {
            url = argv[i];
        } else {
            return usage();
        }
    }
    if (!url || idle <= 0)
        return usage();

    FILE *out = stdout;
    if (outName) {
        out = fopen(outName, "wb");
        if (!out) {
            fprintf(stderr, "cannot write %s\n", outName);
            return 5;
        }
    }

    QNetworkAccessManager nam;
    QUrl target = QUrl::fromEncoded(url);
    for (int hop = 0; hop < 6; ++hop) {
        QNetworkRequest request(target);
        request.setRawHeader("User-Agent", agent);
        // Without this Qt 4.7 asks for gzip and keeps a compressed reply until
        // it has all of it, so streamed answers would arrive only at the end.
        request.setRawHeader("Accept-Encoding", "identity");
        for (int h = 0; h < headers.size(); ++h) {
            int colon = headers[h].indexOf(':');
            if (colon > 0)
                request.setRawHeader(headers[h].left(colon).trimmed(), headers[h].mid(colon + 1).trimmed());
        }
        QNetworkReply *reply;
        if (post) {
            request.setHeader(QNetworkRequest::ContentTypeHeader, type);
            reply = nam.post(request, data);
        } else {
            reply = nam.get(request);
        }

        QEventLoop loop;
        QElapsedTimer quiet;
        quiet.start();
        int status = 0;
        bool redirect = false;
        while (true) {
            loop.processEvents(QEventLoop::WaitForMoreEvents, 200);
            if (!status && reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).isValid()) {
                status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
                redirect = status == 301 || status == 302 || status == 303 || status == 307 || status == 308;
            }
            if (status && !redirect && reply->bytesAvailable() > 0) {
                QByteArray chunk = reply->readAll();
                fwrite(chunk.constData(), 1, chunk.size(), out);
                fflush(out);
                quiet.restart();
            }
            if (reply->isFinished())
                break;
            if (quiet.elapsed() > idle * 1000) {
                fprintf(stderr, "timeout\n");
                if (outName) {
                    fclose(out);
                    remove(outName);
                }
                return 3;
            }
        }

        status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        QUrl next = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
        if (redirect && next.isValid()) {
            target = target.resolved(next);
            if (status == 303)
                post = false;
            reply->deleteLater();
            continue;
        }
        QByteArray rest = reply->readAll();
        fwrite(rest.constData(), 1, rest.size(), out);
        fflush(out);
        if (reply->error() != QNetworkReply::NoError || status < 200 || status > 299) {
            fprintf(stderr, "status %d\nerror %d: %s\n", status, int(reply->error()),
                    reply->errorString().toLocal8Bit().constData());
            if (outName) {
                fclose(out);
                remove(outName);
            }
            return 2;
        }
        if (outName)
            fclose(out);
        return 0;
    }
    fprintf(stderr, "too many redirects\n");
    return 4;
}
