import requests

address = 'http://localhost:5000/'

# Send GET requests
for i in range(20):
    response = requests.get(address)
    print(response.content)

# Send POST requests
for i in range(20):
    response = requests.post(address)
    print(response.content)
