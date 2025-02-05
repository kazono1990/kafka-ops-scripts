# topic ops scripts
## increase-topic-replication-factor

This script increases existing kafka topic's replication factor.

### How to use
```bash
$  ./increase-replication-factor.sh --bootstrap-server localhost:19092 --topic test-topic --replica-list 1,2,3,4
```

**note:**
Please change `KAFKA_BIN_PATH` to your specific directory which binary located. 

### Example
```bash
$ ./kafka-topics.sh --list --bootstrap-server localhost:19092
test-topic


$ ./kafka-topics.sh --describe --bootstrap-server localhost:19092 --topic test-topic
Topic: test-topic	PartitionCount: 2	ReplicationFactor: 1	Configs: segment.bytes=1073741824
	Topic: test-topic	Partition: 0	Leader: 2	Replicas: 2	Isr: 2
	Topic: test-topic	Partition: 1	Leader: 1	Replicas: 1	Isr: 1


$ ./increase-replication-factor.sh --bootstrap-server localhost:19092 --topic test-topic --replica 1,2


$ ./kafka-topics.sh --describe --bootstrap-server localhost:19092 --topic test-topic
Topic: test-topic	PartitionCount: 2	ReplicationFactor: 2	Configs: segment.bytes=1073741824
	Topic: test-topic	Partition: 0	Leader: 2	Replicas: 2,1	Isr: 2,1
	Topic: test-topic	Partition: 1	Leader: 1	Replicas: 1,2	Isr: 1,2
```
