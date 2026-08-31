content = '''const firebaseConfig = {
    apiKey: 'AIzaSyAiEO1peZc3AnSVAB1N6-ZlvEi966pHNMo',
    appId: '1:476933292121:web:3bff354476104bcd36f148',
    messagingSenderId: '476933292121',
    projectId: 'saas-snooker-club',
    authDomain: 'saas-snooker-club.firebaseapp.com',
    storageBucket: 'saas-snooker-club.firebasestorage.app',
    measurementId: 'G-24KNED8T96',
};

firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

// State
let clubId = null;
let tables = [];
let bookingsForDate = [];
let selectedTableId = null;
let selectedSlot = null;

// DOM Elements
const eClubName = document.getElementById('clubName');
const eClubLogo = document.getElementById('clubLogoContainer');
const eTablesGrid = document.getElementById('tablesGrid');
const eDateInput = document.getElementById('bookingDate');
const eTimeSlotsGrid = document.getElementById('timeSlotsGrid');
const eTimeSlotsEmpty = document.getElementById('timeSlotsEmpty');
const eCustomerName = document.getElementById('customerName');
const eCustomerPhone = document.getElementById('customerPhone');
const eNotes = document.getElementById('notes');
const eSubmitBtn = document.getElementById('submitBtn');
const eSubmitLoader = document.getElementById('submitLoader');
const eAlert = document.getElementById('alertBanner');
const eBookingFlow = document.getElementById('bookingFlow');
const eSuccessScreen = document.getElementById('successScreen');

// Initialize
function init() {
    // Set min date to today
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    eDateInput.min = yyyy + '-' + mm + '-' + dd;
    eDateInput.value = yyyy + '-' + mm + '-' + dd;
    
    // Get club ID from URL
    const urlParams = new URLSearchParams(window.location.search);
    clubId = urlParams.get('club');
    
    if (!clubId) {
        if(window.showError) { window.showError("No club specified in URL. Please use a valid booking link."); }
        eBookingFlow.style.display = 'none';
        return;
    }
    
    loadClubInfo();
    loadTables();
    
    // Listeners
    eDateInput.addEventListener('change', refreshSlots);
    eCustomerName.addEventListener('input', validateForm);
    eCustomerPhone.addEventListener('input', validateForm);
    eSubmitBtn.addEventListener('click', submitBooking);
}

async function loadClubInfo() {
    try {
        const doc = await db.collection('clubs').doc(clubId).get();
        if (!doc.exists) {
            if(window.showError) window.showError("Club not found.");
            eBookingFlow.style.display = 'none';
            return;
        }
        const data = doc.data();
        eClubName.textContent = data.clubName || 'Snooker Club';
        eClubName.classList.remove('skeleton');
        
        // Force the local logo.png since the user requested their logo
        eClubLogo.innerHTML = '<img src="logo.png" class="w-full h-full object-cover bg-white p-1">';
        eClubLogo.classList.remove('skeleton');
        
        if (data.themeColor) {
            document.documentElement.style.setProperty('--primary', data.themeColor);
        }
    } catch (e) {
        console.error(e);
        if(window.showError) window.showError("Failed to load club info.");
    }
}

async function loadTables() {
    try {
        const snapshot = await db.collection('clubs').doc(clubId).collection('tables').get();
        tables = snapshot.docs.map(doc => Object.assign({ id: doc.id }, doc.data()));
        
        // Filter out disabled ones if any. For now show all.
        renderTables();
    } catch (e) {
        console.error(e);
        if(window.showError) window.showError("Failed to load tables.");
    }
}

function renderTables() {
    eTablesGrid.innerHTML = '';
    tables.forEach(table => {
        const div = document.createElement('div');
        div.className = 'table-card p-4 rounded-xl flex flex-col items-center justify-center text-center gap-2';
        div.innerHTML = '<div class="w-12 h-12 rounded-full bg-slate-800/80 flex items-center justify-center text-indigo-400 mb-1"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16"></path></svg></div><span class="font-bold text-slate-200">' + table.name + '</span><span class="text-xs text-indigo-300/70 uppercase tracking-widest font-semibold">' + table.type + '</span>';
        div.onclick = () => {
            document.querySelectorAll('.table-card').forEach(el => el.classList.remove('selected'));
            div.classList.add('selected');
            selectedTableId = table.id;
            refreshSlots();
        };
        eTablesGrid.appendChild(div);
    });
}

async function refreshSlots() {
    if (!selectedTableId || !eDateInput.value) {
        eTimeSlotsEmpty.style.display = 'block';
        eTimeSlotsGrid.innerHTML = '';
        validateForm();
        return;
    }
    
    eTimeSlotsEmpty.style.display = 'none';
    eTimeSlotsGrid.innerHTML = '<div class="col-span-full text-center text-slate-400 py-4 font-medium flex items-center justify-center gap-2"><div class="w-4 h-4 border-2 border-indigo-500/30 border-t-indigo-500 rounded-full animate-spin"></div> Loading availability...</div>';
    
    try {
        const parts = eDateInput.value.split('-');
        const year = parseInt(parts[0], 10);
        const month = parseInt(parts[1], 10) - 1;
        const day = parseInt(parts[2], 10);
        const startOfDay = new Date(year, month, day, 0, 0, 0);
        const endOfDay = new Date(year, month, day, 23, 59, 59);
        
        // Fetch bookings for the date
        const snapshot = await db.collection('clubs').doc(clubId).collection('bookings')
            .where('bookingDate', '>=', startOfDay)
            .where('bookingDate', '<=', endOfDay)
            .get();
            
        bookingsForDate = snapshot.docs.map(doc => doc.data());
        
        renderTimeSlots();
    } catch (e) {
        console.error(e);
        eTimeSlotsGrid.innerHTML = '<div class="col-span-full text-red-400 text-sm">Error checking availability</div>';
    }
}

function renderTimeSlots() {
    eTimeSlotsGrid.innerHTML = '';
    selectedSlot = null;
    
    // Default config (10 AM to 10 PM, 60 min slots)
    const startHour = 10;
    const endHour = 22;
    const slotDurationMin = 60;
    
    const parts = eDateInput.value.split('-');
    const year = parseInt(parts[0], 10);
    const month = parseInt(parts[1], 10) - 1;
    const day = parseInt(parts[2], 10);
    const selectedDate = new Date(year, month, day);
    
    // Filter bookings for the selected table only
    const tableBookings = bookingsForDate.filter(b => b.tableId === selectedTableId && (b.status === "pending" || b.status === "confirmed"));
    
    const now = new Date();
    
    for (let h = startHour; h < endHour; h++) {
        for (let m = 0; m < 60; m += slotDurationMin) {
            const slotStart = new Date(year, month, day, h, m, 0);
            const slotEnd = new Date(slotStart.getTime() + slotDurationMin * 60000);
            
            // Check if slot is in the past
            if (slotStart < now) continue;
            
            // Check overlaps
            let isOccupied = false;
            for (const b of tableBookings) {
                const bStart = b.startTime.toDate();
                const bEnd = b.endTime.toDate();
                if ((slotStart >= bStart && slotStart < bEnd) || (slotEnd > bStart && slotEnd <= bEnd)) {
                    isOccupied = true;
                    break;
                }
            }
            
            const btn = document.createElement('button');
            const hh = h % 12 || 12;
            const ampm = h < 12 ? 'AM' : 'PM';
            const mmstr = m < 10 ? '0'+m : m;
            const timeStr = hh + ':' + mmstr + ' ' + ampm;
            btn.textContent = timeStr;
            btn.className = 'slot-btn rounded-xl py-3 text-sm font-semibold shadow-sm tracking-wide';
            
            if (isOccupied) {
                btn.disabled = true;
                btn.classList.add('opacity-40', 'line-through');
            } else {
                btn.onclick = () => {
                    document.querySelectorAll('.slot-btn').forEach(el => el.classList.remove('selected'));
                    btn.classList.add('selected');
                    selectedSlot = { start: slotStart, end: slotEnd };
                    validateForm();
                };
            }
            
            eTimeSlotsGrid.appendChild(btn);
        }
    }
    
    if (eTimeSlotsGrid.children.length === 0) {
        eTimeSlotsGrid.innerHTML = '<div class="col-span-full text-center text-slate-400 py-4">No available slots for this date.</div>';
    }
    validateForm();
}

function validateForm() {
    const isReady = selectedTableId && selectedSlot && eCustomerName.value.trim() && eCustomerPhone.value.trim();
    eSubmitBtn.disabled = !isReady;
}

async function submitBooking() {
    if (eSubmitBtn.disabled) return;
    
    eSubmitBtn.disabled = true;
    eSubmitLoader.classList.remove('hidden');
    
    try {
        const table = tables.find(t => t.id === selectedTableId);
        
        const parts = eDateInput.value.split('-');
        const year = parseInt(parts[0], 10);
        const month = parseInt(parts[1], 10) - 1;
        const day = parseInt(parts[2], 10);
        const bookingDate = new Date(year, month, day, 0, 0, 0);
        
        const newBooking = {
            clubId: clubId,
            tableId: table.id,
            tableName: table.name,
            tableType: table.type,
            customerName: eCustomerName.value.trim(),
            customerPhone: eCustomerPhone.value.trim(),
            notes: eNotes.value.trim(),
            bookingDate: firebase.firestore.Timestamp.fromDate(bookingDate),
            startTime: firebase.firestore.Timestamp.fromDate(selectedSlot.start),
            endTime: firebase.firestore.Timestamp.fromDate(selectedSlot.end),
            status: 'pending',
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };
        
        await db.collection('clubs').doc(clubId).collection('bookings').add(newBooking);
        
        eBookingFlow.style.display = 'none';
        eSuccessScreen.style.display = 'flex';
        
    } catch (e) {
        console.error(e);
        if(window.showError) window.showError("Failed to submit booking. Please try again.");
        eSubmitBtn.disabled = false;
    } finally {
        eSubmitLoader.classList.add('hidden');
    }
}

// Start
init();
'''
with open('C:/Users/Shuai/Desktop/booking_website/app.js', 'w', encoding='utf-8') as f:
    f.write(content)
