import os

def fix_ternary():
    path = 'lib/features/games/data/games_repository.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = content.replace(
        "customerId: newPaidBy != null ? session.playerIdentities?[newPaidBy] : null,", 
        "customerId: (newPaidBy != null && session.playerIdentities != null) ? session.playerIdentities![newPaidBy] : null,"
    )
    
    # Check for others
    content = content.replace(
        "customerId: session.playerIdentities?[customerName],", 
        "customerId: session.playerIdentities != null ? session.playerIdentities![customerName] : null,"
    )
    
    content = content.replace(
        "customerId: session.playerIdentities?[session.paidBy!],", 
        "customerId: session.playerIdentities != null ? session.playerIdentities![session.paidBy!] : null,"
    )
    
    content = content.replace(
        "customerId: session.playerIdentities?[player],", 
        "customerId: session.playerIdentities != null ? session.playerIdentities![player] : null,"
    )

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_ternary()
