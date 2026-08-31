import re

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("function init() {", "async function init() {")
content = content.replace("loadClubInfo();\n    loadTables();", "await loadClubInfo();\n    loadTables();")

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'w', encoding='utf-8') as f:
    f.write(content)
