#!/usr/bin/python
# -*- coding: utf-8 -*-
# HAL 2027 - AI assistant for the Nokia N9 (Python 2.6 + PySide + QML).
# Chat with Gemini, Claude and OpenAI-compatible services using your own
# API keys, Google Translate with speech, conversation history.
# Designed and written by Claude (Anthropic) together with smyhu. MIT licence.

import os
import sys
import pwd
import json
import re
import unicodedata
import time
import sqlite3
import subprocess

from PySide.QtCore import QObject, QUrl, QProcess, QSettings, QTimer, Signal, Slot
from PySide.QtGui import QApplication
from PySide.QtDeclarative import QDeclarativeView

APP_DIR = os.path.dirname(os.path.abspath(__file__))
FETCH = os.path.join(APP_DIR, 'hal2027-fetch')
ESPEAK = os.path.join(APP_DIR, 'espeak', 'espeak-ng')
REC = os.environ.get('HAL2027_REC', os.path.join(APP_DIR, 'hal2027-rec'))
ESPEAK_DATA = os.path.join(APP_DIR, 'espeak', 'espeak-ng-data')
# calm, low offline voice by default (espeak-ng defaults: speed 175, pitch 50);
# both can be changed in Settings
VOICE_SPEED = 130
VOICE_PITCH = 25
VERSION = '0.1.12'
UI_LANGUAGES = ('pl', 'en')

HOME = os.environ.get('HOME') or pwd.getpwuid(os.getuid()).pw_dir
if not os.path.isdir(HOME):
    HOME = '/home/user'
DATA_DIR = os.path.join(HOME, '.local/share/hal2027')
CACHE_DIR = os.path.join(HOME, '.cache/hal2027')
TTS_DIR = os.path.join(CACHE_DIR, 'tts')
DOCS_DIR = os.environ.get('HAL2027_DOCS', os.path.join(HOME, 'MyDocs/Documents/HAL2027'))
KEY_FILE_NAMES = ('hal2027-klucze.txt', 'hal2027-keys.txt')
KEY_FILE_DIRS = (os.path.join(HOME, 'MyDocs'), HOME)

ANTHROPIC_VERSION = '2026-10-21'

# Tried in turn when the chosen Gemini model is overloaded (free tier: the
# newest models often hang or return 503 under high demand).
GEMINI_FALLBACK = ['gemini-3.5-flash', 'gemini-flash-lite-latest']
RETRY_STATUS = (404, 429, 500, 502, 503, 504)

# Speech to text: tried in this order, skipping services without a key.
# kind gemini = audio sent to a Gemini model; kind whisper = the
# OpenAI-style /audio/transcriptions endpoint (Groq, OpenAI, Mistral...).
# 'key' names the service whose API key is used (default: id), 'base' the
# server (default: that service's base). Changed in uslugi.json.
SPEECH_TO_TEXT = [
    {'id': 'gemini', 'kind': 'gemini', 'models': ['gemini-flash-lite-latest', 'gemini-3.5-flash']},
    {'id': 'groq', 'kind': 'whisper', 'model': 'whisper-large-v3-turbo'},
    {'id': 'openai', 'kind': 'whisper', 'model': 'gpt-4o-mini-transcribe'},
    {'id': 'mistral', 'kind': 'whisper', 'model': 'voxtral-mini-latest'},
]
LISTEN_MAX_SECONDS = 30

# Services. kind: gemini, anthropic or openai (OpenAI-compatible chat API).
PROVIDERS = [
    {'id': 'gemini', 'name': 'Google Gemini', 'kind': 'gemini',
     'base': 'https://generativelanguage.googleapis.com/v1beta',
     'model': 'gemini-3.5-flash', 'free': True,
     'signup': 'https://aistudio.google.com/apikey'},
    {'id': 'claude', 'name': 'Anthropic Claude', 'kind': 'anthropic',
     'base': 'https://api.anthropic.com/v1',
     'model': 'claude-opus-5-5', 'free': False,
     'signup': 'https://console.anthropic.com/settings/keys'},
    {'id': 'openai', 'name': 'OpenAI', 'kind': 'openai',
     'base': 'https://api.openai.com/v1', 'model': '', 'free': False,
     'signup': 'https://platform.openai.com/api-keys'},
    {'id': 'openrouter', 'name': 'OpenRouter', 'kind': 'openai',
     'base': 'https://openrouter.ai/api/v1', 'model': '', 'free': True,
     'signup': 'https://openrouter.ai/keys'},
    {'id': 'groq', 'name': 'Groq', 'kind': 'openai',
     'base': 'https://api.groq.com/openai/v1', 'model': '', 'free': True,
     'signup': 'https://console.groq.com/keys'},
    {'id': 'mistral', 'name': 'Mistral', 'kind': 'openai',
     'base': 'https://api.mistral.ai/v1', 'model': '', 'free': False,
     'signup': 'https://console.mistral.ai/api-keys'},
    {'id': 'xai', 'name': 'xAI Grok', 'kind': 'openai',
     'base': 'https://api.x.ai/v1', 'model': '', 'free': False,
     'signup': 'https://console.x.ai'},
]


def load_services():
    """Services can be changed without a new package: /opt/hal2027/uslugi.json
    (shipped) and the user's MyDocs/hal2027-uslugi.json, which changes chosen
    fields of a service (matched by id) or adds new ones. Each kind (gemini,
    anthropic, openai) is one way of talking to a server; a new service of one
    of these kinds needs only an entry in the file."""
    global PROVIDERS, ANTHROPIC_VERSION, GEMINI_FALLBACK, SPEECH_TO_TEXT, LISTEN_MAX_SECONDS
    for path in (os.path.join(APP_DIR, 'uslugi.json'),
                 os.path.join(HOME, 'MyDocs', 'hal2027-uslugi.json'),
                 os.path.join(HOME, 'MyDocs', 'hal2027-services.json')):
        if not os.path.exists(path):
            continue
        try:
            conf = json.load(open(path))
        except (IOError, ValueError), e:
            print 'hal2027: %s ignored: %s' % (path, e)
            continue
        ANTHROPIC_VERSION = str(conf.get('anthropic_version', ANTHROPIC_VERSION))
        GEMINI_FALLBACK = [str(m) for m in conf.get('gemini_fallback', GEMINI_FALLBACK)]
        stt = conf.get('speech_to_text')
        if isinstance(stt, list):
            SPEECH_TO_TEXT = [e for e in stt if isinstance(e, dict) and e.get('id') and
                              e.get('kind') in ('gemini', 'whisper')]
        try:
            LISTEN_MAX_SECONDS = max(5, min(120, int(conf.get('listen_max_seconds', LISTEN_MAX_SECONDS))))
        except (TypeError, ValueError):
            pass
        for entry in conf.get('services', []):
            if not isinstance(entry, dict) or not entry.get('id'):
                continue
            old = [x for x in PROVIDERS if x['id'] == entry['id']]
            if old:
                old[0].update(entry)
            elif entry.get('kind') in ('gemini', 'anthropic', 'openai') and entry.get('base'):
                new = {'name': entry['id'], 'model': '', 'free': False, 'signup': ''}
                new.update(entry)
                PROVIDERS.append(new)
        print 'hal2027: services from %s' % path

load_services()
PROVIDER = dict((p['id'], p) for p in PROVIDERS)
for _p in PROVIDERS:     # test servers: HAL2027_BASE_GEMINI=http://127.0.0.1:8099/gemini
    _p['base'] = os.environ.get('HAL2027_BASE_' + _p['id'].upper(), _p['base'])

SYSTEM_PROMPT = (
    u"You are HAL 2027, a calm, polite and helpful assistant running on a Nokia N9 "
    u"phone with a small 3.9-inch screen. Always answer in the language of the "
    u"user's last message. Keep answers short and clear. Use plain text: short "
    u"paragraphs, simple lists with '-' if needed, no tables, no headings, no code "
    u"blocks unless the user asks for code. The current local date and time is %s.")
SYSTEM_MOBILE = (u" The phone is on a slow 2G mobile connection right now: answer in "
                 u"at most three sentences unless the user asks for more.")


def session_env():
    """Outside the user session D-Bus and gconf need the session bus address;
    Harmattan keeps it in /tmp/session_bus_address.user."""
    if os.environ.get('DBUS_SESSION_BUS_ADDRESS'):
        return
    try:
        for line in open('/tmp/session_bus_address.user'):
            if 'DBUS_SESSION_BUS_ADDRESS=' in line:
                value = line.split('DBUS_SESSION_BUS_ADDRESS=', 1)[1].strip().strip("';")
                os.environ['DBUS_SESSION_BUS_ADDRESS'] = value
    except IOError:
        pass


def phone_language():
    """Phone language (gconf /meegotouch/i18n/language); English otherwise.
    HAL2027_LANG=pl etc. overrides it for testing."""
    code = os.environ.get('HAL2027_LANG', '')
    if not code:
        session_env()
        try:
            p = subprocess.Popen(['gconftool-2', '-g', '/meegotouch/i18n/language'],
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            code = p.communicate()[0].strip()
        except OSError:
            pass
    if not code:
        code = os.environ.get('LANG', '')
    code = code[:2].lower()
    if code in UI_LANGUAGES:
        return code
    return 'en'


def ensure_dir(path):
    if not os.path.isdir(path):
        os.makedirs(path)


def default_route():
    """Name of the interface with the default route ('' when offline)."""
    try:
        f = open(os.environ.get('HAL2027_ROUTES', '/proc/net/route'))
        try:
            lines = f.readlines()[1:]
        finally:
            f.close()
    except IOError:
        return 'unknown'
    for line in lines:
        fields = line.split()
        if len(fields) > 3 and fields[0] != 'lo' and fields[1] == '00000000' \
                and int(fields[3], 16) & 1:
            return fields[0]
    return ''


class Net(QObject):
    """Runs hal2027-fetch in helper processes. HTTPS must not run inside
    Python on the N9: Python holds the old OpenSSL 0.9.8 and the TLS patch
    makes QtNetwork load OpenSSL 1.0.x, which crashes the process.
    Each request has a tag; answers wait in a queue for QML (finished())."""

    finished = Signal()

    def __init__(self):
        QObject.__init__(self)
        self.procs = {}
        self.results = []

    def start(self, tag, url, data=None, datafile=None, ctype=None, headers=(),
              outfile=None, idle=30, on_done=None, on_chunk=None):
        """on_chunk(text) gets the body as it arrives (for streamed answers);
        on_done(ok, body, status) at the end."""
        self.cancel(tag)
        args = ['-t', str(idle)]
        for h in headers:
            args += ['-H', h]
        if ctype:
            args += ['-c', ctype]
        if datafile:
            args += ['-D', datafile]
        elif data:
            args += ['-d', data]
        if outfile:
            args += ['-o', outfile]
        args.append(url)
        proc = QProcess(self)
        self.procs[tag] = proc
        state = {'err': '', 'status': 0, 'body': []}

        def stdout_ready():
            chunk = str(proc.readAllStandardOutput())
            if not chunk:
                return
            state['body'].append(chunk)
            if on_chunk:
                on_chunk(chunk)

        def stderr_ready():
            for line in str(proc.readAllStandardError()).splitlines():
                if line.startswith('status '):
                    try:
                        state['status'] = int(line.split()[1])
                    except (IndexError, ValueError):
                        pass
                elif line.strip():
                    state['err'] = line.strip()

        def finished(*args):
            if self.procs.get(tag) is not proc:
                return
            del self.procs[tag]
            stdout_ready()
            stderr_ready()
            ok = proc.exitStatus() == QProcess.NormalExit and proc.exitCode() == 0
            body = ''.join(state['body']).decode('utf-8', 'replace')
            if not ok and not body:
                body = unicode(state['err'] or 'helper crashed', 'utf-8', 'replace')
            if not ok:
                print 'hal2027: %s failed (%s): %s' % (url.split('?')[0][:80], state['status'], body[:200].encode('utf-8'))
            proc.deleteLater()
            if on_done:
                on_done(ok, body, state['status'])
            else:
                self.results.append({'tag': tag, 'ok': ok, 'body': body})
                self.finished.emit()

        proc.readyReadStandardOutput.connect(lambda: stdout_ready())
        proc.readyReadStandardError.connect(lambda: stderr_ready())
        proc.finished.connect(lambda *a: finished(*a))
        proc.start(FETCH, args)

    @Slot(unicode, unicode, unicode)
    def request(self, tag, url, data):
        self.start(tag, url, data=data)

    @Slot(result=unicode)
    def take(self):
        if not self.results:
            return u''
        return unicode(json.dumps(self.results.pop(0)))

    @Slot(result=bool)
    def online(self):
        """Checked before each request: starting one without a connection makes
        the phone show its "choose a network" dialog again and again."""
        return default_route() != ''

    @Slot(result=unicode)
    def link(self):
        """wifi, mobile or none."""
        dev = default_route()
        if not dev:
            return u'none'
        if dev.startswith('wlan') or dev == 'unknown':
            return u'wifi'
        return u'mobile'

    @Slot(unicode)
    def cancel(self, tag):
        proc = self.procs.pop(tag, None)
        if proc:
            proc.kill()


class Store(QObject):
    """Settings (QSettings) and API keys (a private JSON file)."""

    def __init__(self):
        QObject.__init__(self)
        self.s = QSettings('hal2027', 'hal2027')
        ensure_dir(DATA_DIR)
        self.key_path = os.path.join(DATA_DIR, 'keys.json')

    @Slot(unicode, unicode, result=unicode)
    def get(self, key, default):
        v = self.s.value(key, default)
        if v is None:
            return default
        return unicode(v)

    @Slot(unicode, unicode)
    def set(self, key, value):
        self.s.setValue(key, value)
        self.s.sync()

    def keys(self):
        try:
            return json.load(open(self.key_path))
        except (IOError, ValueError):
            return {}

    def save_keys(self, keys):
        tmp = self.key_path + '.tmp'
        f = open(tmp, 'w')
        try:
            os.chmod(tmp, 0600)
            json.dump(keys, f)
        finally:
            f.close()
        os.rename(tmp, self.key_path)

    def key(self, provider):
        return self.keys().get(provider, u'')

    @Slot(unicode, result=bool)
    def hasKey(self, provider):
        return bool(self.key(provider))

    @Slot(unicode, result=unicode)
    def keyHint(self, provider):
        """Last 4 characters, to show which key is stored."""
        k = self.key(provider)
        return k and (u'…' + k[-4:]) or u''

    @Slot(unicode, unicode)
    def setKey(self, provider, value):
        keys = self.keys()
        value = u''.join(value.split())
        if value:
            keys[provider] = value
        else:
            keys.pop(provider, None)
        self.save_keys(keys)

    @Slot(result=unicode)
    def importKeys(self):
        """Reads 'service=key' lines from MyDocs/hal2027-klucze.txt (or
        hal2027-keys.txt), stores them and deletes the file. Returns the
        list of imported services as JSON, or {"error": ...}."""
        for d in KEY_FILE_DIRS:
            for n in KEY_FILE_NAMES:
                path = os.path.join(d, n)
                if not os.path.exists(path):
                    continue
                keys = self.keys()
                got = []
                try:
                    for line in open(path):
                        line = line.strip().lstrip('\xef\xbb\xbf')
                        if not line or line.startswith('#') or '=' not in line:
                            continue
                        name, value = line.split('=', 1)
                        name = name.strip().lower()
                        value = ''.join(value.split())
                        if name in PROVIDER and value:
                            keys[name] = value.decode('utf-8', 'replace')
                            got.append(name)
                except IOError, e:
                    return unicode(json.dumps({'error': str(e)}))
                if got:
                    self.save_keys(keys)
                    try:
                        os.remove(path)
                    except OSError:
                        pass
                return unicode(json.dumps({'imported': got, 'file': path}))
        return unicode(json.dumps({'error': 'nofile'}))

    @Slot(result=unicode)
    def providers(self):
        return unicode(json.dumps(PROVIDERS))


class History(QObject):
    """Conversations in SQLite."""

    def __init__(self):
        QObject.__init__(self)
        ensure_dir(DATA_DIR)
        self.db = sqlite3.connect(os.path.join(DATA_DIR, 'history.db'))
        self.db.execute('CREATE TABLE IF NOT EXISTS conv (id INTEGER PRIMARY KEY, '
                        'title TEXT, created REAL, updated REAL, provider TEXT, model TEXT)')
        self.db.execute('CREATE TABLE IF NOT EXISTS msg (id INTEGER PRIMARY KEY, conv INTEGER, '
                        'role TEXT, text TEXT, ts REAL, provider TEXT, model TEXT)')
        self.db.commit()

    def messages(self, conv):
        return [{'role': r[0], 'text': r[1]} for r in
                self.db.execute('SELECT role, text FROM msg WHERE conv=? ORDER BY id', (conv,))]

    @Slot(int, result=unicode)
    def load(self, conv):
        return unicode(json.dumps(self.messages(conv)))

    @Slot(result=unicode)
    def list(self):
        return self.search(u'')

    @Slot(unicode, result=unicode)
    def search(self, pattern):
        """Conversations whose title or any message matches the pattern:
        * = any text, ? = one character; without them the words are looked
        for anywhere. Letter case and Polish (and other) accents are ignored,
        so "zolw" finds "żółw"."""
        pattern = fold(pattern.strip())
        if not pattern:
            rows = self.db.execute('SELECT c.id, c.title, c.updated, c.provider '
                                   'FROM conv c ORDER BY c.updated DESC LIMIT 200').fetchall()
        else:
            rx = re.compile(re.escape(pattern).replace('\\*', '.*').replace('\\?', '.'),
                            re.UNICODE | re.DOTALL)
            self.db.create_function('hal_match', 1, lambda t: t is not None and rx.search(fold(t)) is not None)
            rows = self.db.execute('SELECT c.id, c.title, c.updated, c.provider FROM conv c '
                                   'WHERE hal_match(c.title) OR EXISTS (SELECT 1 FROM msg m '
                                   'WHERE m.conv=c.id AND hal_match(m.text)) '
                                   'ORDER BY c.updated DESC LIMIT 200').fetchall()
        return unicode(json.dumps([{'id': r[0], 'title': r[1], 'updated': r[2],
                                    'provider': r[3]} for r in rows]))

    def add(self, conv, role, text, provider=u'', model=u''):
        now = time.time()
        if not conv:
            title = u' '.join(text.split())[:200]
            cur = self.db.execute('INSERT INTO conv (title, created, updated, provider, model) '
                                  'VALUES (?,?,?,?,?)', (title, now, now, provider, model))
            conv = cur.lastrowid
        self.db.execute('INSERT INTO msg (conv, role, text, ts, provider, model) VALUES (?,?,?,?,?,?)',
                        (conv, role, text, now, provider, model))
        self.db.execute('UPDATE conv SET updated=? WHERE id=?', (now, conv))
        self.db.commit()
        return conv

    @Slot(int)
    def remove(self, conv):
        self.db.execute('DELETE FROM msg WHERE conv=?', (conv,))
        self.db.execute('DELETE FROM conv WHERE id=?', (conv,))
        self.db.commit()

    @Slot(int, result=unicode)
    def export(self, conv):
        """Saves the conversation as a text file; returns its path ('' on error)."""
        row = self.db.execute('SELECT title, created FROM conv WHERE id=?', (conv,)).fetchone()
        if not row:
            return u''
        try:
            ensure_dir(DOCS_DIR)
            name = time.strftime('rozmowa-%Y%m%d-%H%M%S.txt', time.localtime(row[1]))
            path = os.path.join(DOCS_DIR, name)
            f = open(path, 'w')
            try:
                f.write(('HAL 2027: %s\n%s\n\n' % (row[0], time.strftime('%Y-%m-%d %H:%M', time.localtime(row[1])))).encode('utf-8'))
                for m in self.messages(conv):
                    who = m['role'] == 'user' and u'>' or u'HAL:'
                    f.write((u'%s %s\n\n' % (who, m['text'])).encode('utf-8'))
            finally:
                f.close()
            return unicode(path)
        except (IOError, OSError), e:
            print 'hal2027: export failed:', e
            return u''


def fold(text):
    """Lower case without accents, for searching (ł has no decomposition)."""
    text = unicodedata.normalize('NFKD', unicode(text).lower().replace(u'\u0142', u'l'))
    return u''.join(c for c in text if not unicodedata.combining(c))


def sse_lines(buf, chunk):
    """Adds chunk to buf (list with one string), returns complete 'data:' payloads."""
    buf[0] += chunk
    out = []
    while '\n' in buf[0]:
        line, buf[0] = buf[0].split('\n', 1)
        line = line.rstrip('\r')
        if line.startswith('data:'):
            out.append(line[5:].strip())
    return out


def api_error(body, status):
    """A readable message from an API error body."""
    try:
        j = json.loads(body)
        if isinstance(j, list) and j:
            j = j[0]
        e = j.get('error', j)
        if isinstance(e, dict):
            msg = e.get('message') or e.get('status') or e.get('type')
        else:
            msg = e
        if msg:
            return u'%s%s' % (status and (u'HTTP %d: ' % status) or u'', msg)
    except (ValueError, AttributeError, TypeError):
        pass
    body = body.strip()
    if status:
        return u'HTTP %d %s' % (status, body[:160])
    return body[:200] or u'?'


class Chat(QObject):
    """Sends the conversation to the chosen service and streams the answer.
    QML reads events with take(): {type: start|delta|done|error, ...}."""

    event = Signal()

    def __init__(self, net, store, history):
        QObject.__init__(self)
        self.net = net
        self.store = store
        self.history = history
        self.events = []
        self.conv = 0
        self.answer = []
        self.job = 0
        ensure_dir(CACHE_DIR)

    def push(self, ev):
        self.events.append(ev)
        self.event.emit()

    @Slot(result=unicode)
    def take(self):
        if not self.events:
            return u''
        return unicode(json.dumps(self.events.pop(0)))

    @Slot(result=int)
    def conversation(self):
        return self.conv

    @Slot(int)
    def open(self, conv):
        self.stop()
        self.conv = conv

    @Slot()
    def newConversation(self):
        self.stop()
        self.conv = 0

    def provider(self):
        pid = self.store.get(u'provider', u'gemini')
        return PROVIDER.get(pid, PROVIDERS[0])

    @Slot(result=unicode)
    def providerName(self):
        return unicode(self.provider()['name'])

    @Slot(unicode, result=unicode)
    def model(self, pid):
        p = PROVIDER.get(pid, PROVIDERS[0])
        if pid == 'gemini' and self.store.get(u'cfgVersion', u'1') == u'1':
            # 0.1.0 stored gemini-3.8-flash, which hangs on the free tier
            if self.store.get(u'model.gemini', u'') == u'gemini-3.8-flash':
                self.store.set(u'model.gemini', p['model'])
            self.store.set(u'cfgVersion', u'2')
        return self.store.get(u'model.' + pid, p['model'])

    @Slot(unicode, unicode)
    def setModel(self, pid, model):
        self.store.set(u'model.' + pid, model.strip())

    @Slot(unicode, bool)
    def send(self, text, mobile):
        text = text.strip()
        if not text:
            return
        p = self.provider()
        key = self.store.key(p['id'])
        model = self.model(p['id'])
        if not key:
            self.push({'type': 'error', 'code': 'nokey', 'message': p['name']})
            return
        if not model:
            self.push({'type': 'error', 'code': 'nomodel', 'message': p['name']})
            return
        self.stop()
        self.conv = self.history.add(self.conv, u'user', text, p['id'], model)
        msgs = self.history.messages(self.conv)[-40:]
        system = SYSTEM_PROMPT % time.strftime('%Y-%m-%d %H:%M (%A)')
        if mobile:
            system += SYSTEM_MOBILE
        self.job += 1
        job = self.job
        chain = [model]
        if p['kind'] == 'gemini':
            chain += [m for m in GEMINI_FALLBACK if m != model]
        self.push({'type': 'start', 'conv': self.conv})
        self.attempt(job, p, key, chain, 0, system, msgs)

    def attempt(self, job, p, key, chain, n, system, msgs):
        model = chain[n]
        last = n == len(chain) - 1
        self.answer = []
        url, headers, body, parse = getattr(self, 'req_' + p['kind'])(p, key, model, system, msgs)
        headers = headers + [h.encode('utf-8') for h in p.get('headers', [])]
        path = os.path.join(CACHE_DIR, 'request.json')
        f = open(path, 'w')
        try:
            f.write(json.dumps(body))
        finally:
            f.close()
        buf = ['']
        state = {'error': u''}

        def chunk(data):
            if job != self.job:
                return
            for payload in sse_lines(buf, data):
                if payload == '[DONE]':
                    continue
                try:
                    j = json.loads(payload)
                except ValueError:
                    continue
                text, err = parse(j)
                if err:
                    state['error'] = err
                if text:
                    self.answer.append(text)
                    self.push({'type': 'delta', 'text': text})

        def done(ok, raw, status):
            if job != self.job:
                return
            answer = u''.join(self.answer)
            if not answer and not last and (status in RETRY_STATUS or (not ok and status == 0)):
                print 'hal2027: %s failed (%s), trying %s' % (model, status or 'timeout', chain[n + 1])
                self.push({'type': 'fallback', 'model': chain[n + 1], 'failed': model})
                self.attempt(job, p, key, chain, n + 1, system, msgs)
                return
            if not ok or (not answer and not state['error']):
                if not answer:
                    msg = state['error'] or api_error(raw, status)
                    self.push({'type': 'error', 'code': 'api', 'message': msg, 'status': status})
                    return
            if state['error'] and not answer:
                self.push({'type': 'error', 'code': 'api', 'message': state['error']})
                return
            self.history.add(self.conv, u'assistant', answer, p['id'], model)
            self.push({'type': 'done', 'text': answer, 'note': state['error'], 'model': model})

        # a model that stays silent this long is treated as overloaded when
        # there is another one to try
        self.net.start('chat', url, datafile=path, ctype='application/json', headers=headers,
                       idle=last and 90 or 30, on_chunk=chunk, on_done=done)

    @Slot()
    def stop(self):
        self.job += 1
        self.net.cancel('chat')

    # ---- request builders: -> url, headers, body, parse(json) -> (text, error)

    def req_gemini(self, p, key, model, system, msgs):
        contents = []
        for m in msgs:
            contents.append({'role': m['role'] == 'user' and 'user' or 'model',
                             'parts': [{'text': m['text']}]})
        body = {'contents': contents, 'systemInstruction': {'parts': [{'text': system}]}}
        url = '%s/models/%s:streamGenerateContent?alt=sse' % (p['base'], model)

        def parse(j):
            if 'error' in j:
                return u'', api_error(json.dumps(j), 0)
            out = []
            for c in j.get('candidates', []):
                for part in c.get('content', {}).get('parts', []):
                    if part.get('text') and not part.get('thought'):
                        out.append(part['text'])
                if c.get('finishReason') in ('SAFETY', 'PROHIBITED_CONTENT', 'BLOCKLIST'):
                    return u''.join(out), u'blocked: ' + c['finishReason']
            return u''.join(out), u''
        return url, ['x-goog-api-key: ' + key.encode('utf-8')], body, parse

    def req_anthropic(self, p, key, model, system, msgs):
        body = {'model': model, 'max_tokens': 64000, 'stream': True, 'system': system,
                'messages': [{'role': m['role'], 'content': m['text']} for m in msgs],
                'output_config': {'effort': self.store.get(u'effort', u'low')}}
        headers = ['x-api-key: ' + key.encode('utf-8'),
                   'anthropic-version: ' + ANTHROPIC_VERSION]
        # server-side fallback when a safety classifier declines (models that support it)
        if model.startswith(('claude-opus-5', 'claude-fable-5', 'claude-sonnet-5-5')):
            body['fallbacks'] = 'default'
            headers.append('anthropic-beta: server-side-fallback-2026-07-01')

        def parse(j):
            t = j.get('type')
            if t == 'content_block_delta' and j.get('delta', {}).get('type') == 'text_delta':
                return j['delta'].get('text', u''), u''
            if t == 'message_delta' and j.get('delta', {}).get('stop_reason') == 'refusal':
                return u'', u'refusal'
            if t == 'error':
                return u'', api_error(json.dumps(j), 0)
            return u'', u''
        return p['base'] + '/messages', headers, body, parse

    def req_openai(self, p, key, model, system, msgs):
        messages = [{'role': 'system', 'content': system}]
        messages += [{'role': m['role'], 'content': m['text']} for m in msgs]
        body = {'model': model, 'stream': True, 'messages': messages}
        headers = ['Authorization: Bearer ' + key.encode('utf-8')]
        if p['id'] == 'openrouter':
            headers += ['HTTP-Referer: https://github.com/smyhu/hal2027-n9', 'X-Title: HAL 2027']

        def parse(j):
            if 'error' in j:
                return u'', api_error(json.dumps(j), 0)
            out = []
            for c in j.get('choices', []):
                d = c.get('delta') or {}
                if d.get('content'):
                    out.append(d['content'])
            return u''.join(out), u''
        return p['base'] + '/chat/completions', headers, body, parse

    # ---- model lists

    @Slot(unicode)
    def fetchModels(self, pid):
        p = PROVIDER.get(pid)
        key = self.store.key(pid)
        if not p or not key:
            self.push({'type': 'models', 'error': 'nokey', 'models': []})
            return
        k = key.encode('utf-8')
        if p['kind'] == 'gemini':
            url, headers = p['base'] + '/models?pageSize=200', ['x-goog-api-key: ' + k]
        elif p['kind'] == 'anthropic':
            url, headers = p['base'] + '/models?limit=100', ['x-api-key: ' + k, 'anthropic-version: ' + ANTHROPIC_VERSION]
        else:
            url, headers = p['base'] + '/models', ['Authorization: Bearer ' + k]

        def done(ok, body, status):
            if not ok:
                self.push({'type': 'models', 'error': api_error(body, status), 'models': []})
                return
            try:
                j = json.loads(body)
            except ValueError:
                self.push({'type': 'models', 'error': body[:100], 'models': []})
                return
            names = []
            if p['kind'] == 'gemini':
                for m in j.get('models', []):
                    if 'generateContent' in m.get('supportedGenerationMethods', []):
                        names.append(m.get('name', '').replace('models/', ''))
            else:
                for m in j.get('data', []):
                    names.append(m.get('id', ''))
            names = [n for n in names if n]
            self.push({'type': 'models', 'error': '', 'models': names})
        self.net.start('models', url, headers=headers, idle=30, on_done=done)

    @Slot(unicode, result=unicode)
    def toHtml(self, text):
        return unicode(markdown_html(text))


def markdown_html(text):
    """Very small Markdown subset -> Qt rich text (bold, italic, code, lists)."""
    import re
    import cgi
    out = []
    for line in text.split(u'\n'):
        s = cgi.escape(line)
        s = re.sub(u'^#{1,6}\\s*(.*)$', u'<b>\\1</b>', s)
        s = re.sub(u'^\\s*[-*•]\\s+', u'• ', s)
        s = re.sub(u'\\*\\*(.+?)\\*\\*', u'<b>\\1</b>', s)
        s = re.sub(u'(?<![\\w*])\\*(?!\\s)(.+?)(?<!\\s)\\*(?![\\w*])', u'<i>\\1</i>', s)
        s = re.sub(u'`([^`]+)`', u'<tt>\\1</tt>', s)
        out.append(s)
    return u'<br>'.join(out)


class Speech(QObject):
    """Google text-to-speech: downloads MP3 pieces (max ~180 characters each),
    QML plays them one after another. (From MeeTranslate.)"""

    ready = Signal()
    failed = Signal()

    def __init__(self, net, store):
        QObject.__init__(self)
        self.net = net
        self.store = store
        self.job = 0
        self.files = []
        self.proc = None

    @Slot(result=bool)
    def offlineAvailable(self):
        return os.path.exists(ESPEAK) and os.path.isdir(ESPEAK_DATA)

    @staticmethod
    def espeak_voice(lang):
        lang = (lang or 'en').lower().replace('_', '-')
        for name in (lang, lang.split('-')[0]):
            for d in ('lang',):
                for root, dirs, files in os.walk(os.path.join(ESPEAK_DATA, d)):
                    if name in files:
                        return name
        return 'en'

    @Slot(result=unicode)
    def takeFiles(self):
        return unicode(json.dumps(self.files))

    @staticmethod
    def pieces(text, limit=180):
        text = u' '.join(text.replace(u'*', u' ').replace(u'#', u' ').split())
        out = []
        while len(text) > limit:
            cut = -1
            for mark in (u'. ', u'! ', u'? ', u'; ', u': ', u', ', u' '):
                cut = text.rfind(mark, 0, limit)
                if cut > limit / 3:
                    cut += len(mark) - 1
                    break
            if cut <= 0:
                cut = limit
            out.append(text[:cut].strip())
            text = text[cut:].strip()
        if text:
            out.append(text)
        return out

    @Slot(unicode, unicode)
    def speak(self, text, lang):
        self.speakWith(text, lang, u'google')

    @Slot(unicode, unicode, unicode)
    def speakWith(self, text, lang, engine):
        """engine: google (internet) or offline (espeak-ng on the phone)."""
        import urllib
        self.stop()
        self.job += 1
        job = self.job
        ensure_dir(TTS_DIR)
        for f in os.listdir(TTS_DIR):
            try:
                os.remove(os.path.join(TTS_DIR, f))
            except OSError:
                pass
        parts = self.pieces(text)[:30]
        files = []
        if engine == 'offline':
            self.speak_offline(job, parts, files, self.espeak_voice(lang))
            return

        def next_piece(i):
            if job != self.job:
                return
            if i >= len(parts):
                self.files = files
                self.ready.emit()
                return
            q = urllib.quote(parts[i].encode('utf-8'))
            url = ('https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=%s&total=%d&idx=%d&textlen=%d&q=%s'
                   % (urllib.quote(lang.encode('utf-8')), len(parts), i, len(parts[i]), q))
            out = os.path.join(TTS_DIR, 'part%02d.mp3' % i)

            def done(ok, err, status):
                if job != self.job:
                    return
                if not ok:
                    self.failed.emit()
                    return
                files.append(out)
                # the first piece starts playing while the rest download
                if i == 0:
                    self.files = list(files)
                    self.ready.emit()
                next_piece(i + 1)

            self.net.start('tts', url, outfile=out, idle=20, on_done=done)

        next_piece(0)

    def speak_offline(self, job, parts, files, voice):
        def next_piece(i):
            if job != self.job:
                return
            if i >= len(parts):
                self.proc = None
                self.files = files
                self.ready.emit()
                return
            out = os.path.join(TTS_DIR, 'part%02d.wav' % i)
            proc = QProcess(self)
            self.proc = proc

            def finished(*a):
                if job != self.job or self.proc is not proc:
                    return
                proc.deleteLater()
                ok = proc.exitStatus() == QProcess.NormalExit and proc.exitCode() == 0 and os.path.exists(out)
                if not ok:
                    print 'hal2027: espeak-ng failed: %s' % str(proc.readAllStandardError())[:200]
                    self.proc = None
                    self.failed.emit()
                    return
                files.append(out)
                if i == 0:
                    self.files = list(files)
                    self.ready.emit()
                next_piece(i + 1)

            proc.finished.connect(lambda *a: finished(*a))
            style = ['-s', str(self.store.get(u'voiceSpeed', unicode(VOICE_SPEED))),
                     '-p', str(self.store.get(u'voicePitch', unicode(VOICE_PITCH))), '-g', '2']
            proc.start(ESPEAK, ['--path=' + ESPEAK_DATA, '-v', voice] + style +
                       ['-w', out, parts[i]])

        next_piece(0)

    @Slot(result=unicode)
    def allFiles(self):
        try:
            names = sorted(f for f in os.listdir(TTS_DIR) if f.endswith('.mp3') or f.endswith('.wav'))
        except OSError:
            names = []
        return unicode(json.dumps([os.path.join(TTS_DIR, n) for n in names]))

    @Slot(result=bool)
    def downloading(self):
        return 'tts' in self.net.procs or self.proc is not None

    @Slot()
    def stop(self):
        self.job += 1
        self.net.cancel('tts')
        if self.proc:
            self.proc.kill()
            self.proc = None


class Listener(QObject):
    """Voice input. hal2027-rec records the microphone (PulseAudio) into a
    WAV file; then the recording goes to the speech-to-text services in
    the SPEECH_TO_TEXT order until one returns text. Events for QML (take()):
      level {value 0..1, seconds}, transcribing {service}, fallback {service},
      text {text, service}, error {code: mic | nokey | api | short, message}."""

    # not 'event': that name would hide QObject.event(), which Qt calls
    # when the recorder process (a child object) is added or removed
    news = Signal()

    def __init__(self, net, store):
        QObject.__init__(self)
        self.net = net
        self.store = store
        self.proc = None
        self.job = 0
        self.events = []
        self.wav = os.path.join(CACHE_DIR, 'mowa.wav')

    def push(self, ev):
        self.events.append(ev)
        self.news.emit()

    @Slot(result=unicode)
    def take(self):
        if not self.events:
            return u''
        return unicode(json.dumps(self.events.pop(0)))

    @Slot(result=int)
    def maxSeconds(self):
        return LISTEN_MAX_SECONDS

    def services(self):
        out = []
        for e in SPEECH_TO_TEXT:
            key = self.store.key(e.get('key', e['id']))
            base = e.get('base') or PROVIDER.get(e.get('key', e['id']), {}).get('base')
            if key and base:
                out.append((e, key, base))
        return out

    @Slot(result=bool)
    def available(self):
        return len(self.services()) > 0

    @Slot(unicode)
    def record(self, lang):
        """Starts recording; lang is the expected language (pl, en...)."""
        self.drop()
        if not self.services():
            self.push({'type': 'error', 'code': 'nokey'})
            return
        ensure_dir(CACHE_DIR)
        if os.path.exists(self.wav):
            os.remove(self.wav)
        self.job += 1
        job = self.job
        self.lang = lang
        proc = QProcess(self)
        self.proc = proc
        state = {'error': u'', 'seconds': 0.0, 'buf': ''}

        def ready():
            state['buf'] += str(proc.readAllStandardOutput())
            lines = state['buf'].split('\n')
            state['buf'] = lines.pop()
            level = None
            for line in lines:
                if line.startswith('level '):
                    try:
                        level = int(line.split()[1]) / 100.0
                    except ValueError:
                        pass
                    state['seconds'] += 0.1
                elif line.startswith('error '):
                    state['error'] = unicode(line[6:], 'utf-8', 'replace')
                elif line.startswith('done '):
                    try:
                        state['seconds'] = float(line.split()[1])
                    except ValueError:
                        pass
            if level is not None and job == self.job:
                self.push({'type': 'level', 'value': level, 'seconds': state['seconds']})

        def finished(*args):
            ready()
            if self.proc is proc:
                self.proc = None
            proc.deleteLater()
            if job != self.job:
                return
            if state['error'] or not os.path.exists(self.wav):
                print 'hal2027: recording failed: %s' % state['error'].encode('utf-8')
                self.push({'type': 'error', 'code': 'mic', 'message': state['error'] or u'no recording'})
                return
            if state['seconds'] < 0.6:
                self.push({'type': 'error', 'code': 'short'})
                return
            self.sent = time.time()
            self.transcribe(job, self.services(), 0)

        proc.readyReadStandardOutput.connect(lambda: ready())
        proc.finished.connect(lambda *a: finished(*a))
        proc.start(REC, [self.wav, str(LISTEN_MAX_SECONDS)])
        if not proc.waitForStarted(3000):
            self.proc = None
            self.push({'type': 'error', 'code': 'mic', 'message': u'hal2027-rec did not start'})

    @Slot()
    def finish(self):
        """Ends recording and sends it to be written down."""
        proc = self.proc
        if not proc:
            return
        proc.write('q\n')         # the recorder stops on any input line
        proc.terminate()
        # the WAV header is kept valid while recording, so a recorder that
        # does not stop in time can simply be killed
        timer = QTimer(self)
        timer.setSingleShot(True)

        def late():
            timer.deleteLater()
            if proc is self.proc:
                print 'hal2027: recorder did not stop, killing it'
                proc.kill()
        timer.timeout.connect(lambda: late())
        timer.start(1500)

    @Slot()
    def drop(self):
        """Drops the recording or the transcription in progress."""
        self.job += 1
        if self.proc:
            self.proc.kill()
            self.proc = None
        self.net.cancel('stt')

    def transcribe(self, job, services, n):
        entry, key, base = services[n]
        name = PROVIDER.get(entry.get('key', entry['id']), {}).get('short') or \
            PROVIDER.get(entry.get('key', entry['id']), {}).get('name') or entry['id']
        self.push({'type': n and 'fallback' or 'transcribing', 'service': name})
        lang = self.lang or u'pl'
        if entry['kind'] == 'gemini':
            models = entry.get('models') or GEMINI_FALLBACK
            self.stt_gemini(job, services, n, key, base, models, 0, lang, name)
        else:
            self.stt_whisper(job, services, n, key, base, entry, lang, name)

    def next_service(self, job, services, n, message):
        if job != self.job:
            return
        if n + 1 < len(services):
            print 'hal2027: speech to text: %s failed (%s), trying %s' % (
                services[n][0]['id'], message.encode('utf-8'), services[n + 1][0]['id'])
            self.transcribe(job, services, n + 1)
        else:
            self.push({'type': 'error', 'code': 'api', 'message': message})

    def deliver(self, job, text, name):
        if job != self.job:
            return
        print 'hal2027: speech written down by %s in %.1f s' % (name.encode('utf-8'), time.time() - self.sent)
        self.push({'type': 'text', 'text': text.strip(), 'service': name})

    def stt_gemini(self, job, services, n, key, base, models, m, lang, name, think_off=True):
        import base64
        audio = base64.b64encode(open(self.wav, 'rb').read())
        prompt = ('Write down exactly what is said in this recording (most likely in the '
                  'language with code "%s"). Return only the spoken words with normal '
                  'punctuation, no comments. If nothing is said, return nothing.' % lang)
        body = {'contents': [{'role': 'user', 'parts': [
                    {'text': prompt},
                    {'inline_data': {'mime_type': 'audio/wav', 'data': audio}}]}],
                'generationConfig': {'temperature': 0}}
        if think_off:       # writing down needs no thinking, and thinking takes seconds
            body['generationConfig']['thinkingConfig'] = {'thinkingBudget': 0}
        path = os.path.join(CACHE_DIR, 'stt.json')
        f = open(path, 'w')
        try:
            f.write(json.dumps(body))
        finally:
            f.close()
        url = '%s/models/%s:generateContent' % (base, models[m])

        def done(ok, raw, status):
            if job != self.job:
                return
            text = u''
            try:
                j = json.loads(raw)
                for c in j.get('candidates', []):
                    for part in c.get('content', {}).get('parts', []):
                        if part.get('text') and not part.get('thought'):
                            text += part['text']
            except ValueError:
                pass
            if ok and text.strip():
                self.deliver(job, text, name)
            elif ok:
                self.push({'type': 'error', 'code': 'empty'})
            elif status == 400 and think_off:
                # a model that cannot switch thinking off: ask again without it
                self.stt_gemini(job, services, n, key, base, models, m, lang, name, False)
            elif m + 1 < len(models) and (status in RETRY_STATUS or status == 0):
                self.stt_gemini(job, services, n, key, base, models, m + 1, lang, name)
            else:
                self.next_service(job, services, n, api_error(raw, status))

        self.net.start('stt', url, datafile=path, ctype='application/json',
                       headers=['x-goog-api-key: ' + key.encode('utf-8')], idle=30, on_done=done)

    def stt_whisper(self, job, services, n, key, base, entry, lang, name):
        boundary = 'hal2027-%d' % int(time.time() * 1000)
        fields = [('model', entry.get('model', 'whisper-1')), ('response_format', 'json')]
        if entry.get('language', True):
            fields.append(('language', lang))
        parts = []
        for k, v in fields:
            parts.append('--%s\r\nContent-Disposition: form-data; name="%s"\r\n\r\n%s\r\n'
                         % (boundary, k, v.encode('utf-8') if isinstance(v, unicode) else v))
        parts.append('--%s\r\nContent-Disposition: form-data; name="file"; filename="mowa.wav"\r\n'
                     'Content-Type: audio/wav\r\n\r\n' % boundary)
        path = os.path.join(CACHE_DIR, 'stt.form')
        f = open(path, 'wb')
        try:
            f.write(''.join(parts))
            f.write(open(self.wav, 'rb').read())
            f.write('\r\n--%s--\r\n' % boundary)
        finally:
            f.close()
        headers = ['Authorization: Bearer ' + key.encode('utf-8')]
        headers += [h.encode('utf-8') for h in entry.get('headers', [])]

        def done(ok, raw, status):
            if job != self.job:
                return
            text = u''
            try:
                text = json.loads(raw).get('text') or u''
            except (ValueError, AttributeError):
                pass
            if ok and text.strip():
                self.deliver(job, text, name)
            elif ok:
                self.push({'type': 'error', 'code': 'empty'})
            else:
                self.next_service(job, services, n, api_error(raw, status))

        self.net.start('stt', base.rstrip('/') + '/audio/transcriptions', datafile=path,
                       ctype='multipart/form-data; boundary=' + boundary,
                       headers=headers, idle=30, on_done=done)


class Clipboard(QObject):
    @Slot(result=unicode)
    def text(self):
        return QApplication.clipboard().text()

    @Slot(unicode)
    def setText(self, text):
        QApplication.clipboard().setText(text)


def main():
    app = QApplication(sys.argv)
    app.setApplicationName('hal2027')
    app.setOrganizationName('hal2027')

    view = QDeclarativeView()
    net = Net()
    store = Store()
    history = History()
    chat = Chat(net, store, history)
    speech = Speech(net, store)
    listener = Listener(net, store)
    clipboard = Clipboard()
    ctx = view.rootContext()
    ctx.setContextProperty('uiLang', phone_language())
    ctx.setContextProperty('appVersion', VERSION)
    ctx.setContextProperty('net', net)
    ctx.setContextProperty('store', store)
    ctx.setContextProperty('history', history)
    ctx.setContextProperty('chat', chat)
    ctx.setContextProperty('speech', speech)
    ctx.setContextProperty('listener', listener)
    ctx.setContextProperty('clipboard', clipboard)
    ctx.setContextProperty('docsDir', DOCS_DIR)
    view.setResizeMode(QDeclarativeView.SizeRootObjectToView)
    view.setSource(QUrl.fromLocalFile(os.path.join(APP_DIR, 'qml', 'main.qml')))
    view.showFullScreen()
    sys.exit(app.exec_())


if __name__ == '__main__':
    main()
