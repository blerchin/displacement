#include <Arduino.h>
#include <Wire.h>

#include <Adafruit_FONA.h>
#include <Adafruit_MQTT.h>
#include <Adafruit_MQTT_FONA.h>
#include "DHT.h"

#include "credentials.h"


#define PIN_DHT A0
#define PIN_PHOTOCELL A1
#define PIN_FONA_RX 9
#define PIN_FONA_TX 8
#define PIN_FONA_RST 4
#define PIN_FONA_KEY 5

#define FONA_ENABLED 1

#define UPLOAD_INTERVAL 60000

#include <SoftwareSerial.h>
SoftwareSerial fonaSS = SoftwareSerial(PIN_FONA_TX, PIN_FONA_RX);
SoftwareSerial *fonaSerial = &fonaSS;
bool fonaOn = false; 

Adafruit_FONA fona = Adafruit_FONA(PIN_FONA_RST);
Adafruit_MQTT_FONA mqtt(&fona, AIO_SERVER, AIO_SERVERPORT, AIO_USERNAME, AIO_KEY);

Adafruit_MQTT_Publish feed = Adafruit_MQTT_Publish(&mqtt, AIO_USERNAME "/feeds/surrogate-sensors");

DHT *dht = new DHT(PIN_DHT, DHT22);


uint32_t lastUpload = millis();

uint16_t batterymV[10];
char humidity[10];
char degreesF[10];
char light[10];
char csvstring[256];


void readSensors() {
  itoa(analogRead(PIN_PHOTOCELL), light, 10);
  dtostrf(dht->readTemperature(true), 6, 2, degreesF);
  dtostrf(dht->readHumidity(), 6, 2, humidity);
  if(fonaOn) {
    fona.getBattVoltage(batterymV);
  }
}

void toggleFONA(bool turnOn) {
  if (turnOn != fonaOn) {
    digitalWrite(PIN_FONA_KEY, LOW);
    delay(2000);
    digitalWrite(PIN_FONA_KEY, HIGH);
    delay(3000);
    fonaOn = turnOn;
  }
}

bool startFONA() {
  #if FONA_ENABLED
  toggleFONA(true);
  fonaSerial->begin(4800);
  if(!fona.begin(*fonaSerial)) {
    Serial.println("Failed to communicate with FONA");
    return false;
  }
  #endif
}

bool connectMQTT() {
  int8_t ret;
  if (mqtt.connected()) {
    return true;
  }
  Serial.println("Connecting to MQTT...");
  while ((ret = mqtt.connect()) != 0) { // connect will return 0 for connected
    Serial.println(mqtt.connectErrorString(ret));
    Serial.println("Retrying MQTT connection in 5 seconds...");
    mqtt.disconnect();
    delay(5000);  // wait 5 seconds
  }
  Serial.println("MQTT connected");
  return true;
}

char* getSensorCSV() {
  snprintf(
    csvstring,
    256,
    "%lu,%d,%s,%s,%s",
    millis(),
    batterymV,
    degreesF,
    humidity,
    light
  );
  return csvstring;
}

void stopFONA() {
  #if FONA_ENABLED
  toggleFONA(false);
  #endif
}


void setup(void)
{
  //Watchdog.enable(60000);
  Serial.begin(9600);

  pinMode(PIN_FONA_KEY, OUTPUT);
  digitalWrite(PIN_FONA_KEY, HIGH);


  Serial.println("RUNNING");
}

void loop(void)
{
  //Watchdog.reset();
  Serial.println(millis() - lastUpload);
  delay(1000);

  if (millis() - lastUpload > UPLOAD_INTERVAL) {
    readSensors();
    Serial.println("DID READ SENSORS");
    #if FONA_ENABLED
      startFONA();
      Serial.println("FONA RUNNING");
      while(fona.getNetworkStatus() != 1) {
        delay(1000);
        Serial.println("waiting for network");
      }
      fona.enableGPRS(true);
      connectMQTT();
      feed.publish(getSensorCSV());
      delay(1000);
      stopFONA();
      Serial.println("FONA_STOPPED");
    #endif
    lastUpload = millis();
  }
}
