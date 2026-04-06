import re

# Fix profile_page.dart: replace print( with debugPrint( and fix ___
path = 'lib/screens/profile_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace bare print( with debugPrint(
content = re.sub(r'\bprint\(', 'debugPrint(', content)

# Fix unnecessary triple underscores in errorBuilder lambdas: (_, __, ___) -> (_, __, _e)
content = content.replace('(_, __, ___)', '(_, __, _e)')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f'Fixed {path}')
