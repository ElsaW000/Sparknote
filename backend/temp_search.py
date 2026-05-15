content = open('main.py', 'r', encoding='utf-8').read()
import re

# UserCreate
m = re.search(r'class UserCreate\b[^\n]*\n(.*?)(?=\nclass [A-Z]|\Z)', content, re.S)
if m: print('UserCreate:', repr(m.group(0)[:200]))

# CaptchaChallenge
m = re.search(r'class CaptchaChallenge\b[^\n]*\n(.*?)(?=\nclass [A-Z]|\Z)', content, re.S)
if m: print('CaptchaChallenge:', repr(m.group(0)[:200]))

# Find the exact position of UserCreate to see full definition
idx = content.find('class UserCreate')
if idx >= 0:
    print('\nFull UserCreate context:')
    print(repr(content[idx:idx+300]))
