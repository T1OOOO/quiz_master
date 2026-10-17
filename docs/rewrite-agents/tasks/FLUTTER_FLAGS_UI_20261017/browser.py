"""Record finite official browser CLI calls for this isolated fixture."""
from pathlib import Path
import base64,json,re,subprocess,sys
ROOT=Path(__file__).resolve().parents[4]
PACKET=Path(__file__).resolve().parent
name=sys.argv[1]
assert re.fullmatch(r'[a-z0-9-]+',name)
args=sys.argv[2:]
if args[0]=='eval-file':
    script=Path(args[1]).read_bytes()
    args=['eval','-b',base64.b64encode(script).decode(),'--json']
exe='C:/Users/Alexey_Matvienko/AppData/Roaming/npm/node_modules/agent-browser/bin/agent-browser-win32-x64.exe'
command=[exe,'--session','qm-flutter-flags-20261017','--allowed-domains','127.0.0.1,quiz.kotopedia.org,www.gstatic.com,fonts.gstatic.com,fonts.googleapis.com','--init-script',str(PACKET/'media-init.js'),*args]
raw=PACKET/(name+'-raw.txt')
with raw.open('w',encoding='utf-8') as stream:
    process=subprocess.Popen(command,stdout=stream,stderr=subprocess.STDOUT,cwd=ROOT)
    try:
        code=process.wait(timeout=45)
        timed_out=False
    except subprocess.TimeoutExpired:
        process.terminate()
        code=process.wait(timeout=10)
        timed_out=True
receipt={'actual_exit':code,'stdout':raw.read_text(encoding='utf-8',errors='replace'),'stderr':'','timed_out':timed_out}
(PACKET/(name+'.json')).write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt,ensure_ascii=False)[:3200])
raise SystemExit(0 if receipt['actual_exit']==0 else 1)
