import json

found_content = None
max_len = 0

with open(r'C:\Users\Shuai\.gemini\antigravity\brain\dbb6d21c-f6a5-4029-bfd3-a12cdf8ef31b\.system_generated\logs\transcript_full.jsonl', 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if data.get('type') == 'GENERIC' and 'class _ManualGameSetupScreenState' in data.get('content', ''):
                content = data['content']
                if len(content) > max_len:
                    max_len = len(content)
                    found_content = content
        except:
            pass

if found_content:
    with open('extracted_saas.txt', 'w', encoding='utf-8') as f:
        f.write(found_content)
    print(f'Extracted {max_len} bytes')
else:
    print('Not found')
