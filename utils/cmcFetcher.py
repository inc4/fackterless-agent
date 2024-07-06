import requests

API_KEY = ''
URL = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/historical'

def get_btc_price_at_date(date):
    headers = {
        'Accepts': 'application/json',
        'X-CMC_PRO_API_KEY': API_KEY,
    }
    params = {
        'symbol': 'BTC',
        'time_start': date,
        'time_end': date,
        'interval': 'daily'
    }
    response = requests.get(URL, headers=headers, params=params)
    data = response.json()
    print(data)

