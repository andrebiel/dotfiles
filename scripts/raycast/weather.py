#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Weather
# @raycast.mode inline
# @raycast.refreshTime 1h

# Optional parameters:
# @raycast.icon ??

# Documentation:
# @raycast.description The Weather in Uelzen
# @raycast.author Andre Biel
# @raycast.authorURL https://github.com/karllson

import requests
import os
from dotenv import load_dotenv

load_dotenv()

TOKEN = os.getenv('WEATHER_API_KEY')
URL = "http://api.openweathermap.org/data/2.5/weather?" \
    "q={}&appid={}&units=metric"


class Weather:
    def __init__(self, zip):
        self.zip = zip

    def getWeather(self):
        response = requests.get(URL.format(self.zip, TOKEN)).json()

        return response


result = Weather('29525').getWeather()

print("{:.2f} C ({})".format(result['main']['temp'],
                             result['weather'][0]['description']))
