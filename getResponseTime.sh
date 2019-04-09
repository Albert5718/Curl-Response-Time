#/bin/sh

times=100
#set -x

#Establish session and get cookie and CSRFTOKEN (stored cookie in cookie.txt)
CSRFTOKEN=$(curl -s -X POST "https://192.168.0.193/api/session?username=admin&password=admin" -H "X-CSRFTOKEN: null" --data "" --compressed --insecure -c ./cookie.txt | jq -r '.CSRFToken')
QSESSION=$(cat cookie.txt | awk '/QSESSIONID/ { for (x=1;x<=NF;x++) if ($x~"QSESSIONID") print $(x+1) }')

#You cna use '#' to mark the unwanted url in apis.txt
APIs=$(cat apis.txt | sed "/#/d")

#initilize first test result
for API in ${APIs[@]}
do
	echo $API >> result.txt
	curl -s -w "@curl-format.txt" -X GET https://192.168.0.193/api$API -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' -H "Cookie: QSESSIONID=$QSESSION;" -H "X-CSRFTOKEN: $CSRFTOKEN" --insecure -o /dev/null >> result.txt
done

#Do recycle for setting times and append data
for i in $(seq 2 $times);
do
	echo "$i%"
	for API in ${APIs[@]}
	do
		#For sed usage to backslash slash
		API=$(echo "$API" | sed 's/\//\\\//g')
		response_time=$(curl -s -w "@curl-format.txt" -X GET https://192.168.0.193/api$API -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' -H "Cookie: QSESSIONID=$QSESSION;" -H "X-CSRFTOKEN: $CSRFTOKEN" --insecure -o /dev/null | awk '{print $2}')
		#Append result
		sed -i "/$API$/ {n; s/$/,$response_time/}" result.txt
	done
done

#Add average
average=$(cat result.txt | sed -n "s/time_total: *//p" | awk -F ',' '{sum=0; for(i=1; i<=NF; i++) sum += $i; print sum / NF}')

index=1

for avg in ${average[@]}
do
	awk -i inplace "{print \$0} /time_total/{count++;if(count==$index){print \"average:\"\"$avg\"}}" result.txt
	index=$((index+1))
done
