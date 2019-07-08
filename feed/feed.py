import sys
import os
import subprocess
from math import exp, floor
from time import strftime
from Adafruit_IO import MQTTClient
from dotenv import load_dotenv
load_dotenv()


def convert_lux(v):
    return floor(80 - 3.24 * exp(-0.00938 * float(v)))

def format_entry(payload):
    data = payload.split(',')
    degreesF = data[2]
    humidity = data[3]
    light = convert_lux(data[4])
    now = strftime('%d %b, %Y %H:%m')
    out = '{}\n'.format(now)
    out += 'from 34.073960,-118.454797\n'
    out += 'Ambient Temp: {} F\n'.format(degreesF)
    out += 'Relative Humidity: {}%\n'.format(humidity)
    out += 'Brightness: {} lux\n'.format(light)
    return out
    

def log(str):
    print(str);
    to_print = str + '\n \n \n'
    print_cmd = ['lp', '-d', 'ZJ-58', '-o', 'raw']
    proc = subprocess.Popen(print_cmd, stdin=subprocess.PIPE)
    proc.stdin.write(to_print.encode('ASCII'))
    proc.communicate()
    proc.wait()

def connected(client):
    log('Connected')
    client.subscribe(os.getenv('FEED_ID'))

def disconnected(client):
    log('Disconnected')
    sys.exit(1)

def message(client, feed_id, payload):
    log(format_entry(payload))

client = MQTTClient(os.getenv('IO_USERNAME'), os.getenv('IO_KEY'))

client.on_connect = connected
client.on_disconnect = disconnected
client.on_message = message
client.connect()
client.loop_blocking()


