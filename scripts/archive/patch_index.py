import re

with open('C:/Users/Shuai/Desktop/booking_website/index.html', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''<!-- Step 4: Details -->
            <section class="mb-10">
                <div class="section-header">
                    <span class="step-circle">4</span>
                    <h2 class="text-xl font-semibold text-white">Your Details</h2>
                </div>
                <div class="grid md:grid-cols-2 gap-6">
                    <div>
                        <label class="block text-sm font-medium text-slate-400 mb-2">Full Name <span class="text-red-400">*</span></label>
                        <input type="text" id="customerName" class="w-full px-4 py-3 rounded-xl border-slate-700 shadow-inner" placeholder="E.g., Rahul Sharma" required>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-slate-400 mb-2">Phone Number <span class="text-red-400">*</span></label>
                        <div class="flex">
                            <span class="inline-flex items-center px-4 rounded-l-xl border border-r-0 border-slate-700 bg-slate-800 text-slate-400 font-semibold shadow-inner">+91</span>
                            <input type="tel" id="customerPhone" maxlength="10" class="w-full px-4 py-3 rounded-r-xl border-slate-700 shadow-inner flex-1 bg-slate-900 focus:outline-none focus:ring-1 focus:ring-indigo-500" placeholder="9876543210" required>
                        </div>
                    </div>
                </div>
            </section>'''

# Using regex to replace the section.
content = re.sub(r'<!-- Step 4: Details -->\s*<section class="mb-10">.*?</section>', replacement, content, flags=re.DOTALL)

with open('C:/Users/Shuai/Desktop/booking_website/index.html', 'w', encoding='utf-8') as f:
    f.write(content)
