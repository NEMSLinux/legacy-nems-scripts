#!/bin/bash
{
	#////////////////////////////////////
	# NEMS Cloudshell Display for ODROID
	#
	#////////////////////////////////////
	# Based on DietPi Cloudshell created by Daniel Knight / daniel.knight@dietpi.com / dietpi.com
	#
	#////////////////////////////////////
	#
	# Info:
	# - System Stats for Cloudshell (or monitor/terminal)
	#
	# Usage:
	# dietpi-cloudshell				= Config Menu
	# dietpi-cloudshell 1			= Run
	# dietpi-cloudshell 2			= Run + Skip intro
	#////////////////////////////////////

	#Force en_GB Locale for whole script. Prevents incorrect parsing with non-english locales.
	LANG=en_GB.UTF-8

	#Ensure we are in users home dir: https://github.com/Fourdee/DietPi/issues/905#issuecomment-298223705
	cd "$HOME"

	#Exit path for non-root logins.
	if (( $UID != 0 )); then

		/DietPi/dietpi/func/dietpi-notify 1 'Error: Root privileges required. Please run the command with "sudo"\n'
		exit

	fi

	#Grab Input (valid interger)
	INPUT=0
	if [[ $1 =~ ^-?[0-9]+$ ]]; then
		INPUT=$1
	fi

        # List of HW_MODEL are here: https://github.com/Fourdee/DietPi/blob/master/dietpi/dietpi-obtain_hw_model
	HW_MODEL=$(sed -n 1p /DietPi/dietpi/.hw_model)
	CPU_CORES=$(nproc --all)

	#Version
	DIETPI_CLOUDSHELL_VERSION=$(/home/pi/nems-scripts/info.sh nemsver)

	#/tmp/.* files used throughout this script.
	FP_TEMP="/tmp/dietpi-cloudshell"

	PROGRAM_NAME="DietPi-Cloudshell"

	BLANK_SCREEN_ACTIVE=0
	BLANK_SCREEN_AT_SPECIFIC_TIME_ENABLED=0
	BLANK_SCREEN_TIME_HOUR_START=0
	BLANK_SCREEN_TIME_HOUR_END=0

	#This will only work if dietpi-cloudshell was started by autostart (login script), as the setterm power options can only be applied when the command originates from the same terminal (no redirects).
	RUN_BLANK_SCREEN_AT_SPECIFIC_TIME(){

		local current_hour=$(date +%-H)

		#Turn screen off
		if (( ! $BLANK_SCREEN_ACTIVE )); then

			if (( $BLANK_SCREEN_TIME_HOUR_START == $current_hour )); then
				clear
				echo -e "\n\nScreen will be powered down in under 1 minute\n"
				setterm --blank 1 --powersave on &> /dev/tty1 #blank after 1 minute as force requires a poke to bring it back up.
				BLANK_SCREEN_ACTIVE=1
			fi

		#Turn screen on
		elif (( $BLANK_SCREEN_TIME_HOUR_END == $current_hour )); then
			setterm --blank poke &> /dev/tty1
			setterm --reset &> /dev/tty1
			setterm --blank 0 --powersave off &> /dev/tty1
			BLANK_SCREEN_ACTIVE=0

		fi

	}

	#BC does not allow for printing leading zeros.
	BC_ADD_LEADING_ZERO(){

		#$1 = string input
		local return_value=$1

		#BC - Add leading zero to start of .* string.
		# +0
		if [ "${return_value:0:1}" = "." ]; then
			return_value="0$return_value"

		# -0
		elif [ "${return_value:0:2}" = "-." ]; then
			return_value=$(echo -e "$return_value" | sed 's/^-./-0./')
		fi

		echo "$return_value"

	}

	#Converts a byte int to string, in human readable byte format.
	BYTE_PRINT_CONVERSION(){

		local return_value=0
		local decimal_count=1

		#$1=byte value

		# - KB
		if (( $1 < 1048576 )); then
			#return_value="$(( $1 / 1024 )) KB"
			return_value="$(echo "scale=$decimal_count; $1 / 1024" | bc -l ) KB"

		# - MB
		elif (( $1 < 1073741824 )); then
			#return_value="$(( $1 / 1024 / 1024 )) MB"
			return_value="$(echo "scale=$decimal_count; $1 / 1024 / 1024" | bc -l ) MB"

		# - GB
		else
			#return_value="$(( $1 / 1024 / 1024 / 1024 )) GB"
			return_value="$(echo "scale=$decimal_count; $1 / 1024 / 1024 / 1024" | bc -l ) GB"

		fi

		#BC - Add leading zero to start of .* string.
		return_value=$(BC_ADD_LEADING_ZERO "$return_value")

		echo "$return_value"

	}

	#Converts a byte int to string, in human readable bit format.
    # - for network data transmission rate (LAN, WLAN, ...)
	# - 1MB = 8Mbit | 1Mbit = 0.125MB
    BIT_PRINT_CONVERSION(){

		local return_value=0
		local decimal_count=1

		#$1=byte value

		# - Kbit
		if (( $1 < 1000000 )); then
				#return_value="$(( $1 * 8 / 1000 )) Kbit"
				return_value="$(echo "scale=$decimal_count; $1 * 8 / 1000" | bc -l) Kbit"

		# - MBit
		elif (( $1 < 1000000000 )); then
				#return_value="$(( $1 * 8 / 1000 / 1000 )) Mbit"
				return_value="$(echo "scale=$decimal_count; $1  * 8 / 1000 / 1000" | bc -l) Mbit"

		# - GBit
		else
				#return_value="$(( $1 * 8 / 1000 / 1000 / 1000 )) Gbit"
				return_value="$(echo "scale=$decimal_count; $1 * 8 / 1000 / 1000 / 1000" | bc -l) Gbit"

		fi

		#BC - Add leading zero to start of .* string.
		return_value=$(BC_ADD_LEADING_ZERO "$return_value")

		echo "$return_value"

    }

	#Apply fonts
	Enable_Term_Options(){

		# - Set large font 1st (480x320+)
		setfont /usr/share/consolefonts/Uni3-TerminusBold32x16

		# - set small font if insufficent number of lines (320x240)
		if (( $(tput lines) < 10 )); then

			setfont /usr/share/consolefonts/Uni3-TerminusBold24x12.psf

		fi

	}

	#/////////////////////////////////////////////////////////////////////////////////////
	# Colours
	#/////////////////////////////////////////////////////////////////////////////////////
	C_RESET="\e[0m"
	C_REVERSE="\e[7m"

	#C_BOLD makes normal text "brighter"
	C_BOLD="\e[1m"

	#Colour array
	#0 WHITE
	#1 RED
	#2 GREEN
	#3 YELLOW
	#4 BLUE
	#5 PURPLE
	#6 CYAN
	#7 TEST
	aCOLOUR=(
		"\e[39m"
		"\e[31m"
		"\e[32m"
		"\e[33m"
		"\e[34m"
		"\e[35m"
		"\e[36m"
		"\e[93m"
	)

	#user colour
	USER_COLOUR_INDEX=3

	C_PERCENT_GRAPH=0
	Percent_To_Graph(){

		#$1 = int/float 0-100
		#$C_PERCENT_GRAPH = return text

		#Convert to int
		local input_value=$(echo $1 | cut -d. -f1)

		#Cap input value
		if (( $input_value > 100 )); then
			input_value=100
		elif (( $input_value < 0 )); then
			input_value=0
		fi

		#Work out a percentage based graph
		#18 step split (18 / 100)
		if (( $input_value >= 95 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[1]}------WARNING-----$C_RESET]"
		elif (( $input_value >= 90 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[1]}-----------------$C_RESET-]"
		elif (( $input_value >= 88 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[1]}----------------$C_RESET--]"
		elif (( $input_value >= 82 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[1]}---------------$C_RESET---]"
		elif (( $input_value >= 76 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[3]}--------------$C_RESET----]"
		elif (( $input_value >= 70 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[3]}-------------$C_RESET-----]"
		elif (( $input_value >= 64 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[3]}------------$C_RESET------]"
		elif (( $input_value >= 56 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[3]}-----------$C_RESET-------]"
		elif (( $input_value >= 50 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[3]}----------$C_RESET--------]"
		elif (( $input_value >= 44 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[3]}---------$C_RESET---------]"
		elif (( $input_value >= 38 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[2]}--------$C_RESET----------]"
		elif (( $input_value >= 32 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[2]}-------$C_RESET-----------]"
		elif (( $input_value >= 26 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[2]}------$C_RESET------------]"
		elif (( $input_value >= 20 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[2]}-----$C_RESET-------------]"
		elif (( $input_value >= 15 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[2]}----$C_RESET--------------]"
		elif (( $input_value >= 10 )); then
			C_PERCENT_GRAPH=" $input_value% [$C_REVERSE${aCOLOUR[2]}---$C_RESET---------------]"
		elif (( $input_value >= 5 )); then
			C_PERCENT_GRAPH=" $input_value%  [$C_REVERSE${aCOLOUR[2]}--$C_RESET----------------]"
		else
			C_PERCENT_GRAPH=" $input_value%  [$C_REVERSE${aCOLOUR[2]}-$C_RESET-----------------]"
		fi

	}

	#/////////////////////////////////////////////////////////////////////////////////////
	# Obtain Stat Data
	#/////////////////////////////////////////////////////////////////////////////////////
	TEMPERATURE_CONVERSION_VALUE=0
	Obtain_Temperature_Conversion(){

		if (( $TEMPERATURE_OUTPUT_TYPE == 0 )); then
			TEMPERATURE_CONVERSION_VALUE=$(awk "BEGIN {printf \"%.0f\",$TEMPERATURE_CONVERSION_VALUE * 1.8 + 32"})
			TEMPERATURE_CONVERSION_VALUE+="'f"
		else
			TEMPERATURE_CONVERSION_VALUE+="'c"
		fi

	}

	DATE_TIME=0
	Obtain_DATE_TIME(){

		DATE_TIME=$(date +"%a %x - %R")

	}

	UPTIME=0
	Obtain_UPTIME(){

		local fSeconds=$(cat /proc/uptime | awk '{print $1}')

		local seconds=${fSeconds%.*}
		local minutes=0
		local hours=0
		local days=0

		while (( $seconds >= 60 )); do
			((minutes++))
			seconds=$(( $seconds - 60 ))
		done

		while (( $minutes >= 60 )); do
			((hours++))
			minutes=$(( $minutes - 60 ))
		done

		while (( $hours >= 24 )); do
			((days++))
			hours=$(( $hours - 24 ))
		done

		UPTIME="Uptime: $days Day, $hours Hour"

	}

	#CPU
	CPU_GOV=0
	CPU_TEMP=0
	C_CPUTEMP=0
	CPU_FREQ_1=0
	CPU_FREQ_2=0
	CPU_USAGE=0
	CPU_TOTALPROCESSES=0
	Obtain_CPU(){

		CPU_TOTALPROCESSES=$(( $(ps --ppid 2 -p 2 --deselect | wc -l) - 2 )) # - ps process and descriptions.
		CPU_GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
		CPU_TEMP=$(/DietPi/dietpi/dietpi-cpuinfo 1)

		if [[ $CPU_TEMP =~ ^-?[0-9]+$ ]]; then

			#Obtain colour for temps
			if (( $CPU_TEMP >= 65 )); then

				C_CPUTEMP=${aCOLOUR[1]}

			elif (( $CPU_TEMP >= 50 )); then

				C_CPUTEMP=${aCOLOUR[3]}

			elif (( $CPU_TEMP >= 35 )); then

				C_CPUTEMP=${aCOLOUR[2]}

			else

				C_CPUTEMP=${aCOLOUR[4]}

			fi

			#Set 'c or 'f output
			TEMPERATURE_CONVERSION_VALUE=$CPU_TEMP
			Obtain_Temperature_Conversion
			CPU_TEMP=$TEMPERATURE_CONVERSION_VALUE

		fi

		CPU_FREQ_1=$(( $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) / 1000 ))
		CPU_FREQ_2="N/A"

		#Unique additional freq readout for Odroid XU4 (octo, 2nd quad set)
		if (( $HW_MODEL == 11 )); then

			CPU_FREQ_2=$(( $(cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq) / 1000 ))

		fi

		CPU_USAGE=0
		FP_TEMP="/tmp/.cpu_usage"

		# PS (inaccurate)
		ps -axo %cpu | sed '1d' | sed 's/ //' > "$FP_TEMP"
		while read -r line
		do

			CPU_USAGE=$( echo "scale=1;$CPU_USAGE + $line" | bc -l )

		done < $FP_TEMP

		#ps returns usage of each core, so we devide the total by #n cores
		CPU_USAGE=$(echo "scale=0;$CPU_USAGE / $CPU_CORES" | bc -l )

		# TOP (accurate)
		# Fails to output in low screen res (https://github.com/Fourdee/DietPi/issues/203#issuecomment-189711968)
		# CPU_USAGE=$(BC_ADD_LEADING_ZERO "$(echo "scale=1; 100 - $(top -b -n 1 | grep '%Cpu(s):' | awk '{print $8}')" | bc -l)")

		#convert to interger and graph it
		Percent_To_Graph $CPU_USAGE
		CPU_USAGE=$C_PERCENT_GRAPH

	}

	#Storage
	# - array
	MAX_STORAGE=6
	STORAGE_TOTAL=()
	STORAGE_USED=()
	STORAGE_FREE=()
	STORAGE_PERCENT=()
	STORAGE_PATH=()
	STORAGE_NAME=()

	Init_STORAGE(){

		for ((i=0; i<$MAX_STORAGE; i++))
		do
			STORAGE_TOTAL[$i]='N/A'
			STORAGE_USED[$i]='N/A'
			STORAGE_FREE[$i]='N/A'
			STORAGE_PERCENT[$i]=' Not installed'
			STORAGE_NAME[$i]=0

			# 0 reserved for flash storage
			if (( $i == 0 )); then

				STORAGE_PATH[$i]='/'
				STORAGE_NAME[$i]='Flash/RootFS Storage:    '

			else

				STORAGE_PATH[$i]="/mnt/usb_$i"
				STORAGE_NAME[$i]="Storage $i:               "

			fi

		done

	}

	Destroy_STORAGE(){

		unset STORAGE_TOTAL
		unset STORAGE_USED
		unset STORAGE_FREE
		unset STORAGE_PERCENT
		unset STORAGE_PATH
		unset STORAGE_NAME

	}

	# $1 $2 = Range of indexs to update (eg: 0-1)
	Obtain_STORAGE(){

		local index_start=$1
		local index_end=$2

		FP_TEMP="/tmp/.df"
		rm "$FP_TEMP"

		#df will endless hang when NFS server is down: https://github.com/Fourdee/DietPi/issues/395
		# - So lets run it as another thread so we can kill it if it hangs.
		local df_failed=0
		df -Ph > $FP_TEMP &
		local pid=$(echo $!)

		# - Wait X seconds before terminating the df thread
		local max_seconds=4
		local current_seconds=0
		while (( $(ps aux | awk '{print $2}' | grep -ci -m1 "$pid$") )) # ! -f may exist, but no data at time of scrape, causing 'mount not found'. so lets wait for process to exit.
		do

			if (( $current_seconds >= $max_seconds )); then

				#kill

				/DietPi/dietpi/func/dietpi-notify 1 "DF failed, unable to obtain drive data"
				sleep 2

				kill $pid

				df_failed=1

				echo -e "$(date) | df failed to respond" >> /var/log/dietpi-cloudshell.log

				break

			else

				sleep 1
				((current_seconds++))

			fi

		done

		if (( $df_failed )); then

			for ((i=$index_start; i<=$index_end; i++))
			do

				STORAGE_PERCENT[$i]="${STORAGE_PATH[$i]}"
				STORAGE_FREE[$i]='DF failed'

			done

		else

			for ((i=$index_start; i<=$index_end; i++))
			do

				if (( $(cat $FP_TEMP | grep -ci -m1 "${STORAGE_PATH[$i]}$") )); then

					STORAGE_TOTAL[$i]=$(cat $FP_TEMP | grep -m1 "${STORAGE_PATH[$i]}$" | awk '{print $2}'); STORAGE_TOTAL[$i]+='B'
					STORAGE_USED[$i]=$(cat $FP_TEMP | grep -m1 "${STORAGE_PATH[$i]}$" | awk '{print $3}'); STORAGE_USED[$i]+='B'
					STORAGE_FREE[$i]=$(cat $FP_TEMP | grep -m1 "${STORAGE_PATH[$i]}$" | awk '{print $4}'); STORAGE_FREE[$i]+='B'
					STORAGE_PERCENT[$i]=$(cat $FP_TEMP | grep -m1 "${STORAGE_PATH[$i]}$" | awk '{print $5}' | sed 's/%//g')

					Percent_To_Graph ${STORAGE_PERCENT[$i]}
					STORAGE_PERCENT[$i]=$C_PERCENT_GRAPH

					#DEBUG John:
					echo -e "Results success:\n" >> /var/log/dietpi-cloudshell.log
					echo -e " - Index = $i" >> /var/log/dietpi-cloudshell.log
					echo -e " - Path  = ${STORAGE_PATH[$i]}" >> /var/log/dietpi-cloudshell.log
					echo -e " - Total = ${STORAGE_TOTAL[$i]}" >> /var/log/dietpi-cloudshell.log

				else

					STORAGE_PERCENT[$i]="${STORAGE_PATH[$i]}"
					STORAGE_FREE[$i]='Mount not active'

					#DEBUG John:
					echo -e "$(date) | Mount not found:\n" >> /var/log/dietpi-cloudshell.log
					echo -e " - Index = $i" >> /var/log/dietpi-cloudshell.log
					echo -e " - Path  = ${STORAGE_PATH[$i]}\n" >> /var/log/dietpi-cloudshell.log
					cat "$FP_TEMP" >> /var/log/dietpi-cloudshell.log
					echo -e "\n" >> /var/log/dietpi-cloudshell.log

				fi

			done

		fi

	}

	#DietPi
	DIETPI_VERSION_CURRENT=0
	DIETPI_UPDATE_AVAILABLE=0
	DIETPI_WEBSITE="dietpi.com"
	DIETPI_TWITTER="@dietpi_"
	DIETPI_HW_DESCRIPTION="N/A"
	Obtain_DIETPIINFO(){

		#DietPi version
		DIETPI_VERSION_CURRENT="${aCOLOUR[2]}$(cat /DietPi/dietpi/.version)$C_RESET"

		#Current HW
		DIETPI_HW_DESCRIPTION=$(sed -n 2p /DietPi/dietpi/.hw_model)

		#DietPi-Update available?
		DIETPI_UPDATE_AVAILABLE="N/A"
		if [ -f /DietPi/dietpi/.update_available ]; then

			#Set current version to red
			DIETPI_VERSION_CURRENT="${aCOLOUR[1]}$(cat /DietPi/dietpi/.version)$C_RESET"

			local update_version=$(cat /DietPi/dietpi/.update_available)
			if (( $update_version > 0 )); then
				DIETPI_UPDATE_AVAILABLE="${aCOLOUR[2]}$update_version$C_RESET"

			elif (( $update_version == -1 )); then
				DIETPI_UPDATE_AVAILABLE="${aCOLOUR[2]}New Image$C_RESET"
			fi
		fi


	}

	#Network Details
	NETWORK_DETAILS_ADAPTER="eth0"
	NETWORK_DETAILS_IP_INT=0
	NETWORK_DETAILS_MAC_ADDRESS=0
	NETWORK_DETAILS_SIGNAL_STRENGTH=0
	NETWORK_DETAILS_DUPLEXSPEED=0
	NETWORK_DETAILS_HOSTNAME=0
	NETWORK_DETAILS_MODE=0 #1=dhcp, 0=static
	Obtain_NETWORK_DETAILS(){

		FP_TEMP="/tmp/.ifconfig"

		#Hostname
		NETWORK_DETAILS_HOSTNAME=$(hostname)

		#Active network adapater.
		NETWORK_DETAILS_ADAPTER=$(sed -n 3p /DietPi/dietpi/.network)

		#Mode (dhcp/static)
		if (( $(cat /etc/network/interfaces | grep -ci -m1 "iface $NETWORK_DETAILS_ADAPTER inet dhcp") )); then
			NETWORK_DETAILS_MODE="Dhcp"
		else
			NETWORK_DETAILS_MODE="Static"
		fi

		#Ifconfig to /tmp
		ifconfig $NETWORK_DETAILS_ADAPTER > $FP_TEMP

		#IP / MAC addresses
		NETWORK_DETAILS_IP_INT=$(cat "$FP_TEMP" | grep -m1 'inet '| cut -d: -f2 | awk '{ print $1}')
		NETWORK_DETAILS_MAC_ADDRESS=$(cat /sys/class/net/$NETWORK_DETAILS_ADAPTER/address)

		#Speed/Strength
		#Wifi
		if (( $(echo $NETWORK_DETAILS_ADAPTER | grep -ci -m1 'wlan') == 1 )); then
			NETWORK_DETAILS_SIGNAL_STRENGTH="$(iwconfig $NETWORK_DETAILS_ADAPTER | grep -m1 'Signal level=' | awk '{ print $4 }' | sed 's/level=//g' | cut -f1 -d "/")%"
			NETWORK_DETAILS_DUPLEXSPEED="$(iwconfig $NETWORK_DETAILS_ADAPTER | grep -m1 'Bit Rate:' | awk '{ print $2 }' | sed 's/Rate://g')Mbit"
		#Lan
		else
			NETWORK_DETAILS_DUPLEXSPEED="$(cat /sys/class/net/$NETWORK_DETAILS_ADAPTER/speed) Mbit"
			#NETWORK_DETAILS_DUPLEXSPEED=$(mii-tool | awk '{print $3}')
			NETWORK_DETAILS_SIGNAL_STRENGTH="N/A"
		fi

	}

	#Network Usage (all values are in bytes)
	NETWORK_USAGE_TOTAL_CURRENT_SENT=0
	NETWORK_USAGE_TOTAL_CURRENT_RECIEVED=0

	NETWORK_USAGE_NOW_CURRENT_SENT=0
	NETWORK_USAGE_NOW_CURRENT_RECIEVED=0
	NETWORK_USAGE_NOW_INIT=0
	NETWORK_USAGE_SECONDS_SINCE_LAST_UPDATE=0

	NETWORK_USAGE_DAY_CURRENT_SENT=0
	NETWORK_USAGE_DAY_CURRENT_RECIEVED=0
	NETWORK_USAGE_DAY_PREVIOUS_SENT=0
	NETWORK_USAGE_DAY_PREVIOUS_RECIEVED=0
	NETWORK_USAGE_DAY_OF_MONTH=-1

	Obtain_NETWORK_USAGE(){

		#Check for valid integer scrapes from netstat, before running calculations: http://dietpi.com/phpbb/viewtopic.php?f=11&t=441&p=1927#p1927 | https://github.com/Fourdee/DietPi/issues/355
		local run_update=1

		local mtu_size=$(netstat -N -i | grep "$NETWORK_DETAILS_ADAPTER" | awk '{print $2}')
		if [[ ! $mtu_size =~ ^-?[0-9]+$ ]]; then
			run_update=0
		fi

		local network_usage_current_recieved=$(netstat -N -i | grep "$NETWORK_DETAILS_ADAPTER" | awk '{print $4}')
		if [[ ! $network_usage_current_recieved =~ ^-?[0-9]+$ ]]; then
			run_update=0
		fi

		local network_usage_current_sent=$(netstat -N -i | grep "$NETWORK_DETAILS_ADAPTER" | awk '{print $8}')
		if [[ ! $network_usage_current_sent =~ ^-?[0-9]+$ ]]; then
			run_update=0
		fi


		if (( $run_update == 1 )); then

			#Store previous totals
			local total_previous_sent=$NETWORK_USAGE_TOTAL_CURRENT_SENT
			local total_previous_recieved=$NETWORK_USAGE_TOTAL_CURRENT_RECIEVED

			#Update current totals
			NETWORK_USAGE_TOTAL_CURRENT_RECIEVED=$(( $network_usage_current_recieved * $mtu_size ))
			NETWORK_USAGE_TOTAL_CURRENT_SENT=$(( $network_usage_current_sent * $mtu_size ))

			#Current usage
			# - Work out seconds since last update
			local seconds_since_last_update=$(( $(date +%s) - $NETWORK_USAGE_SECONDS_SINCE_LAST_UPDATE ))

			# - Init - Override current usage to 0, on first run of scene.
			if (( $NETWORK_USAGE_NOW_INIT == 0 )); then
				NETWORK_USAGE_NOW_CURRENT_SENT=0
				NETWORK_USAGE_NOW_CURRENT_RECIEVED=0

				NETWORK_USAGE_NOW_INIT=1

			# - Obtain current usage
			else
				NETWORK_USAGE_NOW_CURRENT_SENT=$(( ( $NETWORK_USAGE_TOTAL_CURRENT_SENT - $total_previous_sent ) / $seconds_since_last_update ))
				NETWORK_USAGE_NOW_CURRENT_RECIEVED=$(( ( $NETWORK_USAGE_TOTAL_CURRENT_RECIEVED - $total_previous_recieved ) / $seconds_since_last_update ))
			fi

			# - Update timestamp
			NETWORK_USAGE_SECONDS_SINCE_LAST_UPDATE=$(date +%s)

			# - Ifconfig to /tmp
			#ifconfig $NETWORK_DETAILS_ADAPTER > $FP_TEMP
			#/sys/class/net/ values are being reset by system/kernel when they reach X size. Some sort of "cap".
			#NETWORK_USAGE_TOTAL_CURRENT_SENT=$(( $(cat /sys/class/net/$NETWORK_DETAILS_ADAPTER/statistics/tx_bytes) / 1024 / 1024 ))
			#NETWORK_USAGE_TOTAL_CURRENT_RECIEVED=$(( $(cat /sys/class/net/$NETWORK_DETAILS_ADAPTER/statistics/rx_bytes) / 1024 / 1024 ))

			#Usage today
			# - Has the day changed? Also runs on init.
			#	String if statement, to prevent "leading zero integer error" from $(date): https://github.com/Fourdee/DietPi/issues/272
			local dayofmonth=$(date +"%d")
			if [ "$NETWORK_USAGE_DAY_OF_MONTH" != "$dayofmonth" ]; then
				#Update previous day values to current
				NETWORK_USAGE_DAY_PREVIOUS_SENT=$NETWORK_USAGE_TOTAL_CURRENT_SENT
				NETWORK_USAGE_DAY_PREVIOUS_RECIEVED=$NETWORK_USAGE_TOTAL_CURRENT_RECIEVED
				NETWORK_USAGE_DAY_OF_MONTH=$dayofmonth

			fi

			# - Work out todays usage
			NETWORK_USAGE_DAY_CURRENT_SENT=$(( $NETWORK_USAGE_TOTAL_CURRENT_SENT - $NETWORK_USAGE_DAY_PREVIOUS_SENT ))
			NETWORK_USAGE_DAY_CURRENT_RECIEVED=$(( $NETWORK_USAGE_TOTAL_CURRENT_RECIEVED - $NETWORK_USAGE_DAY_PREVIOUS_RECIEVED ))

		fi

	}

	#Memory
	MEMORY_TOTAL=0
	MEMORY_FREE=0
	MEMORY_USED=0
	MEMORY_CACHED=0
	MEMORY_PERCENT=0
	MEMORY_SWAPTOTAL=0
	MEMORY_SWAPUSED=0
	MEMORY_SWAPFREE=0
	MEMORY_SWAPERCENT=0
	Obtain_MEMORY(){

		#Write to temp
		FP_TEMP="/tmp/.mem"
		free -m > $FP_TEMP

		#RAM MB
		MEMORY_TOTAL=$(cat $FP_TEMP | grep -m1 'Mem: ' | awk '{print $2}')
		#Grab values and seperate cache from "used and free" results.
		MEMORY_CACHED=$(cat $FP_TEMP | grep -m1 'Mem: ' | awk '{print $7}')
		MEMORY_USED=$(( $(cat $FP_TEMP | grep -m1 'Mem: ' | awk '{print $3}') - $MEMORY_CACHED ))
		MEMORY_FREE=$(( $(cat $FP_TEMP | grep -m1 'Mem: ' | awk '{print $4}') + $MEMORY_CACHED ))
		MEMORY_PERCENT=$(echo | awk "{print $MEMORY_USED / $MEMORY_TOTAL * 100}")

		#convert to interger and graph it
		Percent_To_Graph $MEMORY_PERCENT
		MEMORY_PERCENT=$C_PERCENT_GRAPH

		#SWAP MB
		MEMORY_SWAPTOTAL=$(cat $FP_TEMP | grep -m1 'Swap: ' | awk '{print $2}')
		# - Swap available and active
		if (( $MEMORY_SWAPTOTAL > 0 )); then
			MEMORY_SWAPUSED=$(cat $FP_TEMP | grep -m1 'Swap: ' | awk '{print $3}')
			MEMORY_SWAPFREE=$(cat $FP_TEMP | grep -m1 'Swap: ' | awk '{print $4}')
			MEMORY_SWAPERCENT=$( echo | awk "{print $MEMORY_SWAPUSED / $MEMORY_SWAPTOTAL * 100}")

			#convert to interger and graph it
			Percent_To_Graph $MEMORY_SWAPERCENT
			MEMORY_SWAPERCENT=$C_PERCENT_GRAPH
		else
			MEMORY_SWAPERCENT=" Disabled"

		fi


	}

	#PI-HOLE STATS!
	PIHOLE_QUERY_COUNT=0
	PIHOLE_TOTAL_ADS=0
	PIHOLE_PERCENT_ADS=0
	PIHOLE_TOTAL_DOMAINS=0
	PIHOLE_LAST_DOMAIN_BLOCKED=0
	Obtain_PIHOLE(){

		local pihole_log_file="/var/log/pihole.log"

		#Lets pull the total number of blocked domains only once during 1st run, its quite cpu intensive.
		if (( $PIHOLE_TOTAL_DOMAINS == 0 )); then
			if [ -f /etc/pihole/gravity.list ]; then
				PIHOLE_TOTAL_DOMAINS=$(wc -l /etc/pihole/gravity.list | awk '{print $1}')
			else
				PIHOLE_TOTAL_DOMAINS="Not Installed"
			fi

		fi

		local today=$(date +'%b %e')

		PIHOLE_QUERY_COUNT=$(cat "$pihole_log_file" | grep "$today" | awk '/query/ {print $7}' | wc -l)
		#Prevent / 0 on percentage
		if (( $PIHOLE_QUERY_COUNT <= 0 )); then
			PIHOLE_QUERY_COUNT=1
		fi

		PIHOLE_TOTAL_ADS=$(cat "$pihole_log_file" | grep "$today" | awk '/\/etc\/pihole\/gravity.list/ {print $7}' | wc -l)
		PIHOLE_PERCENT_ADS=$(echo | awk "{print $PIHOLE_TOTAL_ADS / $PIHOLE_QUERY_COUNT * 100}")

		#convert to interger and graph it
		Percent_To_Graph $PIHOLE_PERCENT_ADS
		PIHOLE_PERCENT_ADS=$C_PERCENT_GRAPH

		#Get last blocked domain
		if (( $PIHOLE_TOTAL_ADS == 0 )); then
			PIHOLE_LAST_DOMAIN_BLOCKED="None"
		else
			PIHOLE_LAST_DOMAIN_BLOCKED=$(tac /var/log/pihole.log | grep -m1 'gravity.list' | awk '{print $6}' | cut -c 1-24 )
		fi

	}

	#/////////////////////////////////////////////////////////////////////////////////////
	# Scene Settings
	#/////////////////////////////////////////////////////////////////////////////////////
	RUN_INTRO=0
	if (( $INPUT == 1 )); then
		RUN_INTRO=1
	fi

	#SCENE INDEXS
	SCENE_CURRENT=2
	MAX_SCENES=9

	#Refresh rate (every X seconds)
	REFRESH_RATE=5

	#0='f | 1='c
	TEMPERATURE_OUTPUT_TYPE=1

	#0=bit (Mbit) | 1=byte (MB)
	NETWORK_USAGE_CURRENT_OUTPUT_TYPE=0

	#Enabled Scenes
	aEnabledScenes=()
	for ((i=0; i<$MAX_SCENES; i++))
	do
		aEnabledScenes[$i]=1
	done

	#/////////////////////////////////////////////////////////////////////////////////////
	# Scene Print / Update
	#/////////////////////////////////////////////////////////////////////////////////////

	Run_Intro(){

	   #'--------------------------'
		clear

		local aAnimation=(
			'                          '
			'i         -              c'
			'P  i      -            c l'
			't  P  i   -          c l o'
			'e  t  P  i-        c l o u'
			'i  e  t Pi-    c l o u d s'
			'D  i  etPi-  c l o u d s h'
			'  D  ietPi-c l o u d s h e'
			'    DietPi-cl o u d s h e '
			'    DietPi-clou d s h e l '
			'    DietPi-clouds h e l l '
			'    DietPi-cloudshe l l   '
			'    DietPi-cloudshell     '
		)

		local aBar=(
			' '
			'  '
			'    '
			'       '
			'         '
			'            '
			'               '
			'                 '
			'                    '
			'                      '
			'                        '
			'                         '
			'                          '

		)

		for ((i=0; i<${#aAnimation[@]}; i++))
		do

			clear
			echo -e "$C_RESET"
			echo -e ""
			echo -e ""
			echo -e ""
			echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}${aAnimation[$i]}"
			echo -e "$C_RESET          v$DIETPI_CLOUDSHELL_VERSION"
			echo -e ""
			echo -e "       Loading..."
			echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE${aBar[$i]}"

			sleep 0.2
		done

		#delete[] array
		unset aAnimation
		unset aBar

		sleep 0.1

	}

	#Top banner
	BANNER_PRINT=0
	BANNER_MODE=0
	Update_Banner(){

		#Banner Modes
		if (( $BANNER_MODE == 0 )); then
			BANNER_PRINT="NEMS $DIETPI_CLOUDSHELL_VERSION"
		elif (( $BANNER_MODE == 1 )); then
			Obtain_DATE_TIME
			BANNER_PRINT=$DATE_TIME
		elif (( $BANNER_MODE == 2 )); then
			Obtain_UPTIME
			BANNER_PRINT=$UPTIME
		fi

		#Set next index
		((BANNER_MODE++))

		#Cap
		if (( $BANNER_MODE >= 3 )); then
			BANNER_MODE=0
		fi

	}

	#CPU
	Update_Scene_0(){

		#Update data
		Obtain_CPU

		#Clear screen
		clear

		#Banner
		echo -e "$C_RESET $BANNER_PRINT"
		#
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE CPU Usage:               "
		echo -e "$C_RESET$CPU_USAGE"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE CPU Stats:               "
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Temp      ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $C_CPUTEMP$CPU_TEMP"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Processes ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $CPU_TOTALPROCESSES"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Governor  ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $CPU_GOV"

		#XU3/4 unique octo quad sets
		if (( $HW_MODEL == 11 )); then
			echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Freq 0-3  ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $CPU_FREQ_1 mhz"
			echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Freq 4-7  ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $CPU_FREQ_2 mhz"

		#Generic CPU hardware
		else
			echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Freq      ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $CPU_FREQ_1 mhz"
		fi

	}

	#$1 $2 = Storage index's to update and display (must be a range of 1 , eg: 0-1 1-2 3-4)
	Update_Scene_1(){

		local index_1=$1
		local index_2=$2

		#Update data
		Obtain_STORAGE $index_1 $index_2

		#Clear screen
		clear

		#Banner
		echo -e "$C_RESET $BANNER_PRINT"
		#
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE ${STORAGE_NAME[$index_1]}"
		echo -e "$C_RESET${STORAGE_PERCENT[$index_1]}"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Used: $C_RESET${STORAGE_USED[$index_1]} / ${STORAGE_TOTAL[$index_1]}"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Free: $C_RESET${STORAGE_FREE[$index_1]}"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE ${STORAGE_NAME[$index_2]}"
		echo -e "$C_RESET${STORAGE_PERCENT[$index_2]}"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Used: $C_RESET${STORAGE_USED[$index_2]} / ${STORAGE_TOTAL[$index_2]}"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Free: $C_RESET${STORAGE_FREE[$index_2]}"

	}

	#DietPi
	Update_Scene_4(){

		#Update data
		Obtain_DIETPIINFO

		#Clear screen
		clear

		#Banner
		echo -e "$C_RESET $BANNER_PRINT"
		#
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE DietPi:                  "
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Version   ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $DIETPI_VERSION_CURRENT"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Updates   ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $DIETPI_UPDATE_AVAILABLE"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Web       ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $DIETPI_WEBSITE"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Twitter   ${aCOLOUR[$USER_COLOUR_INDEX]}:$C_RESET  $DIETPI_TWITTER"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE Device:                  "
		echo -e "$C_RESET $DIETPI_HW_DESCRIPTION"

	}

	#NETWORK DETAILS
	Update_Scene_5(){

		#Update data
		Obtain_NETWORK_DETAILS

		#Clear screen
		clear

		#Banner
		echo -e "$C_RESET $BANNER_PRINT"
		#
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE Network Details:         "
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} IP      : $C_RESET$NETWORK_DETAILS_IP_INT"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Mode    : $C_RESET$NETWORK_DETAILS_MODE"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Adapter : $C_RESET$NETWORK_DETAILS_ADAPTER"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Duplex  : $C_RESET$NETWORK_DETAILS_DUPLEXSPEED"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Signal  : $C_RESET$NETWORK_DETAILS_SIGNAL_STRENGTH"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Hostname: $C_RESET$NETWORK_DETAILS_HOSTNAME"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} MAC: $C_RESET$NETWORK_DETAILS_MAC_ADDRESS"

	}

	#NETWORK USAGE
	Update_Scene_6(){

		#Update data
		Obtain_NETWORK_USAGE

		# - Convert usage values into human readable format. Run before clearing screen due to additional processing (delay)
		local total_sent_output=$( BYTE_PRINT_CONVERSION $NETWORK_USAGE_TOTAL_CURRENT_SENT )
		local total_recieved_output=$( BYTE_PRINT_CONVERSION $NETWORK_USAGE_TOTAL_CURRENT_RECIEVED )

		local today_sent_output=$( BYTE_PRINT_CONVERSION $NETWORK_USAGE_DAY_CURRENT_SENT )
		local today_recieved_output=$( BYTE_PRINT_CONVERSION $NETWORK_USAGE_DAY_CURRENT_RECIEVED )

		local now_sent_output=0
		local now_recieved_output0
		if (( $NETWORK_USAGE_CURRENT_OUTPUT_TYPE == 0 )); then
			now_sent_output=$( BIT_PRINT_CONVERSION $NETWORK_USAGE_NOW_CURRENT_SENT )
			now_recieved_output=$( BIT_PRINT_CONVERSION $NETWORK_USAGE_NOW_CURRENT_RECIEVED )
		else
			now_sent_output=$( BYTE_PRINT_CONVERSION $NETWORK_USAGE_NOW_CURRENT_SENT )
			now_recieved_output=$( BYTE_PRINT_CONVERSION $NETWORK_USAGE_NOW_CURRENT_RECIEVED )
		fi


		#Clear screen
		clear


		#Banner
		# - Banner does not fit this scene (>= 9 lines)
		#echo -e "$C_RESET $BANNER_PRINT"

		#
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE Network Usage (TOTAL):   "
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Sent     : $C_RESET$total_sent_output"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Recieved : $C_RESET$total_recieved_output"

		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE Network Usage (TODAY):   "
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Sent     : $C_RESET$today_sent_output"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Recieved : $C_RESET$today_recieved_output"

		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE Network Usage (CURRENT): "
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Sent     : $C_RESET$now_sent_output/s"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Recieved : $C_RESET$now_recieved_output/s"

	}

	#Memory
	Update_Scene_7(){

		#Update data
		Obtain_MEMORY

		#Clear screen
		clear

		#Banner
		echo -e "$C_RESET $BANNER_PRINT"
		#
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE Memory Usage (RAM):      "
		echo -e "$C_RESET$MEMORY_PERCENT"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Used: $C_RESET$MEMORY_USED MB / $MEMORY_TOTAL MB"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Free: $C_RESET$MEMORY_FREE MB"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE Memory Usage (SWAP):     "
		echo -e "$C_RESET$MEMORY_SWAPERCENT"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Used: $C_RESET$MEMORY_SWAPUSED MB / $MEMORY_SWAPTOTAL MB"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Free: $C_RESET$MEMORY_SWAPFREE MB"

	}

	#Pi-hole
	Update_Scene_8(){

		#Update data
		Obtain_PIHOLE

		#Clear screen
		clear

		#Banner
		echo -e "$C_RESET $BANNER_PRINT"
		#
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE Pi-hole stats (TODAY):   "
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Ads Blocked: $C_RESET$PIHOLE_TOTAL_ADS"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} DNS Queries: $C_RESET$PIHOLE_QUERY_COUNT"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]} Blocked Domains: $C_RESET$PIHOLE_TOTAL_DOMAINS"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE % of traffic = Ads:      "
		echo -e "$C_RESET$PIHOLE_PERCENT_ADS"
		echo -e "$C_RESET${aCOLOUR[$USER_COLOUR_INDEX]}$C_REVERSE Last domain blocked:     "
		echo -e "$C_RESET $PIHOLE_LAST_DOMAIN_BLOCKED"

	}

	#/////////////////////////////////////////////////////////////////////////////////////
	# Settings File
	#/////////////////////////////////////////////////////////////////////////////////////
	#Define Location
	FILEPATH_SETTINGS="/DietPi/dietpi/.dietpi-cloudshell"

	Read_Settings_File(){

		if [ -f "$FILEPATH_SETTINGS" ]; then

			. "$FILEPATH_SETTINGS"

		fi

	}

	Write_Settings_File(){

		cat << _EOF_ > "$FILEPATH_SETTINGS"
REFRESH_RATE=$REFRESH_RATE
USER_COLOUR_INDEX=$USER_COLOUR_INDEX
TEMPERATURE_OUTPUT_TYPE=$TEMPERATURE_OUTPUT_TYPE
OUTPUT_DISPLAY_INDEX=$OUTPUT_DISPLAY_INDEX

NETWORK_USAGE_CURRENT_OUTPUT_TYPE=$NETWORK_USAGE_CURRENT_OUTPUT_TYPE

BLANK_SCREEN_AT_SPECIFIC_TIME_ENABLED=$BLANK_SCREEN_AT_SPECIFIC_TIME_ENABLED
BLANK_SCREEN_TIME_HOUR_START=$BLANK_SCREEN_TIME_HOUR_START
BLANK_SCREEN_TIME_HOUR_END=$BLANK_SCREEN_TIME_HOUR_END

_EOF_

		#Add enabled scenes
		for ((i=0; i<$MAX_SCENES; i++))
		do

			echo -e "aEnabledScenes[$i]=${aEnabledScenes[$i]}" >> $FILEPATH_SETTINGS

		done

		#Add Drive Paths and Names
		for ((i=0; i<$MAX_STORAGE; i++))
		do

			echo -e "STORAGE_PATH[$i]='${STORAGE_PATH[$i]}'" >> $FILEPATH_SETTINGS
			echo -e "STORAGE_NAME[$i]='${STORAGE_NAME[$i]}'" >> $FILEPATH_SETTINGS

		done

	}

	#/////////////////////////////////////////////////////////////////////////////////////
	# Init
	#/////////////////////////////////////////////////////////////////////////////////////
	Init(){

		#--------------------------------------------------------------------------------
		#Storage array
		Init_STORAGE

		#--------------------------------------------------------------------------------
		#Load Settings file.
		Read_Settings_File

		#--------------------------------------------------------------------------------
		#VM disable CPU scene
		if (( $HW_MODEL == 20 )); then
			aEnabledScenes[0]=0
		fi

		#--------------------------------------------------------------------------------
		#Check and disable scenes if software is not installed:
		# 6 Pi-hole
		if [ ! -f /etc/pihole/gravity.list ]; then

			aEnabledScenes[8]=0

		fi

		#--------------------------------------------------------------------------------
		#Ensure we have at least 1 Scene enabled in the settings file.
		local enabled_scene=0
		for ((i=0; i<$MAX_SCENES; i++))
		do
			if (( ${aEnabledScenes[$i]} )); then
				enabled_scene=1
				break
			fi
		done

		#No Scenes selected! Override user setting and enable at least 1 scene (dietpi)
		if (( $enabled_scene == 0 )); then

			aEnabledScenes[4]=1
			SCENE_CURRENT=4

		fi
		#--------------------------------------------------------------------------------
		#Update DietPi network shared data: https://github.com/Fourdee/DietPi/issues/359
		/DietPi/dietpi/func/obtain_network_details

	}

	#/////////////////////////////////////////////////////////////////////////////////////
	# Start/Stop Control for Menu
	#/////////////////////////////////////////////////////////////////////////////////////
	#0=tty1 1=current
	OUTPUT_DISPLAY_INDEX=0

	Stop(){

		#Service if started.
		systemctl stop dietpi-cloudshell

		#Kill all , excluding Menu.
		ps ax | grep '[d]ietpi-cloudshell [1-9]' | awk '{print $1}' > "$FP_TEMP"
		while read -r line
		do
			kill $line &> /dev/null
		done < $FP_TEMP

	}

	Start(){

		#Are we starting on the current screen? (eg: from tty1)
		local output_current_screen=0
		if [ "$(tty)" = "/dev/tty1" ]; then
			output_current_screen=1
		elif (( $OUTPUT_DISPLAY_INDEX == 1 )); then
			output_current_screen=1
		fi

		#Inform user to press CTRL+C to exit
		if (( $output_current_screen == 1 )); then
			clear
			echo -e "$C_RESET"
			read -p "Use CTRL+C to exit. Press any key to launch $PROGRAM_NAME..."
		fi

		#Launch in blocking mode
		if (( $output_current_screen == 1 )); then

			/DietPi/dietpi/dietpi-cloudshell 1

		#Launch as service on main screen
		else

			systemctl start dietpi-cloudshell

		fi

		sleep 0.1

	}

	#/////////////////////////////////////////////////////////////////////////////////////
	# Menu System
	#/////////////////////////////////////////////////////////////////////////////////////
	WHIP_BACKTITLE=0
	WHIP_TITLE=0
	WHIP_QUESTION=0
	CHOICE=0
	TARGETMENUID=0
	LASTSELECTED_ITEM=""

	Menu_Exit(){

		WHIP_TITLE="Exit $PROGRAM_NAME"
		WHIP_QUESTION="Exit $PROGRAM_NAME configuration tool?"
		whiptail --title "$WHIP_TITLE" --yesno "$WHIP_QUESTION" --backtitle "$WHIP_TITLE" --yes-button "Ok" --no-button "Back" --defaultno 9 55
		CHOICE=$?
		if (( $CHOICE == 0 )); then

			#Save changes
			Write_Settings_File

			#exit
			TARGETMENUID=-1

		else

			#Return to Main Menu
			TARGETMENUID=0

		fi

	}

	#TARGETMENUID=0
	Menu_Main(){

		TARGETMENUID=0
		WHIP_BACKTITLE="- $PROGRAM_NAME v$DIETPI_CLOUDSHELL_VERSION -"
		WHIP_TITLE="- $PROGRAM_NAME -"

		local temp_output_text="Fahrenheit"
		if (( $TEMPERATURE_OUTPUT_TYPE == 1 )); then
			temp_output_text="Celsius"
		fi

		local target_output_text="Main Screen (tty1)"
		if (( $OUTPUT_DISPLAY_INDEX == 1 )); then
			target_output_text="Current screen or terminal"
		fi

		local bitbyte_output_text="Bit (Kbit, Mbit, Gbit)"
		if (( $NETWORK_USAGE_CURRENT_OUTPUT_TYPE == 1 )); then
			bitbyte_output_text="Byte (KB, MB, GB)"
		fi

		local autoscreenoff="Disabled"
		if (( $BLANK_SCREEN_AT_SPECIFIC_TIME_ENABLED )); then
			autoscreenoff="Enabled"
		fi

		OPTION=$(whiptail --title "$WHIP_TITLE" --backtitle "$WHIP_BACKTITLE" --menu "" --cancel-button "Exit" --default-item "$LASTSELECTED_ITEM" 17 75 10 \
		"Colour" "Setting: Change the colour scheme." \
		"Update Rate" "Setting: Control the time between screen updates." \
		"Scenes" "Setting: Toggle which scenes are shown." \
		"Storage" "Setting: Set mount locations used for storage stats" \
		"Temperature" "Setting: Output = $temp_output_text" \
		"Net Usage Current" "Setting: Output = $bitbyte_output_text" \
		"Output Display" "Setting: $target_output_text." \
		"Auto screen off" "Setting: $autoscreenoff | Start $BLANK_SCREEN_TIME_HOUR_START h | End $BLANK_SCREEN_TIME_HOUR_END h" \
		"Start / Restart" "Apply settings. Launch on $target_output_text." \
		"Stop" "Stops $PROGRAM_NAME."  3>&1 1>&2 2>&3)

		CHOICE=$?
		if (( $CHOICE == 0 )); then

			LASTSELECTED_ITEM="$OPTION"

			case "$OPTION" in

				"Storage")
					TARGETMENUID=5
				;;
				"Auto screen off")
					TARGETMENUID=4
				;;
				"Net Usage Current")
					((NETWORK_USAGE_CURRENT_OUTPUT_TYPE++))
					if (( $NETWORK_USAGE_CURRENT_OUTPUT_TYPE > 1 )); then
						NETWORK_USAGE_CURRENT_OUTPUT_TYPE=0
					fi
				;;
				Temperature)
					((TEMPERATURE_OUTPUT_TYPE++))
					if (( $TEMPERATURE_OUTPUT_TYPE > 1 )); then
						TEMPERATURE_OUTPUT_TYPE=0
					fi
				;;
				"Output Display")
					((OUTPUT_DISPLAY_INDEX++))
					if (( $OUTPUT_DISPLAY_INDEX > 1 )); then
						OUTPUT_DISPLAY_INDEX=0
					fi
				;;
				"Start / Restart")
					Write_Settings_File
					Stop
					Start
				;;
				"Stop")
					Stop
				;;
				Colour)
					TARGETMENUID=1
				;;
				"Update Rate")
					TARGETMENUID=2
				;;
				Scenes)
					TARGETMENUID=3
				;;
			esac
		else
			Menu_Exit
		fi

	}

	#TARGETMENUID=1
	Menu_Colour(){

		#Return to main menu
		TARGETMENUID=0

		#Colour array
		#0 WHITE
		#1 RED
		#2 GREEN
		#3 YELLOW
		#4 BLUE
		#5 PURPLE
		#6 CYAN
		WHIP_TITLE='- Options : Colour -'
		WHIP_QUESTION='Select your colour scheme.'
		OPTION=$(whiptail --title "$WHIP_TITLE" --backtitle "$WHIP_BACKTITLE" --menu "$WHIP_QUESTION" --cancel-button "Back" --default-item "$USER_COLOUR_INDEX" 15 45 7 \
		"0" "White" \
		"1" "Red" \
		"2" "Green" \
		"3" "Yellow (Default)" \
		"4" "Blue" \
		"5" "Purple" \
		"6" "Cyan"  3>&1 1>&2 2>&3)

		CHOICE=$?
		if (( $CHOICE == 0 )); then

			USER_COLOUR_INDEX=$OPTION

		fi

	}

	#TARGETMENUID=2
	Menu_UpdateRate(){

		#Return to main menu
		TARGETMENUID=0

		WHIP_TITLE='- Options : Update Rate -'
		WHIP_QUESTION='Change the delay between scene changes and updates.'
		OPTION=$(whiptail --title "$WHIP_TITLE" --backtitle "$WHIP_BACKTITLE" --menu "$WHIP_QUESTION" --cancel-button "Back" --default-item "$REFRESH_RATE" 15 55 7 \
		"1" "Second" \
		"3" "Seconds" \
		"5" "Seconds (Default)" \
		"10" "Seconds" \
		"15" "Seconds" \
		"20" "Seconds" \
		"30" "Seconds" \
		"45" "Seconds" \
		"60" "Seconds" 3>&1 1>&2 2>&3)

		CHOICE=$?
		if (( $CHOICE == 0 )); then

			REFRESH_RATE=$OPTION

		fi

	}

	#TARGETMENUID=3
	Menu_SceneSelection(){

		#Return to main menu
		TARGETMENUID=0

		FP_TEMP="/tmp/.dietpi-cloudshell_scenelist"

		#Get on/off whilptail status
		local aWhiptailArray=()
		local aWhip_OnOff_Status=()
		for ((i=0; i<$MAX_SCENES; i++))
		do
			#On/Off status
			aWhip_OnOff_Status[$i]='on'
			if (( ! ${aEnabledScenes[$i]} )); then

				aWhip_OnOff_Status[$i]='off'

			fi

		done

		#Define options
		local index=0
		index=0;aWhiptailArray+=("$index" "CPU: Temperatures, Usage, frequency and more." "${aWhip_OnOff_Status[$index]}")
		index=1;aWhiptailArray+=("$index" "Storage: Usage information for Flash and USB drives" "${aWhip_OnOff_Status[$index]}")
		index=2;aWhiptailArray+=("$index" " - Additional Storage (USB_2/3)" "${aWhip_OnOff_Status[$index]}")
		index=3;aWhiptailArray+=("$index" " - Additional Storage (USB_4/5)" "${aWhip_OnOff_Status[$index]}")
		index=4;aWhiptailArray+=("$index" "DietPi: Information, stats and updates for DietPi." "${aWhip_OnOff_Status[$index]}")
		index=5;aWhiptailArray+=("$index" "Network Details: Ip address, Speeds, Signal and more." "${aWhip_OnOff_Status[$index]}")
		index=6;aWhiptailArray+=("$index" "Network Usage: Bandwidth usage (sent / recieved)." "${aWhip_OnOff_Status[$index]}")
		index=7;aWhiptailArray+=("$index" "Memory: Stats for RAM and Swapfile usage." "${aWhip_OnOff_Status[$index]}")
		index=8;aWhiptailArray+=("$index" "Pi-hole: Stats for Pi-hole. Total Ads blocked etc." "${aWhip_OnOff_Status[$index]}")

		WHIP_TITLE='- Options : Scene Selection -'
		WHIP_QUESTION='Please use the spacebar to toggle which scenes are active.'
		whiptail --title "$WHIP_TITLE" --checklist "$WHIP_QUESTION" --backtitle "$WHIP_TITLE" --separate-output 16 75 9 "${aWhiptailArray[@]}" 2> "$FP_TEMP"
		CHOICE=$?

		#Delete[] array
		unset aWhiptailArray
		unset aWhip_OnOff_Status

		# - Reset all scenes to 0
		if (( $CHOICE == 0 )); then

			for ((i=0; i<$MAX_SCENES; i++))
			do
				aEnabledScenes[$i]=0

			done

		fi

		# - Enable required scenes
		while read -r line
		do

			aEnabledScenes[$line]=1

		done < "$FP_TEMP"

	}

	#TARGETMENUID=4
	Menu_BlankScreenAtTime(){

		#Return to main menu
		TARGETMENUID=0

		#generate 24 hour array
		local aWhipHour=()
		for ((i=0; i<24; i++))
		do
			aWhipHour+=("$i" "Hour")

		done

		local blank_screen_at_specific_time_enabled_text='Disabled'
		if (( $BLANK_SCREEN_AT_SPECIFIC_TIME_ENABLED )); then
			blank_screen_at_specific_time_enabled_text='Enabled'
		fi

		WHIP_TITLE='- Options : Auto screen off -'
		WHIP_QUESTION='Automatically power down the screen and disable DietPi-Cloudshell processing during a specific time.\n\nNB: This feature will only work if DietPi-Cloudshell was launched with the DietPi-Autostart option, or, launched from the main screen (tty1).'
		OPTION=$(whiptail --title "$WHIP_TITLE" --backtitle "$WHIP_BACKTITLE" --menu "$WHIP_QUESTION" --cancel-button "Back" --default-item "$REFRESH_RATE" 16 60 3 \
		"Toggle" "$blank_screen_at_specific_time_enabled_text" \
		"Start time" "Set which hour to power off screen ($BLANK_SCREEN_TIME_HOUR_START)." \
		"End time" "Set which hour to power on screen ($BLANK_SCREEN_TIME_HOUR_END)." 3>&1 1>&2 2>&3)

		CHOICE=$?
		if (( $CHOICE == 0 )); then

			if [ "$OPTION" = "Toggle" ];then

				((BLANK_SCREEN_AT_SPECIFIC_TIME_ENABLED++))
				if (( $BLANK_SCREEN_AT_SPECIFIC_TIME_ENABLED > 1 )); then
					BLANK_SCREEN_AT_SPECIFIC_TIME_ENABLED=0
				fi

			elif [ "$OPTION" = "Start time" ];then

				WHIP_QUESTION='Please select which hour (24h) you would like the screen to power off.'
				OPTION=$(whiptail --title "$WHIP_TITLE" --menu "$WHIP_QUESTION" --default-item "$BLANK_SCREEN_TIME_HOUR_START" --backtitle "$WHIP_BACKTITLE" 16 55 7 "${aWhipHour[@]}" 3>&1 1>&2 2>&3)
				CHOICE=$?
				if (( $CHOICE == 0 )); then
					BLANK_SCREEN_TIME_HOUR_START=$OPTION
				fi

			elif [ "$OPTION" = "End time" ];then

				WHIP_QUESTION='Please select which hour (24h) you would like the screen to power on.'
				OPTION=$(whiptail --title "$WHIP_TITLE" --menu "$WHIP_QUESTION" --default-item "$BLANK_SCREEN_TIME_HOUR_END" --backtitle "$WHIP_BACKTITLE" 16 55 7 "${aWhipHour[@]}" 3>&1 1>&2 2>&3)
				CHOICE=$?
				if (( $CHOICE == 0 )); then
					BLANK_SCREEN_TIME_HOUR_END=$OPTION
				fi

			fi

			TARGETMENUID=4

		fi

		unset aWhipHour

	}

	#TARGETMENUID=5
	Menu_Storage(){

		#Return to main menu
		TARGETMENUID=0

		local aWhiptailArray=()

		for ((i=1; i<$MAX_STORAGE; i++))
		do

			#aWhiptailArray+=("Name $i" "${STORAGE_NAME[$i]}.")
			aWhiptailArray+=("$i" ": Drive $i | ${STORAGE_PATH[$i]}")

		done

		WHIP_TITLE='- Options : Storage Device Mount Location -'
		WHIP_QUESTION='DietPi-Cloudshell pulls the storage stats from the drive mount location. If you have custom drives/mounts, please set them here to be displayed during storage scene updates.\n\n - Drive 1 = Displayed during main storage scene\n - Drive 2/3 = Displayed during additional storage scene\n - Drive 4/5 = Displayed during additional storage scene'
		OPTION=$(whiptail --title "$WHIP_TITLE" --backtitle "$PROGRAM_NAME" --menu "$WHIP_QUESTION" --cancel-button "Back" 19 75 5 "${aWhiptailArray[@]}" 3>&1 1>&2 2>&3)

		CHOICE=$?

		unset aWhiptailArray

		if (( $CHOICE == 0 )); then

			local index=$OPTION

			/DietPi/dietpi/dietpi-drive_manager 1
			local return_string="$(cat /tmp/dietpi-drive_manager_selmnt)"
			if [ -n "$return_string" ]; then

				STORAGE_PATH[$index]="$return_string"

			fi

			TARGETMENUID=5

		fi

	}


	#/////////////////////////////////////////////////////////////////////////////////////
	# MAIN
	#/////////////////////////////////////////////////////////////////////////////////////
	#-----------------------------------------------------------------------------------
	#Init
	Init
	#-----------------------------------------------------------------------------------
	#Run menu
	if (( $INPUT == 0 )); then

		#Start Menu
		while (( $TARGETMENUID >= 0 )); do

			clear

			if (( $TARGETMENUID == 0 )); then
				Menu_Main
			elif (( $TARGETMENUID == 1 )); then
				Menu_Colour
			elif (( $TARGETMENUID == 2 )); then
				Menu_UpdateRate
			elif (( $TARGETMENUID == 3 )); then
				Menu_SceneSelection
			elif (( $TARGETMENUID == 4 )); then
				Menu_BlankScreenAtTime
			elif (( $TARGETMENUID == 5 )); then
				Menu_Storage
			fi

		done

	#-----------------------------------------------------------------------------------
	#Run DietPi-Cloudshell
	elif (( $INPUT >= 1 )); then

		Enable_Term_Options

		#Start Intro
		if (( $RUN_INTRO )); then
			Run_Intro
		fi

		#Set Nice to +10 (not critical)
		renice -n 10 $$ &> /dev/null

		#Start display updates
		while true
		do

			if (( $BLANK_SCREEN_AT_SPECIFIC_TIME_ENABLED )); then

				RUN_BLANK_SCREEN_AT_SPECIFIC_TIME

			fi

			#Disable updates when screen is blanked
			if (( $BLANK_SCREEN_ACTIVE )); then

				sleep 60

			#Update enabled scenes
			else

				if (( ${aEnabledScenes[$SCENE_CURRENT]} )); then

					Update_Banner

					# - Input mode scene update (storage array)
					if (( $SCENE_CURRENT == 1 )); then

						Update_Scene_1 0 1

					# - Input mode scene update (storage array)
					elif (( $SCENE_CURRENT == 2 )); then

						Update_Scene_1 2 3

					# - Input mode scene update (storage array)
					elif (( $SCENE_CURRENT == 3 )); then

						Update_Scene_1 4 5

					# - Normal scene update
					else

						Update_Scene_$SCENE_CURRENT

					fi

					#Apply refresh rate delay
					sleep $REFRESH_RATE

				fi

				#Scene Switcher
				((SCENE_CURRENT++))

				#Cap
				if (( $SCENE_CURRENT >= $MAX_SCENES )); then
					SCENE_CURRENT=0
				fi


			fi

		done
	fi

	#-----------------------------------------------------------------------------------
	#Clean up temp files
	rm "$FP_TEMP" &> /dev/null
	#-----------------------------------------------------------------------------------
	#Delete[] Global arrays
	unset aCOLOUR
	unset aEnabledScenes
	Destroy_STORAGE
	#-----------------------------------------------------------------------------------
	exit
	#-----------------------------------------------------------------------------------
}
