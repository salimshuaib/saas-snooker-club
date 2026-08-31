import re

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'eDateInput\.min = [^\n]+', 'eDateInput.min = ${yyyy}--;', content)
content = re.sub(r'eDateInput\.value = [^\n]+', 'eDateInput.value = ${yyyy}--;', content)
content = re.sub(r'const timeStr = slotStart\.toLocaleTimeString[^\n]+', 'const timeStr = slotStart.toLocaleTimeString([], {hour: \\'numeric\\', minute:\\'2-digit\\'});', content)

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'w', encoding='utf-8') as f:
    f.write(content)
