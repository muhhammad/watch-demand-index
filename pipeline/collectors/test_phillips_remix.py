import requests
import re
import json

url = "https://www.phillips.com/detail/rolex/222472"

headers = {
    "user-agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_0) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}

html = requests.get(url, headers=headers).text

# extract remix context
match = re.search(r'window\.__remixContext\s*=\s*({.*?});', html)

if not match:
    print("No remix context found")
    exit()

data = json.loads(match.group(1))

print(json.dumps(data, indent=2)[:2000])