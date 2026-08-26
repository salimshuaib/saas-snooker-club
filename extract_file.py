import json

found_content = None
max_len = 0

for transcript in [
    r"C:\Users\Shuai\.gemini\antigravity\brain\63dc6b26-4fe0-428d-9821-6c1f2da70485\.system_generated\logs\transcript_full.jsonl",
    r"C:\Users\Shuai\.gemini\antigravity\brain\76143814-e751-4837-b2cf-791d9f5047d4\.system_generated\logs\transcript_full.jsonl",
    r"C:\Users\Shuai\.gemini\antigravity\brain\c1a0ec7a-778e-4d1d-bdef-235d62c587e8\.system_generated\logs\transcript_full.jsonl"
]:
    with open(transcript, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                if data.get("type") == "GENERIC" and "class _ManualGameSetupScreenState" in data.get("content", ""):
                    content = data["content"]
                    if len(content) > max_len:
                        max_len = len(content)
                        found_content = content
            except:
                pass

if found_content:
    with open("extracted_manual_game_setup.txt", "w", encoding='utf-8') as f:
        f.write(found_content)
    print(f"Extracted {max_len} bytes")
else:
    print("Not found")
