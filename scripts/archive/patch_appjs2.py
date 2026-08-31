import re

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove eNotes definition
content = re.sub(r'const eNotes = document\.getElementById\(\'notes\'\);\n', '', content)

# Remove notes from the newBooking object
content = re.sub(r'notes: eNotes\.value\.trim\(\),\n', 'notes: "",\n', content)

# Update validateForm to enforce 10 digits
validate_replacement = '''function validateForm() {
    // Only allow letters and spaces in Name
    eCustomerName.value = eCustomerName.value.replace(/[^a-zA-Z\\s]/g, '');
    
    // Only allow digits in Phone
    eCustomerPhone.value = eCustomerPhone.value.replace(/[^0-9]/g, '');

    const isNameValid = eCustomerName.value.trim().length > 0;
    const isPhoneValid = eCustomerPhone.value.trim().length === 10;
    
    const isReady = selectedTableId && selectedSlot && isNameValid && isPhoneValid;
    eSubmitBtn.disabled = !isReady;
}'''

content = re.sub(r'function validateForm\(\) \{[\s\S]*?eSubmitBtn\.disabled = \!isReady;\n\}', validate_replacement, content)

# Add +91 to customerPhone inside submitBooking
content = re.sub(r'customerPhone: eCustomerPhone\.value\.trim\(\),', 'customerPhone: "+91 " + eCustomerPhone.value.trim(),', content)

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'w', encoding='utf-8') as f:
    f.write(content)
