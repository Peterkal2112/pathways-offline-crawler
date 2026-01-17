#!/bin/bash

# --- LEGAL WARNING ---
printf "\033[1;31m"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "WARNING: ToS Violation Risk. Educational & Research use only.\n"
printf "Usage of this tool is at your own risk.\n"
printf "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
printf "\033[0m\n"

# 1. Path Setup
TARGET_DIR="/opt/Pathways"

# 2. Preparation
printf "\n\033[0;32m[*] Target Directory: %s\033[0m\n" "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR" || exit

# 3. Bootstrapping
printf "\033[0;32m[*] Bootstrapping main files...\033[0m\n"
curl -sL "https://www.shoutoutuk.org/wp-content/uploads/2024/06/pathways-teachers-guide-extremism-youth-radicalisation.pdf" -o "Teaching_Guide.pdf"
curl -sL "https://www.shoutoutuk.org/gamepw/story.html" -o "story.html"

# 4. Recursive Docker Crawler
printf "\033[0;32m[*] Launching Asset Crawler (Docker)...\033[0m\n"
docker run -i --rm --user 0:0 -v "$TARGET_DIR:/app" python:3.9-slim bash -c "
pip install requests > /dev/null 2>&1;
python3 -c \"
import requests, os, re
base_url = 'https://www.shoutoutuk.org/gamepw/'
target_root = '/app'
regex = r'[a-zA-Z0-9_/.-]+\.(?:png|gif|jpg|jpeg|mp3|mp4|wav|swf|json|js|css|woff|html|xml|ico|cur|svg)'

def crawl(initial_files=None):
    found_links = set()
    if initial_files:
        found_links.update(initial_files)
    for root, _, files in os.walk(target_root):
        for file in files:
            if file.endswith(('.js', '.html', '.css', '.xml', '.json')):
                try:
                    with open(os.path.join(root, file), 'r', errors='ignore') as f:
                        found_links.update(re.findall(regex, f.read()))
                except: continue
    to_download = {f.split('?')[0].lstrip('/') for f in found_links if not f.startswith(('http', 'data:', 'https:'))}
    new_assets = 0
    for path in sorted(to_download):
        prefixes = ['', 'html5/lib/scripts/', 'html5/data/css/', 'html5/data/js/', 'mobile/', 'story_content/']
        for p in prefixes:
            loc = p + os.path.basename(path) if p and '/' in path else path
            if p and not path.startswith(p): loc = p + path
            else: loc = path
            dest = os.path.join(target_root, loc)
            if os.path.exists(dest) or len(loc) < 4: continue
            try:
                r = requests.get(base_url + loc, headers={'User-Agent': 'Mozilla/5.0'}, timeout=5)
                if r.status_code == 200:
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    with open(dest, 'wb') as f: f.write(r.content)
                    print(f'  [OK] {loc}')
                    new_assets += 1
                    break
            except: continue
    return new_assets

seeds = ['html5/lib/scripts/bootstrapper.min.js', 'html5/data/css/output.min.css', 'story_content/user.js']
total = 0
while True:
    added = crawl(seeds if total == 0 else None)
    total += added
    if added == 0: break
    print(f'--- Added {added} files. Syncing... ---')
print(f'Sync Complete. Total assets: {total}')
\" "

# 5. Final message
if [ -f "$TARGET_DIR/story.html" ]; then
    printf "\n\033[0;32m[*] Process Finished. Files saved in: %s\033[0m\n" "$TARGET_DIR"
    IP_ADDR=$(hostname -I | awk '{print $1}')
    printf "\033[1;32mURL: http://%s:8080/story.html\033[0m\n" "$IP_ADDR"
    printf "\033[1;33mTo host, run: cd %s && python3 -m http.server 8080\033[0m\n" "$TARGET_DIR"
fi
