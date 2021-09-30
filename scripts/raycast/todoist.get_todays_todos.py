#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Todos for today
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon ??

# Documentation:
# @raycast.description All todos for today
# @raycast.author Andre Biel
# @raycast.authorURL https://github.com/karllson

import requests
from datetime import date
import os
from dotenv import load_dotenv

load_dotenv()

TOKEN = os.getenv('TODOIST_API_KEY')


def getTasks():
    result = requests.get("https://api.todoist.com/rest/v1/tasks",
                          headers={
                              "Authorization": "Bearer %s" % TOKEN
                          }).json()

    return result


tasks = getTasks()

for task in tasks:
    today = date.today()
    today_string = today.isoformat()

    if 'due' in task and today_string == task['due']['date']:
        print('* %s' % (task['content']))
