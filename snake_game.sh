#!/bin/bash
hide_cursor="\033[?25l"
show_cursor="\033[?25h"
width=60
height=30
# snake_color="180;217;217"
# border_color="79;156;156"
# score_color="250;250;0"
snake_length=3
score="0"
snake_path=("15,30" "15,31" "15,32")
b_coin_pos=""
bomb_pos=""
b1=0
b2=0
bomb1=0
bomb2=0
speed=0.01
pid=$$
trap end EXIT
trap end SIGINT
state="true"
direction="left"
function variable_init(){
	echo "true" > snake_game_state
	echo "up" > snake_game_direction
}
function init(){
	border=""
	for ((i=0;i<($width + 2);i++))
	do
		border=$border" "
	done

	for ((i=0;i<${height};i++))
	do
		for ((j=0;j<${width};j++))
		do
			eval "canvas$i[$j]=' '"
		done
	done
}
function set_snake_path(){

	for ((i=0;i<$snake_length;i++))
	do
		data=${snake_path[$i]//,/ }
		k=0
		cmp=()
		for j in ${data[@]}
		do
			cmp[$k]=$j
			k=`expr $k + 1`
		done
		eval "canvas${cmp[0]}[${cmp[1]}]='\e[48;2;180;217;217m \e[0m'"
	done
}

function draw(){
	# border
	echo -e "\e[48;2;79;156;156m${border}\e[0m"

	for ((i=0;i<${height};i++))
	do
		line=""
		for ((j=0;j<${width};j++))
		do
			eval value=\${canvas${i}[$j]}

			line=$line$value
		done
		echo -e "\e[48;2;79;156;156m \e[0m${line}\e[48;2;79;156;156m \e[0m"
	done
	echo -e "\e[48;2;79;156;156m${border}\e[0m"
}

function move(){
	# tail
	tail_index=`expr $snake_length - 1`
	data=${snake_path[${tail_index}]//,/ }
	k=0
	cmp=()
	for j in ${data[@]}
	do
		cmp[$k]=$j
		k=`expr $k + 1`
	done
	eval "canvas${cmp[0]}[${cmp[1]}]=' '"
	for ((i=`expr $snake_length - 1`;i>0;i--))
	do
		snake_path[$i]=${snake_path[`expr $i - 1`]}
	done
	data=${snake_path[0]//,/ }
	k=0
	cmp=()
	for j in ${data[@]}
	do
		cmp[$k]=$j
		k=`expr $k + 1`
	done
	direction=`cat snake_game_direction`
	if [ $direction == "up" ] # up
	then
		cmp[0]=`expr ${cmp[0]} - 1`
	elif [ $direction == "down" ] # down
	then
		cmp[0]=`expr ${cmp[0]} + 1`
	elif [ $direction == "left" ] # left
	then
		cmp[1]=`expr ${cmp[1]} - 1`
	else # right
		cmp[1]=`expr ${cmp[1]} + 1`
	fi
	snake_path[0]=${cmp[0]}","${cmp[1]}
	eval "canvas${cmp[0]}[${cmp[1]}]='\e[48;2;180;217;217m \e[0m'"
}

function check(){
	# check edge
	target=${snake_path[0]}
	data=${snake_path[0]//,/ }
	k=0
	cmp=()
	for j in ${data[@]}
	do
		cmp[$k]=$j
		k=`expr $k + 1`
	done

	if [ ${cmp[0]} == -1 ] || [ ${cmp[0]} == `expr $height` ]
	then
		echo "false" > snake_game_state
		# echo "game over!"
		end
	elif [ ${cmp[1]} == -1 ] || [ ${cmp[1]} == `expr $width` ]
	then
		echo "false" > snake_game_state
		# echo "game over!"
		end
	fi
	#touch self
	for ((i=1;i<$snake_length;i++))
	do
		target2=${snake_path[$i]}
		if [ $target == $target2 ]
		then
			echo "false" > snake_game_state
			end

		fi
	done

	#touch ⌀
	snake_head=${snake_path[0]}
	if [ $snake_head == $bomb_pos ]
	then
		echo "false" > snake_game_state
		end

	fi
	#get b coin
	snake_head=${snake_path[0]}
	if [ $snake_head == $b_coin_pos ]
	then
		eval "canvas${bomb1}[${bomb2}]='\e[38;2;250;0;0m \e[0m'"
		score=`expr $score + 1`
		add_snake_length
		generate_bomb
		generate_b_coin

	fi
}

function add_snake_length(){
	tail_index=`expr $snake_length - 1`
	tail_index2=`expr $tail_index - 1`
	# get tail elements
	data=${snake_path[${tail_index}]//,/ }
	k=0
	cmp=()
	for j in ${data[@]}
	do
		cmp[$k]=$j
		k=`expr $k + 1`
	done
	# get tail2 elements
	data2=${snake_path[${tail_index2}]//,/ }
	k=0
	cmp2=()
	for j in ${data[@]}
	do
		cmp2[$k]=$j
		k=`expr $k + 1`
	done
	# get delta
	delta1=`expr ${cmp2[0]} - ${cmp[0]}`
	delta2=`expr ${cmp2[1]} - ${cmp[1]}`
	new_index1=`expr ${cmp[0]} + $delta1`
	new_index2=`expr ${cmp[1]} + $delta2`
	# add to snake path
	snake_path[$snake_length]=$new_index1","$new_index2
	snake_length=`expr $snake_length + 1`
}
function snake_game(){
	stty -echo
	clear
	printf "\033[s"
	printf $hide_cursor
	init
	set_snake_path
	generate_bomb
	generate_b_coin
	eval "canvas${b1}[${b2}]='\e[38;2;250;250;0mⒷ\e[0m'"
	eval "canvas${bomb1}[${bomb2}]='\e[38;2;250;0;0m⌀\e[0m'"
	draw
	echo -e "\e[38;2;250;250;0mget \e[38;2;255;0;0m${score}\e[38;2;250;250;0m ฿ coins\e[0m"
	move
	sleep ${speed}
	state=`cat snake_game_state`
	direction=`cat snake_game_direction`
	while [ $state == "true" ]
	do
		# Delete the last two lines
		printf "\033[32K"
		# Restore the cursor position
		printf "\033[u"

		eval "canvas${b1}[${b2}]='\e[38;2;250;250;0mⒷ\e[0m'"
		eval "canvas${bomb1}[${bomb2}]='\e[38;2;250;0;0m⌀\e[0m'"
		draw
		echo -e "\e[38;2;250;250;0mget \e[38;2;255;0;0m${score}\e[38;2;250;250;0m ฿ coins\e[0m"
		move
		check
		sleep $speed
	done &
}
function end(){
	kill -9 $pid
	rm -f snake_game_state snake_game_direction
	printf $show_cursor
	exit 0
}
function button_listener(){
	while [ $state == "true" ]
	do
		read -s -n 1 key
		if [ $key == "w" ] || [ $key == "W" ]
		then
			echo "up" > "snake_game_direction"
		elif [ $key == "s" ] || [ $key == "S" ]
		then
			echo "down" > "snake_game_direction"
		elif [ $key == "a" ] || [ $key == "A" ]
		then
			echo "left" > "snake_game_direction"
		elif [ $key == "d" ] || [ $key == "D" ]
		then
			echo "right" > "snake_game_direction"

		fi
		state=`cat snake_game_state`
		direction=`cat snake_game_direction`
		sleep $speed
	done
}
function generate_b_coin(){
	h=`expr $height - 2`
	w=`expr $width - 2`
	b1=$(($RANDOM%${h}))
	b2=$(($RANDOM%${w}))
	b_coin_pos=$b1","$b2
}
#💣
function generate_bomb(){
	h=`expr $height - 2`
	w=`expr $width - 2`
	bomb1=$(($RANDOM%${h}))
	bomb2=$(($RANDOM%${w}))
	bomb_pos=$bomb1","$bomb2
}
variable_init
snake_game
button_listener
end