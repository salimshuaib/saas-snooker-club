import re

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("eDateInput.min = --;", "eDateInput.min = ${yyyy}--;")
content = content.replace("eDateInput.value = --;", "eDateInput.value = ${yyyy}--;")

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'w', encoding='utf-8') as f:
    f.write(content)
