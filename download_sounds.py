import urllib.request
import os
import ssl

os.makedirs('assets/sounds', exist_ok=True)

success_url = 'https://assets.mixkit.co/active_storage/sfx/2013/2013-preview.mp3'
error_url = 'https://assets.mixkit.co/active_storage/sfx/2955/2955-preview.mp3'

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

try:
    with urllib.request.urlopen(success_url, context=ctx) as response, open('assets/sounds/success_beep.mp3', 'wb') as out_file:
        out_file.write(response.read())
    print("Success sound downloaded")
    
    with urllib.request.urlopen(error_url, context=ctx) as response, open('assets/sounds/error_buzzer.mp3', 'wb') as out_file:
        out_file.write(response.read())
    print("Error sound downloaded")
except Exception as e:
    print(f"Error downloading sounds: {e}")
