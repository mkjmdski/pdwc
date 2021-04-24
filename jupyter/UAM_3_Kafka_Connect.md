### Runbook kafka stack + kafka connect
1. uruchom stack
    ```
    docker-compose -f docker-compose.yml up
    ```

2. Sprawdz jakie sa topiki na Kafce
    ```
   ./kafka-topics.sh --bootstrap-server localhost:9092 --list
   ```
   
3. Stworz nowy topik : test-topic
    ```
    ./kafka-topics.sh --bootstrap-server localhost:9092 --topic json.test.topic --create --partitions 3 --replication-factor
   ```
   
4. Połącz się producerem do Kafki na topik test-topic 
    ```
    ./kafka-console-producer.sh --broker-list localhost:9092 --topic json.test.topic
   ```
  
5. Połącz się z Kafką na json.test-topic 
    ```
   ./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic json.test.topic --from-beginning --property print.timestamp=true --from-beginning --property print.key=true 
   ```
   
6. Deploy connectors

   Najpierw simple connector - wyślij na http://localhost:8083/connectors/ (POST method) definicję UAM_3_sink_connector_simple.json np. z Postmana 


   Teraz napisz kilka wiadomości i poczekaj aż zrzuci do Minio

7. `docker-compose logs minio -f` 
   `docker-compose ps`
   



   
   