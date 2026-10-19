"""Package small previews; preserve every original licensed photograph."""
import base64, hashlib, io, json
from pathlib import Path
from PIL import Image, ImageOps, __version__
root = Path(__file__).resolve().parents[1]
catalog = json.loads((root/'assets/quizipedia/catalog.json').read_text(encoding='utf-8'))
photos = {}; evidence = []
for row in catalog['landmarks']:
    path = root/row['image_asset']; original = path.read_bytes()
    with Image.open(path) as source:
        image = ImageOps.exif_transpose(source).convert('RGB')
        image.thumbnail((160,160), Image.Resampling.LANCZOS)
        out = io.BytesIO(); image.save(out, format='WEBP', quality=72, method=6)
        data = out.getvalue(); assert max(image.size) <= 160
        photos[row['id']] = base64.b64encode(data).decode('ascii')
        evidence.append(dict(id=row['id'],source_asset=row['image_asset'],source_sha256=hashlib.sha256(original).hexdigest(),preview_sha256=hashlib.sha256(data).hexdigest(),preview_bytes=len(data),size=image.size))
assert len(photos) == len(catalog['landmarks'])
payload = (json.dumps(dict(schema_version='qm-landmark-thumbnails/v1',photos=photos),sort_keys=True,separators=(',',':'))+'\n').encode()
assert len(payload) < 500000
(root/'assets/quizipedia/landmark_thumbnails.json').write_bytes(payload)
evidence_path = root.parents[2]/'docs/rewrite-agents/tasks/WATER_PHOTO_20261020/thumbnail-provenance.json'
evidence_path.write_bytes((json.dumps(dict(tool='Pillow '+__version__,operation='EXIF orientation, fit within160x160, WebP quality72; originals unchanged',bundle_bytes=len(payload),images=evidence),ensure_ascii=False,indent=2)+'\n').encode())
print('Preview bundle:',len(photos),'photos,',len(payload),'bytes')
