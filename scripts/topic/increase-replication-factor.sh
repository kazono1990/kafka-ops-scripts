#!/usr/bin/env bash

PARAMS=""
KAFKA_BIN_PATH="/opt/kafka/bin"

while (( "$#" )); do
  case "$1" in
    --bootstrap-server)
      BOOTSTRAP_SERVER=$2
      shift 2
      ;;
    --topic)
      TOPIC=$2
      shift 2
      ;;
    --replica)
      REPLICAS=$2
      shift 2
      ;;
    -h|--help)
      echo ""
      echo "Alter the replication factor for existing Kafka topics"
      echo ""
      echo "Usage: $0"
      echo "  --bootstrap-server <broker:9092>"
      echo "  --topic <topic name>"
      echo "  --replica <1,2,3,4>  # List of Broker IDs to locate the replica of topic"
      echo ""

      echo " Example:"
      echo " ./increase-replication-factor.sh --bootstrap-server localhost:19092 --topic test-topic --replica 1,2,3,4"
      exit 1
      ;;
    --)
      shift
      break
      ;;
    *)
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

if [ -n "$PARAMS" ]; then
  eval set -- "$PARAMS"
fi

if [ -z "$BOOTSTRAP_SERVER" ] || [ -z "$TOPIC" ] || [ -z "$REPLICAS" ] ; then
  exec $0 -h
  exit 1
fi

CMD="${KAFKA_BIN_PATH}/kafka-topics.sh --describe --bootstrap-server $BOOTSTRAP_SERVER "
if [ -n "$TOPIC" ]; then
  CMD="${CMD} --topic $TOPIC "
fi

echo "$( ${CMD} )" > topics.txt
UNIQUE_TOPICS=$(cat topics.txt | grep -E '^Topic: ' | awk '{print $2 }' | sort -u)

cat <<EOF > mapping.json
{"version":1,
 "partitions":[
EOF

row_count=0
for topic in ${UNIQUE_TOPICS}; do
  echo "Working on topic $topic..."
  while read r
  do
    partition=$(echo $r | awk '{print $4}')
    leader=$(echo $r | awk '{print $6}')

    replicas=$leader
    for t in $(echo $REPLICAS | tr ',' '\n'); do
      if [[ "$t" != "$leader" ]]; then
	replicas="${replicas},$t"
      fi
    done

    row_count=$(( $row_count + 1 ))
    if [[ $row_count -gt 1 ]]; then
      echo -n "    ," >> mapping.json
    else
      echo -n "     " >> mapping.json
    fi

    cat <<EOF >> mapping.json
{"topic":"$topic", "partition": $partition, "replicas":[$replicas] }
EOF

  done < <(cat topics.txt | awk -v topic=$topic '$2 == topic && $3 == "Partition:"')
done

cat <<EOF >> mapping.json
  ]
}
EOF


CMD="${KAFKA_BIN_PATH}/kafka-reassign-partitions.sh --bootstrap-server $BOOTSTRAP_SERVER --reassignment-json-file mapping.json "

${CMD} --execute | tee reassignment.log
${CMD} --verify
