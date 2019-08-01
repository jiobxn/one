#!/usr/bin/python3
# yum -y install python36-setuptools
# easy_install-3.6 pip
# pip install kafka kafka-python

from kafka import KafkaProducer
from kafka import KafkaConsumer

#Producer
producer = KafkaProducer(bootstrap_servers='127.0.0.1:9092')
future = producer.send('TopicName', b'hello_world')
result = future.get(timeout= 10)
#print(result)

#Consumer
consumer = KafkaConsumer('TopicName', group_id='GroupID', bootstrap_servers=['127.0.0.1:9092'])
for msg in consumer:
    print(msg)
