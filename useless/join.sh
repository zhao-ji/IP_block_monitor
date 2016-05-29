join -1 2 -2 1 \
	<( LC_MESSAGES=C cat top-1m.csv | sed 's/,/ /g' | sort -k 2) \
	<( LC_MESSAGES=C join -1 3 -2 1 \
		<(LC_MESSAGES=C cat $DNS_RECORD | sort -k 3 -u) \
		<(cat $DIFF | sort) \
        | awk '{print $2, $3, $1}' | sort -k 1 \
	) | sort -k 2 -n | awk '{print $2, $1, $3, $4}' > $HOST_LOST
