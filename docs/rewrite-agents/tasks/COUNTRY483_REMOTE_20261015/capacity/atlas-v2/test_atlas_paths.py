import unittest,subprocess,re
from pathlib import Path
import correct_atlas_paths as c

class AtlasPaths(unittest.TestCase):
    def test_unexpected_or_already_corrected_paths_refused(self):
        for value in ('',c.OLD,c.OLD*3,c.OLD*2+c.NEW):
            with self.subTest(value=value),self.assertRaises(ValueError):c.patch(value)
    def test_real_derived_scripts_only_replace_two_image_paths(self):
        bodies=c.scripts()
        for name,body in bodies.items():
            self.assertEqual(body.count(c.NEW),2);self.assertNotIn(c.OLD,body)
            self.assertEqual((c.OWN/name).read_bytes(),body.encode())
            result=subprocess.run(['C:/Program Files/Git/bin/bash.exe','-n'],input=body.encode(),capture_output=True)
            self.assertEqual(result.returncode,0,result.stderr)
            blocks=re.findall(r"python3 - <<'([A-Z_0-9]+)'\n(.*?)\n\1(?:\n|$)",body,re.S)
            self.assertEqual(len(blocks),4 if name.startswith('resume') else 2)
            for marker,code in blocks:compile(code,marker,'exec')
            self.assertNotIn('helm upgrade',body)
        original=(c.OWN.parent/'resume-preparation.sh').read_text()
        self.assertEqual(bodies['resume-preparation-v2.sh'],original.replace(c.OLD,c.NEW))

if __name__=='__main__':unittest.main(verbosity=2)
