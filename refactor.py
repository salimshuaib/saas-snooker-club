import os
import re

def replace_in_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for pattern, repl in replacements:
        new_content = re.sub(pattern, repl, new_content)
        
    if content != new_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Updated {filepath}')

replacements = [
    # Bookings
    (r'BookingStatus\.pending', 'BookingStatus.unconfirmed'),
    (r'pending, confirmed, cancelled, completed', 'unconfirmed, confirmed, cancelled, completed'),
    (r'watchPendingBookings', 'watchUnconfirmedBookings'),
    (r'pendingBookingsCount', 'unconfirmedBookingsCount'),
    (r'PENDING REQUESTS', 'UNCONFIRMED REQUESTS'),
    
    # Credit/Khata
    (r'CreditTransactionStatus\.pending', 'CreditTransactionStatus.unpaid'),
    (r'pending, partiallyPaid, paid', 'unpaid, partiallyPaid, paid'),
    (r'totalPendingTransactions', 'totalUnpaidTransactions'),
    (r'pendingCount', 'unpaidCount'),
    (r'pendingPlayers', 'unpaidPlayers'),
    (r'pendingTransactionsProvider', 'unpaidTransactionsProvider'),
    (r'watchPendingTransactions', 'watchUnpaidTransactions'),
    
    # Games/Providers
    (r'pendingCreditsProvider', 'outstandingCreditsProvider'),
    (r'pendingCredits', 'outstandingCredits'),
    (r'Pending Credit', 'Outstanding Credit'),
    
    # UI Texts targeted
    (r""title:\s*'Pending'"", ""title: 'Unpaid'""),
    (r""return\s*'Pending'"", ""return 'Unconfirmed'""),
    (r""Text\(\s*'Pending'"", ""Text('Unpaid'""),
    (r""paymentStatus == 'pending'"", ""paymentStatus == 'Unpaid'""),
]

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            replace_in_file(os.path.join(root, file), replacements)

for root, _, files in os.walk('lib/l10n'):
    for file in files:
        if file.endswith('.arb'):
            replace_in_file(os.path.join(root, file), replacements)
