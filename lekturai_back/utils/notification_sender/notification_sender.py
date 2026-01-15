import firebase_admin
from firebase_admin import credentials, messaging
import os

print("Current working directory:", os.getcwd())

# 1. Initialize the app with your service account
cred = credentials.Certificate("lektur-ai-firebase-adminsdk-fbsvc-d1de249ee0.json")
firebase_admin.initialize_app(cred)

def send_high_priority_message(target_token):
    # 2. Construct the message
    # Note: We use specific configs for Android and iOS (APNS)
    message = messaging.Message(
        token=target_token,
        notification=messaging.Notification(
            title="Matura Tuż Tuż!",
            body="Może przyszpącisz trochę nauki? Kibicujemy ci 💪"
        ),
        # Android specific high priority settings
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id="urgent_alerts" # Required for Android 8+
            )
        ),
        # iOS specific high priority settings
        apns=messaging.APNSConfig(
            headers={"apns-priority": "10"},
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    content_available=True # Wakes up the app in background
                )
            )
        )
    )

    # 3. Send the message
    try:
        response = messaging.send(message)
        print("Successfully sent message:", response)
    except Exception as e:
        print("Error sending message:", e)

# REPLACE THIS with a real device token from your app
user_token = "e04xhsGyThmvDAecaza7yG:APA91bF53a6VO4XK6Xb5eLNzg9H6Xbmy4Cs2ewSHfoj7Avz9Q-6bvSDY11K9uclwgS8IP-_2Qlb32QoAqXzAD8IWroH_Gjh2ogMhsJN0UrjnF-CCKQFvIDE" 

if __name__ == "__main__":
    send_high_priority_message(user_token)