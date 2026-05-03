content = open(r'D:\02-Projects\01-Sparknote\backend\tests\test_api.py', 'r', encoding='utf-8-sig').read()
import re
# Check for malformed closing docstrings
for m in re.finditer(r'\.""\n    headers', content):
    start = max(0, m.start() - 80)
    end = min(len(content), m.end() + 20)
    print(repr(content[start:end]))
    print('---')
