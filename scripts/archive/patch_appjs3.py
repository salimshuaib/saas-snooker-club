with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove eNotes definition
content = content.replace("const eNotes = document.getElementById('notes');\n", "")

# Remove notes from the newBooking object
content = content.replace("notes: eNotes.value.trim(),", 'notes: "",')
content = content.replace("customerPhone: eCustomerPhone.value.trim(),", 'customerPhone: "+91 " + eCustomerPhone.value.trim(),')

old_validate = '''function validateForm() {
    const isReady = selectedTableId && selectedSlot && eCustomerName.value.trim() && eCustomerPhone.value.trim();
    eSubmitBtn.disabled = !isReady;
}'''

new_validate = '''function validateForm() {
    // Only allow letters and spaces in Name
    eCustomerName.value = eCustomerName.value.replace(/[^a-zA-Z ]/g, '');
    
    // Only allow digits in Phone
    eCustomerPhone.value = eCustomerPhone.value.replace(/[^0-9]/g, '');

    const isNameValid = eCustomerName.value.trim().length > 0;
    const isPhoneValid = eCustomerPhone.value.trim().length === 10;
    
    const isReady = selectedTableId && selectedSlot && isNameValid && isPhoneValid;
    eSubmitBtn.disabled = !isReady;
}'''

content = content.replace(old_validate, new_validate)

with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'w', encoding='utf-8') as f:
    f.write(content)
