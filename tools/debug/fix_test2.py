import re
content = open(r'D:\02-Projects\01-Sparknote\backend\tests\test_api.py', 'r', encoding='utf-8-sig').read()
print('Before - opening issues:', content.count('""NOTE-10'))

# Fix all malformed opening docstrings (""" became "")
content = content.replace('""NOTE-10:', '"""NOTE-10:')

# Fix all malformed closing docstrings (""" became "")
# Pattern: a description ending with ."" followed by newline + spaces + headers
# These are docstrings that should end with """
content = re.sub(r'(\w+)("")\n(\s+headers =)', r'\1"""\n\3', content)
# Also fix standalone malformed ends
content = re.sub(r'\.(\w+)("")\n(\s+\w+ =)', lambda m: m.group(1) + '.' + '"""' + '\n' + m.group(3), content)

# Actually let me just replace all remaining ."" patterns followed by newlines that look like docstring ends
# Find ."" at end of lines followed by lines starting with spaces+headers or assert
lines = content.split('\n')
fixed_lines = []
for i, line in enumerate(lines):
    if i < len(lines) - 1:
        next_line = lines[i+1] if i+1 < len(lines) else ''
        # If this line ends with ."" and next line starts with spaces+headers or assert
        if re.match(r'.*\.\"\"$', line) and re.match(r'\s+(headers =|assert )', next_line):
            line = line[:-2] + '"""'
    fixed_lines.append(line)

content = '\n'.join(fixed_lines)
print('After - opening issues:', content.count('""NOTE-10'))
print('After - malformed ends:', content.count('.""\n    headers'))
open(r'D:\02-Projects\01-Sparknote\backend\tests\test_api.py', 'w', encoding='utf-8-sig').write(content)
print('Done')
