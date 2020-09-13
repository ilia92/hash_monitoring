#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

workers_down_file="$DIR/.workers_down"
hash_checker_res_file="$DIR/cache.txt"

hash_checker_res=`cat $hash_checker_res_file | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | sed -n '/============================START===========================/,/=============================END============================/p' | grep -v 'START\|END'`

api_key=`cat $DIR/.api_key`
counter_trsh=5

workers_down_content=`cat "$workers_down_file"`

# Check for down workers
for i in `seq 1 $(($(printf "$hash_checker_res" | wc -l)))`;
do

w_line=`printf "$hash_checker_res" | sed "$i!d"`
w_down_name=`printf "$w_line" | awk {'print $1'}`
w_down_notified_count=`printf "$workers_down_content" | grep "$w_down_name" | awk {'print $2'}`

#printf "\nread: $w_down_name\t$w_down_notified_count\n"

if ! [[ "$w_down_notified_count" ]]; then
w_down_notified_count=0
echo "$w_down_name 1" >> $workers_down_file

message_new="${message_new}NEW worker down  : ${w_line}\n"
elif [ $(($w_down_notified_count+1)) -le $counter_trsh ]; then

w_down_notified_count=$(($w_down_notified_count+1))
sed -i "/${w_down_name}/c${w_down_name}\t$(($w_down_notified_count))" $workers_down_file

message_still="${message_still}Worker STILL down: ${w_line}\n"
fi
#printf "\n"
done
# END Check for new workers down

#printf "==================================\n"
#printf "$message"

# Check if miners gone UP
for j in `seq 1 $(($(printf "$workers_down_content" | wc -l)))`;
do
#printf "bla $j\n"
w_potentially_down=`printf "$workers_down_content" | sed "$j!d" | awk {'print $1'}`
if_gone_up=`printf "$hash_checker_res" | grep "$w_potentially_down"`

if ! [[ $if_gone_up ]]; then
message_up="${message_up}Worker gone UP: $w_potentially_down\n"
sed -i -n "/${w_potentially_down}/!p" $workers_down_file
fi

done
# END Check if miners gone UP

#message="${message_new}${message_still}${message_up}"

if [[ $message_new ]] || [[ $message_still ]] || [[ $message_up ]]; then

if [[ $message_new ]] && [[ $message_still ]]; then
message_new="$message_new\n"
fi

if [[ $message_new ]] || [[ $message_still ]]; then
message_head=`cat "$hash_checker_res_file" | head -4`
message_tail=`cat "$hash_checker_res_file" | tail -3`
message=`printf "${message_head}\n${message_new}${message_still}\n${message_tail}\n"`
fi

message=`printf "${message}\n${message_up}"`
#send message in this case
printf "Message:\n$message\n"

else
printf "Empty message!\n"
fi



#printf "file:\n"
#cat $workers_down_file