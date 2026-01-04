import time
import msgpackrpc
import paho.mqtt.client as mqtt
from paho.mqtt.enums import CallbackAPIVersion

# --- Configuration ---
# Now we can use 'm4-proxy' because of extra_hosts!
M4_PROXY_HOST = "m4-proxy" 
M4_PROXY_PORT = 5001
MQTT_BROKER = "mosquitto"   
MQTT_TOPIC_WARM = "snake/warm/temp"
MQTT_TOPIC_COOL = "snake/cool/temp"

def get_rpc_value(method_name):
    """
    Creates a fresh connection for a single call.
    Reliability > Speed.
    """
    try:
        address = msgpackrpc.Address(M4_PROXY_HOST, M4_PROXY_PORT)
        client = msgpackrpc.Client(address, timeout=5)
        result = client.call(method_name)
        return result
    except Exception as e:
        print(f"RPC Fail [{method_name}]: {e}")
        return None

def main():
    # Setup MQTT
    mqtt_client = mqtt.Client(CallbackAPIVersion.VERSION1, "PythonBridge")
    
    print("Connecting to MQTT broker...")
    while True:
        try:
            mqtt_client.connect(MQTT_BROKER, 1883, 60)
            print("Connected to MQTT!")
            break
        except Exception as e:
            print(f"Waiting for Mosquitto: {e}")
            time.sleep(2)

    while True:
        # Fetch Warm Side
        warm = get_rpc_value('getWarmTemp')
        if warm is not None and warm != -999.0:
            mqtt_client.publish(MQTT_TOPIC_WARM, str(warm))
            print(f"Warm: {warm}")

        # Fetch Cool Side
        cool = get_rpc_value('getCoolTemp')
        if cool is not None and cool != -999.0:
            mqtt_client.publish(MQTT_TOPIC_COOL, str(cool))
            print(f"Cool: {cool}")

        time.sleep(5) 

if __name__ == "__main__":
    main()