import requests
import pandas as pd

url = "https://opendata.aemet.es/opendata/api/valores/climatologicos/inventarioestaciones/todasestaciones/"

querystring = {"api_key":"<HERE API KEY>"}

headers = {
    'cache-control': "no-cache"
    }

response = requests.request("GET", url, headers=headers, params=querystring)

my_response_json = response.json()

url = my_response_json['datos']
response = requests.request('GET', url, headers=headers, params=querystring)
my_response_json = response.json()

df = pd.DataFrame(my_response_json)
df.info()
df.head()