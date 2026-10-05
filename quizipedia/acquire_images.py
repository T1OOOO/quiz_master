"""Acquire the individually reviewed Commons assets; run under a host asset lease.

The app receives small raster files. Original SVG and provenance remain available
beside the sources; no image labels or other factual details are edited.
"""
import hashlib
import html
import json
from pathlib import Path
import re
import urllib.parse
import urllib.request
import urllib.error
import time

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'next/apps/quiz_app/assets/quizipedia'
CACHE = ROOT / '.run/quizipedia/images'
HEADERS = {'User-Agent': 'QuizMasterEducationalAssets/1.0 (quiz.kotopedia.org)'}


def download(url, destination, limit=12_000_000):
    if destination.exists():
        return hashlib.sha256(destination.read_bytes()).hexdigest()
    request = urllib.request.Request(url, headers=HEADERS)
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=40) as response:
                data = response.read(limit + 1)
            break
        except urllib.error.HTTPError as error:
            if error.code != 429 or attempt == 2:
                raise
            delay = min(45, max(10, int(error.headers.get('Retry-After', '20'))))
            print('Source rate limit; waiting', delay, 'seconds', flush=True)
            time.sleep(delay)
    if len(data) > limit:
        raise ValueError('Asset exceeds acquisition budget')
    destination.write_bytes(data)
    return hashlib.sha256(data).hexdigest()


def original_url(page):
    with urllib.request.urlopen(urllib.request.Request(page, headers=HEADERS), timeout=30) as response:
        text = response.read(2_000_000).decode('utf-8')
    match = re.search(r'class="fullImageLink"[^>]*>.*?<a href="([^"]+)"', text, re.S)
    if not match:
        raise ValueError('No original file link: ' + page)
    url = html.unescape(match[1])
    if urllib.parse.urlparse(url).hostname != 'upload.wikimedia.org':
        raise ValueError('Unexpected original host')
    return url


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    CACHE.mkdir(parents=True, exist_ok=True)
    content = json.loads((ROOT / 'quizipedia/content.json').read_text(encoding='utf-8'))
    records = []
    for item in content['landmarks']:
        title = item['file_title'].replace(' ', '_')
        page = 'https://commons.wikimedia.org/wiki/File:' + urllib.parse.quote(title)
        url = original_url(page)
        original = CACHE / (item['id'] + '.jpg')
        digest = download(url, original)
        target = OUT / (item['id'] + '.jpg')
        with Image.open(original) as image:
            image = ImageOps.exif_transpose(image)
            image.thumbnail((960, 960), Image.Resampling.LANCZOS)
            image.convert('RGB').save(target, quality=88, optimize=True)
        records.append(dict(id=item['id'], image_asset='assets/quizipedia/' + target.name,
                            source_url=page, original_url=url, original_sha256=digest,
                            sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
                            creator=item['creator'], license=item['license'],
                            license_url=item['license_url'], acquired_on='2026-10-05',
                            modification='EXIF orientation applied; resized to maximum 960 pixels and JPEG recompressed.'))
        (ROOT / 'quizipedia/images-manifest.json').write_text(json.dumps(records, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
        print('Acquired', item['id'], flush=True)
        time.sleep(2)
    page = 'https://commons.wikimedia.org/wiki/File:Human_endocrine_male_%26_female_svg_no_labels.svg'
    url = original_url(page)
    original = ROOT / 'quizipedia/sources/endocrine.svg'
    original.parent.mkdir(exist_ok=True)
    digest = download(url, original)
    # Commons' published rasterization of that exact SVG; no synthetic diagram.
    raster = 'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5d/Human_endocrine_male_%26_female_svg_no_labels.svg/960px-Human_endocrine_male_%26_female_svg_no_labels.svg.png'
    target = OUT / 'endocrine.png'
    rendered_digest = download(raster, target)
    with Image.open(target) as image:
        width, height = image.size
        image.verify()
    records.append(dict(id='endocrine', image_asset='assets/quizipedia/endocrine.png',
                        source_url=page, original_url=url, original_sha256=digest,
                        raster_url=raster, sha256=rendered_digest, width=width, height=height,
                        creator='OpenStax, Tomáš Kebert and umimeto.org',
                        license='CC BY-SA 4.0', license_url='https://creativecommons.org/licenses/by-sa/4.0/',
                        acquired_on='2026-10-05', modification='Commons rasterization; original diagram unchanged.'))
    (ROOT / 'quizipedia/images-manifest.json').write_text(json.dumps(records, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print('Acquired endocrine', width, height, flush=True)


if __name__ == '__main__':
    main()
