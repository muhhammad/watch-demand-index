import requests

url = "https://www.phillips.com/detail/rolex/222472?_data=routes/detail.$brand.$id"

headers = {
    "User-Agent": "Mozilla/5.0",
    "Accept": "application/json",
    "X-Requested-With": "XMLHttpRequest",
    "X-Remix-Request": "yes",
    "Referer": "https://www.phillips.com/auction/CH080425"
}

response = requests.get(url, headers=headers)

print(response.status_code)
print(response.headers.get("content-type"))
print(response.text[:1000])