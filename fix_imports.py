with open('lib/features/games/presentation/widgets/player_split_payment_sheet.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('package:saas_snooker_club/', 'package:snooker_club/')

with open('lib/features/games/presentation/widgets/player_split_payment_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(code)
