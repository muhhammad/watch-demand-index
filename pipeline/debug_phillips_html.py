import requests

URL = "https://www.phillips.com/auction/CH080425"

response = requests.get(URL)
response.raise_for_status()

with open("phillips_debug.html", "w", encoding="utf-8") as f:
    f.write(response.text)

print("Saved HTML to phillips_debug.html")