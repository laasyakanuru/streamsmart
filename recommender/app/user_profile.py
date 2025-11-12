#This file simply keeps track of what each user has watched

import json
import os
import pandas as pd

USER_HISTORY_FILE = "data/user_history.json"

def load_user_history():
    if not os.path.exists(USER_HISTORY_FILE):
        with open(USER_HISTORY_FILE, "w") as f:
            json.dump({}, f)
    with open(USER_HISTORY_FILE, "r") as f:
        return json.load(f)

def save_user_history(history):
    with open(USER_HISTORY_FILE, "w") as f:
        json.dump(history, f, indent=2)

def add_to_history(user_id, show_title):
    history = load_user_history()
    user_data = history.get(user_id, [])
    if show_title not in user_data:
        user_data.append(show_title)
        history[user_id] = user_data
        save_user_history(history)

def get_user_history(user_id):
    history = load_user_history()
    return history.get(user_id, [])
