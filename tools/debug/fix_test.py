# Fix malformed docstrings
content = open(r'D:\02-Projects\01-Sparknote\backend\tests\test_api.py', 'r', encoding='utf-8-sig').read()
# Replace all malformed docstring starts (PowerShell heredoc issue: "" became "")
content = content.replace('""NOTE-10:', '"""NOTE-10:')
# Fix the malformed docstring end that became ""
content = content.replace('fallback note.""', 'fallback note."""')
open(r'D:\02-Projects\01-Sparknote\backend\tests\test_api.py', 'w', encoding='utf-8-sig').write(content)
print('Done. Remaining issues:', content.count('""NOTE-10:'))
