
from typing import Any, Text, Dict, List
from datetime import datetime, time
import json

from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher

ITEMS = "items"
OPEN = "open"
CLOSE = "close"
NAME = "name"
SUNDAY = "Sunday"
PREPARATION_TIME = "preparation_time"

from flask import Flask, request, jsonify
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher

def list_menu():
	with open('menu.json') as jsonFile:
		data = json.load(jsonFile)

		return data

def list_opening_hours():
	with open('opening_hours.json') as jsonFile:
		data = json.load(jsonFile)

		return data

class ActionTellTime(Action):

    def name(self) -> Text:
        return "action_show_time"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        dispatcher.utter_message(text=f"{datetime.now()}")

        return []


class ActionShowOpeningTime(Action):

    def name(self) -> Text:
        return "action_show_opening_time"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        opening_times = list_opening_hours()
        items = ""
        for day in opening_times[ITEMS]:
            open = opening_times[ITEMS][day][OPEN]
            close = opening_times[ITEMS][day][CLOSE]
            items += f"{day} from {open} to {close}\n"
        dispatcher.utter_message(text="Open at:")
        dispatcher.utter_message(text=items)


class ActionShowMenu(Action):

    def name(self) -> Text:
        return "action_menu_listing"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        menu = list_menu()
        items = ""
        for entry in menu[ITEMS]:
            items += entry[NAME] + "\n"
         
        dispatcher.utter_message(text=items)



class ActionOrderBooked(Action):

    def name(self) -> Text:
        return "action_order_booked"

    def is_time_between(self, begin_time, end_time) -> bool:
        check_time = datetime.now()

        if begin_time < end_time:
            return check_time >= begin_time and check_time <= end_time
        else:
            return check_time >= begin_time or check_time <= end_time

    def run(self, 
    dispatcher: CollectingDispatcher,
    tracker: Tracker,
    domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        now = datetime.now()
        day_of_now = now.strftime("%A")
        menu = list_opening_hours()
        items = menu[ITEMS]
        opened_at = time(items[day_of_now][OPEN], 0)
        closed_at = time(items[day_of_now][CLOSE], 0)
        time_now = time(now.hour, now.minute)

        if day_of_now == SUNDAY:
            dispatcher.utter_message(text="Unfortunately, it is closed on Sunday.")
        elif self.is_time_between(opened_at, closed_at):
            dispatcher.utter_message(text="The seat has been booked!")

class ActionValidateOrder(Action):

    def name(self) -> Text:
        return "action_validate_order"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        curr_dish = tracker.get_slot("meal_type")
        time_to_prepare = 0
        price = 0
        print(f"curr_dish: {curr_dish} type: {type(curr_dish)}")

        menu = list_menu()[ITEMS]
        print(menu)

        for item in menu:
            if(item['name'].lower() == curr_dish.lower()):
                time_to_prepare = item['preparation_time']
                price = item['price']

        dispatcher.utter_message(text=f"Will be ready in {time_to_prepare} minutes! Pay required {price}")