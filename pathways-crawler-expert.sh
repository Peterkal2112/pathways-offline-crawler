#!/bin/bash
# Expert Version: Fast-Sync & Deploy
TARGET="/opt/Pathways"
BASE_URL="https://www.shoutoutuk.org/gamepw/"

mkdir -p "$TARGET"/{html5/data/js,html5/lib/scripts,html5/lib/stylesheets,story_content,mobile}
cd "$TARGET" || exit

# 1. Fast Bootstrap
curl -sL "${BASE_URL}story.html" -o story.html
curl -sL "${BASE_URL}html5/data/js/data.js" -o html5/data/js/data.js
curl -sL "${BASE_URL}html5/data/js/paths.js" -o html5/data/js/paths.js

# 2. Optimized Deep Crawler
docker run -i --rm -v "$TARGET:/app" python:3.9-slim python3 -c "
import requests, os, re
base = '$BASE_URL'
root = '/app'
prefs = ['', 'html5/data/js/', 'html5/data/css/', 'html5/lib/scripts/', 'html5/lib/stylesheets/', 'mobile/', 'story_content/']
reg = r'[a-zA-Z0-9_/.-]+\.(?:png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico|cur|svg)'
scanned = set()

def sync():
    found = set()
    to_scan = [os.path.join(r, f) for r, _, fs in os.walk(root) for f in fs if f.endswith(('.js','.html','.css')) and os.path.join(r, f) not in scanned]
    if not to_scan: return False
    for fpath in to_scan:
        try:
            with open(fpath, 'r', errors='ignore') as f: found.update(re.findall(reg, f.read()))
            scanned.add(fpath)
        except: continue
    added = 0
    for link in found:
        name = link.split('?')[0].lstrip('/')
        if len(name) < 5 or name.startswith('http'): continue
        if any(os.path.exists(os.path.join(root, p + name if p and not name.startswith(p) else name)) for p in prefs): continue
        for p in prefs:
            rel = p + name if p and not name.startswith(p) else name
            try:
                r = requests.get(base + rel, timeout=5)
                if r.status_code == 200:
                    dest = os.path.join(root, rel)
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with open(dest, 'wb') as f: f.write(r.content)
                    added += 1; break
            except: continue
    return added > 0

while sync(): pass
"

# 3. Instant Host
printf "\033[1;32mSync Complete. Hosting at http://$(hostname -I | awk '{print $1}'):8080/story.html\033[0m\n"
python3 -m http.server 8080
