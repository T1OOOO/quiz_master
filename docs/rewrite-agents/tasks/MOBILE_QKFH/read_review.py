"""Extract a real AGY response without inventing broker acknowledgements."""
import json
import sys
from pathlib import Path

path = Path(__file__).resolve().parent / sys.argv[1]
events = [json.loads(line) for line in path.read_text(encoding='utf-8').splitlines() if line.startswith('{')]
results = [event['result']['response'] for event in events if event.get('event') == 'result' and event.get('result', {}).get('response')]
text = results[-1] if results else ''.join(event.get('step_update', {}).get('text_delta', '') for event in events)
if len(sys.argv) > 2:
    path.with_name(sys.argv[2]).write_text(text, encoding='utf-8')
print(text)
