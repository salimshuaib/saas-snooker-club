import json
import re

transcript_path = r'C:\Users\Shuai\.gemini\antigravity\brain\12ede756-3f23-4cbd-b5c0-c5bff2767e42\.system_generated\logs\transcript_full.jsonl'
full_file = ''

with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        if 'class _MergeCustomersDialog extends ConsumerStatefulWidget {' in line:
            # Try to grab the exact literal string.
            match = re.search(r'class _MergeCustomersDialog extends ConsumerStatefulWidget \{.*', line)
            if match:
                full_file = match.group(0)
                # It's inside a JSON string. We must parse the JSON object.
                try:
                    obj = json.loads(line)
                    if 'tool_calls' in obj:
                        pass
                except Exception as e:
                    pass

# Let's do it properly by parsing each JSON line
with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if 'tool_responses' in data:
                for resp in data['tool_responses']:
                    if 'output' in resp:
                        output = resp['output']
                        if 'class _MergeCustomersDialog extends ConsumerStatefulWidget {' in output:
                            full_file = output
        except Exception:
            pass

if full_file:
    parts = full_file.split('class _MergeCustomersDialog extends ConsumerStatefulWidget {')
    if len(parts) > 1:
        tail = 'class _MergeCustomersDialog extends ConsumerStatefulWidget {' + parts[1]
        
        # Clean up any generic text at the end
        if 'The above content shows the entire, complete file contents' in tail:
            tail = tail.split('The above content shows the entire')[0]
        if 'Please note that the above snippet only shows the MODIFIED lines' in tail:
            tail = tail.split('Please note that the above snippet')[0]
            
        # Write back to file
        with open('lib/features/credit/presentation/screens/credit_screen.dart', 'a', encoding='utf-8') as f:
            f.write('\n\n' + tail)
        print('Restored tail')
    else:
        print('Could not find split')
else:
    print('Could not find full_file')
