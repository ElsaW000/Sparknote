import re
content = open(r'D:\02-Projects\01-Sparknote\backend\tests\test_api.py', 'r', encoding='utf-8-sig').read()
for m in re.finditer(r'""NOTE-10', content):
    start = max(0, m.start() - 60)
    end = min(len(content), m.end() + 60)
    print(repr(content[start:end]))
    print('---')
