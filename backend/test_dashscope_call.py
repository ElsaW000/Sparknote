import requests

def main():
    r = requests.get('http://127.0.0.1:8000/debug/ai', params={'prompt': '你好'})
    print(r.status_code, r.text)

if __name__ == '__main__':
    main()
