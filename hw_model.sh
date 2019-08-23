#!/bin/bash
{

  if [[ ! -f /var/log/nems/hw_model ]]; then
    touch /var/log/nems/hw_model
  fi

	#////////////////////////////////////
	#
	# Originally Created by Daniel Knight
	# daniel.knight@dietpi.com / dietpi.com
	#
        # Adapted for NEMS by Robbie Ferguson
	#
	#////////////////////////////////////
	#
	# Info:
	# - Generates /DietPi/dietpi/.hw_model
	# - Called from /DietPi/dietpi/boot
	#
	# In DietPi-Software:
	#	MAX_HW_MODEL=64		#This needs to match highest HW_MODEL value in dietpi-obtain_hw_model
	#	MAX_HW_ARCH=10		#This needs to match highest HW_ARCH value in dietpi-obtain_hw_model
	#
	# - Line1 -
	# HW_MODEL 121 Khadas VIM3 Pro
	# HW_MODEL 120 Khadas VIM3 Basic
	# HW_MODEL 110 RoseapplePi
	# HW_MODEL 101 ASUS Tinker Board S
	# HW_MODEL 100 ASUS Tinker Board
	# HW_MODEL 90 A20-OLinuXino-MICRO
	# HW_MODEL 80 Cubieboard 3
	# HW_MODEL 79 Sparky SBC
	# HW_MODEL 70 NanoPi NEO Plus2 (1 GB)
	# HW_MODEL 69 NanoPi NEO Plus2 (512 MB)
	# HW_MODEL 68 NanoPi M4 (4 GB)
	# HW_MODEL 67 NanoPi M4 (2 GB)
	# HW_MODEL 66 NanoPi M1 Plus
	# HW_MODEL 65 NanoPi NEO 2
	# HW_MODEL 64 NanoPi NEO Air
	# HW_MODEL 63 NanoPi M1/T1
	# HW_MODEL 62 NanoPi M3/T3
	# HW_MODEL 61 NanoPi M2/T2
	# HW_MODEL 60 NanoPi Neo
	# HW_MODEL 51 BananaPi Pro (Lemaker)
	# HW_MODEL 50 BananaPi M2+ (sinovoip)
	# HW_MODEL 49 RockPro64 4GB
	# HW_MODEL 48 RockPro64 2GB
	# HW_MODEL 47 Rock64 4GB
	# HW_MODEL 46 Rock64 2GB
	# HW_MODEL 45 Rock64 1GB
	# HW_MODEL 44 Pine A64-LTS/Sopine
	# HW_MODEL 42 Pine A64+ (2048mb)
	# HW_MODEL 41 Pine A64+ (1024mb)
	# HW_MODEL 40 Pine A64  (512mb)
	# HW_MODEL 38 OrangePi PC 2
	# HW_MODEL 37 OrangePi Prime
	# HW_MODEL 36 OrangePi Win
	# HW_MODEL 35 OrangePi Zero Plus 2 (H3/H5)
	# HW_MODEL 34 OrangePi Plus
	# HW_MODEL 33 OrangePi Lite
	# HW_MODEL 32 OrangePi Zero (H2+)
	# HW_MODEL 31 OrangePi One
	# HW_MODEL 30 OrangePi PC
	# HW_MODEL 29 x86_64 native (PC)
        # HW_MODEL 22 Amazon Web Services
	# HW_MODEL 21 Docker Container
	# HW_MODEL 20 VM x64 (VMware VirtualBox)
	# HW_MODEL 16 ODROID-N2 (4 GB)
	# HW_MODEL 15 ODROID-N2 (2 GB)
	# HW_MODEL 13 oDroid U3
	# HW_MODEL 12 oDroid C2
	# HW_MODEL 11 oDroid XU3/XU4/HC1/HC2
	# HW_MODEL 10 oDroid C1
	# HW_MODEL 8 Raspberry Pi 4 (4GB)
	# HW_MODEL 7 Raspberry Pi 4 (2GB)
	# HW_MODEL 6 Raspberry Pi 4 (1GB)
	# HW_MODEL 5 Raspberry Pi 3 Model A+
	# HW_MODEL 4 Raspberry Pi 3 Model B+
	# HW_MODEL 3 Raspberry Pi 3
	# HW_MODEL 2 Raspberry Pi 2
	# HW_MODEL 1 Raspberry Pi 1/Zero (512mb)
	# HW_MODEL 0 Raspberry Pi 1 (256mb)
	# - Line2 -
	# HW_MODEL_DESCRIPTION
	# - Line3 -
	# DISTRO 0 unknown
	# DISTRO 1 Debian Wheezy (No longer supported, http://dietpi.com/phpbb/viewtopic.php?f=9&t=432#p1898)
	# DISTRO 2 Ubuntu 14.04 (No longer supported, left in for user message during update)
	# DISTRO 3 Jessie
	# DISTRO 4 Stretch, pulled a muscle!
	# - Line4 -
	# RootFS device path (eg: /dev/mmc01)
	# - Line5 -
	# UUID
	# - Line 6 -
	# HW_ARCH 10 x86_64 (VM)
	# HW_ARCH 3 armv8/arm64
	# HW_ARCH 2 armv7
	# HW_ARCH 1 armv6
	# HW_ARCH 0 unknown
	# - Line 7 -
	# HW_ARCH_DESCRIPTION
	# - Line 8 -
	# IMAGE_ADDITIONAL_CREDITS (eg: ARMbian, Meveric)
	# - Line 9 - Group CPU's
	# HW_CPUID 0 Not set
	# HW_CPUID 1 H3
	# HW_CPUID 2 H5
	# - Line 10 - Onboard WiFi/BT Index
	# HW_ONBOARD_WIFI 0 Not set
	# HW_ONBOARD_WIFI 1 RPi3/ZeroW (BCM43438)
	# - Line 11 - (RPi only)
	# HW_REVISION_CODE
	# - Line 12 - (RPi only)
	# HW_RELEASE_DATE
	# - Line 13 - (RPi only)
	# HW_PCB_REVISION_CODE
	# - Line 14 - (RPi only)
	# HW_MEMORY_SIZE
	# - Line 15 - (RPi only)
	# HW_MANUFACTURER_NAME
	#////////////////////////////////////

	#Force en_GB Locale for whole script. Prevents incorrect parsing with non-english locales.
	LANG=en_GB.UTF-8

	#Ensure we are in users home dir: https://github.com/Fourdee/DietPi/issues/905#issuecomment-298223705
	cd "$HOME"

	#/////////////////////////////////////////////////////////////////////////////////////
	#Obtain Hardware Model index
	#/////////////////////////////////////////////////////////////////////////////////////

	HW_MODEL=0
	HW_MODEL_DESCRIPTION='Unknown Device'
	FP_HW_MODEL_INDENTIFIER='/etc/.nems_hw_model_identifier'
	DISTRO=0
	HW_UUID=0
	HW_ARCH=0
	HW_ARCH_DESCRIPTION='unknown'
	IMAGE_ADDITIONAL_CREDITS=''
	HW_CPUID=0
	HW_ONBOARD_WIFI=0

	ROOTFS_DEVICE_PATH=$(df | grep -m1 '/$' | awk '{print $1}')

	#	RPi Extras
	HW_REVISION_CODE=0
	HW_RELEASE_DATE='Unknown'
	HW_PCB_REVISION_CODE='Unknown'
	HW_MEMORY_SIZE=0
	HW_MANUFACTURER_NAME='Unknown'

	RPi_BoardInfo(){

		#-----------------------------------------------------------------------------------
		#Obtain device info by revision number
		# *" because 10000002 then it indicates that your Raspberry Pi has been over-volted
		HW_REVISION_CODE=$(cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}')

		HW_MODEL_DESCRIPTION='Raspberry Pi '

		if [[ "$HW_REVISION_CODE" = *"Beta" ]]; then

			HW_RELEASE_DATE='Q1 2012'
			HW_MODEL_DESCRIPTION+='Beta'
			HW_PCB_REVISION_CODE='Unknown'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Unknown'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"0002" ]]; then

			HW_RELEASE_DATE='Q1 2012'
			HW_MODEL_DESCRIPTION+='B'
			HW_PCB_REVISION_CODE='1.0'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Unknown'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"0003" ]]; then

			HW_RELEASE_DATE='Q3 2012'
			HW_MODEL_DESCRIPTION+='B (ECN0001)'
			HW_PCB_REVISION_CODE='1.0'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Unknown'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"0004" ]]; then

			HW_RELEASE_DATE='Q3 2012'
			HW_MODEL_DESCRIPTION+='B'
			HW_PCB_REVISION_CODE='2.0'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"0005" ]]; then

			HW_RELEASE_DATE='Q4 2012'
			HW_MODEL_DESCRIPTION+='B'
			HW_PCB_REVISION_CODE='2.0'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Qisda'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"0006" ]]; then

			HW_RELEASE_DATE='Q4 2012'
			HW_MODEL_DESCRIPTION+='B'
			HW_PCB_REVISION_CODE='2.0'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Egoman'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"0007" ]]; then

			HW_RELEASE_DATE='Q1 2013'
			HW_MODEL_DESCRIPTION+='A'
			HW_PCB_REVISION_CODE='2.0'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Egoman'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"0008" ]]; then

			HW_RELEASE_DATE='Q1 2013'
			HW_MODEL_DESCRIPTION+='A'
			HW_PCB_REVISION_CODE='2.0'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"0009" ]]; then

			HW_RELEASE_DATE='Q1 2013'
			HW_MODEL_DESCRIPTION+='A'
			HW_PCB_REVISION_CODE='2.0'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Qisda'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"000d" ]]; then

			HW_RELEASE_DATE='Q4 2012'
			HW_MODEL_DESCRIPTION+='B'
			HW_PCB_REVISION_CODE='2.0'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Egoman'
			HW_MODEL=1

		elif [[ "$HW_REVISION_CODE" = *"000e" ]]; then

			HW_RELEASE_DATE='Q4 2012'
			HW_MODEL_DESCRIPTION+='B'
			HW_PCB_REVISION_CODE='2.0'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=1

		elif [[ "$HW_REVISION_CODE" = *"000f" ]]; then

			HW_RELEASE_DATE='Q4 2012'
			HW_MODEL_DESCRIPTION+='B'
			HW_PCB_REVISION_CODE='2.0'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Qisda'
			HW_MODEL=1

		elif [[ "$HW_REVISION_CODE" = *"0010" ]]; then

			HW_RELEASE_DATE='Q3 2014'
			HW_MODEL_DESCRIPTION+='B+'
			HW_PCB_REVISION_CODE='1.0'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=1

		elif [[ "$HW_REVISION_CODE" = *"0011" ]]; then

			HW_RELEASE_DATE='Q2 2014'
			HW_MODEL_DESCRIPTION+='CM'
			HW_PCB_REVISION_CODE='1.0'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=1

		elif [[ "$HW_REVISION_CODE" = *"0012" ]]; then

			HW_RELEASE_DATE='Q4 2014'
			HW_MODEL_DESCRIPTION+='A+'
			HW_PCB_REVISION_CODE='1.0'
			HW_MEMORY_SIZE=256
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=0

		elif [[ "$HW_REVISION_CODE" = *"0013" ]]; then

			HW_RELEASE_DATE='Q1 2015'
			HW_MODEL_DESCRIPTION+='B+'
			HW_PCB_REVISION_CODE='1.2'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Unknown'
			HW_MODEL=1

		elif [[ "$HW_REVISION_CODE" = *"a01041" ]]; then

			HW_RELEASE_DATE='Q1 2015'
			HW_MODEL_DESCRIPTION+='2 Model B'
			HW_PCB_REVISION_CODE='1.1'
			HW_MEMORY_SIZE=1024
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=2

		elif [[ "$HW_REVISION_CODE" = *"a020a0" ]]; then

			HW_RELEASE_DATE='Q1 2017'
			HW_MODEL_DESCRIPTION+='CM 3'
			HW_PCB_REVISION_CODE='1.0'
			HW_MEMORY_SIZE=1024
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=3
			HW_ONBOARD_WIFI=1

		elif [[ "$HW_REVISION_CODE" = *"a21041" ]]; then

			HW_RELEASE_DATE='Q1 2015'
			HW_MODEL_DESCRIPTION+='2 Model B'
			HW_PCB_REVISION_CODE='1.1'
			HW_MEMORY_SIZE=1024
			HW_MANUFACTURER_NAME='Embest, China'
			HW_MODEL=2

		elif [[ "$HW_REVISION_CODE" = *"a02082" ]]; then

			# This is a Model B board
			HW_RELEASE_DATE='Q1 2016'
			HW_MODEL_DESCRIPTION+='3'
			HW_PCB_REVISION_CODE='1.2'
			HW_MEMORY_SIZE=1024
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=3
			HW_ONBOARD_WIFI=1

		elif [[ "$HW_REVISION_CODE" = *"a22082" ]]; then

			# This is a Model B board
			HW_RELEASE_DATE='Q1 2016'
			HW_MODEL_DESCRIPTION+='3'
			HW_PCB_REVISION_CODE='1.2'
			HW_MEMORY_SIZE=1024
			HW_MANUFACTURER_NAME='Embest, China'
			HW_MODEL=3
			HW_ONBOARD_WIFI=1

		elif [[ "$HW_REVISION_CODE" = *"a32082" ]]; then

			# This is a Model B board
			HW_RELEASE_DATE='Q4 2016'
			HW_MODEL_DESCRIPTION+='3'
			HW_PCB_REVISION_CODE='1.2'
			HW_MEMORY_SIZE=1024
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=3
			HW_ONBOARD_WIFI=1

		elif [[ "$HW_REVISION_CODE" = *"900092" ]]; then

			HW_RELEASE_DATE='Q4 2015'
			HW_MODEL_DESCRIPTION+='Zero'
			HW_PCB_REVISION_CODE='1.2'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=1

		elif [[ "$HW_REVISION_CODE" = *"900093" ]]; then

			HW_RELEASE_DATE='Q2 2016'
			HW_MODEL_DESCRIPTION+='Zero'
			HW_PCB_REVISION_CODE='1.3'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=1

		elif [[ "$HW_REVISION_CODE" = *"9000c1" ]]; then

			HW_RELEASE_DATE='Q1 2017'
			HW_MODEL_DESCRIPTION+='Zero W'
			HW_PCB_REVISION_CODE='1.1'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=1
			HW_ONBOARD_WIFI=1

		elif [[ "$HW_REVISION_CODE" = *"a020d3" ]]; then

			HW_RELEASE_DATE='Q1 2018'
			HW_MODEL_DESCRIPTION+='3 B+'
			HW_PCB_REVISION_CODE='n/a'
			HW_MEMORY_SIZE=1024
			HW_MANUFACTURER_NAME='Sony'
			HW_MODEL=4
			HW_ONBOARD_WIFI=1


		elif [[ "$HW_REVISION_CODE" == *"9020e0" ]]; then

			HW_RELEASE_DATE='Q3 2018'
			HW_MODEL_DESCRIPTION+='3 A+'
			HW_PCB_REVISION_CODE='1.0'
			HW_MEMORY_SIZE=512
			HW_MANUFACTURER_NAME='Sony UK'
			HW_MODEL=5
			HW_ONBOARD_WIFI=1

		elif [[ "$HW_REVISION_CODE" == *"a03111" ]]; then
		
			# This is a Model B board
			HW_RELEASE_DATE='Q2 2019'
			HW_MODEL_DESCRIPTION+='4'
			HW_PCB_REVISION_CODE='1.1'
			HW_MEMORY_SIZE=1024
			HW_MANUFACTURER_NAME='Sony UK'
			HW_MODEL=6
			HW_ONBOARD_WIFI=1

		elif [[ "$HW_REVISION_CODE" == *"b03111" ]]; then
		
			# This is a Model B board
			HW_RELEASE_DATE='Q2 2019'
			HW_MODEL_DESCRIPTION+='4'
			HW_PCB_REVISION_CODE='1.1'
			HW_MEMORY_SIZE=2048
			HW_MANUFACTURER_NAME='Sony UK'
			HW_MODEL=7
			HW_ONBOARD_WIFI=1

		elif [[ "$HW_REVISION_CODE" == *"c03111" ]]; then

			# This is a Model B board
			HW_RELEASE_DATE='Q2 2019'
			HW_MODEL_DESCRIPTION+='4'
			HW_PCB_REVISION_CODE='1.1'
			HW_MEMORY_SIZE=4096
			HW_MANUFACTURER_NAME='Sony UK'
			HW_MODEL=8
			HW_ONBOARD_WIFI=1

		fi

	}

	Obtain_HW_Info(){

		#Systems that use /etc/.dietpi_hw_model_identifier for HW_MODEL
		if [ -f "$FP_HW_MODEL_INDENTIFIER" ]; then

			HW_MODEL=$(sed -n 1p "$FP_HW_MODEL_INDENTIFIER")

			#RoseapplePi
			if (( $HW_MODEL == 110 )); then

				HW_MODEL_DESCRIPTION='RoseapplePi'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'


			# Khadas VIM3 Basic / Pro
			elif (( $HW_MODEL == 120 )); then
				HW_MODEL_DESCRIPTION='Khadas VIM3 '
				IMAGE_ADDITIONAL_CREDITS='balbes150'

                                MEMTOTAL=$(free | awk '/^Mem:/{print $2}')
                                if (( $MEMTOTAL > 3000000 )); then
					HW_MODEL_DESCRIPTION+='Pro'
                                        HW_MODEL=121
                                else
					HW_MODEL_DESCRIPTION+='Basic'
                                fi

			#ASUS Tinker Board
			elif (( $HW_MODEL == 100 )); then

				HW_MODEL_DESCRIPTION='ASUS Tinker Board'

                                # See if this happens to be an S model
                                # Do so by seeing if eMMC drive exists (since it is built in to the S)
# Work in progress. Won't work like this because Tinker Board treats SD card as mmcblk. Need to test on an S to figure out a means of distinguishing between them.
#                                for f in /dev/mmcblk*; do
#                                  [ -e "$f" ] && HW_MODEL_DESCRIPTION='ASUS Tinker Board S' && HW_MODEL=101
#                                  break
#                                done

			#A20-OLinuXino-MICRO
			elif (( $HW_MODEL == 90 )); then

				HW_MODEL_DESCRIPTION='A20-OLinuXino-MICRO'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'

			#Cubieboard 3
			elif (( $HW_MODEL == 80 )); then

				HW_MODEL_DESCRIPTION='Cubieboard 3'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'

			#Sparky SBC
			elif (( $HW_MODEL == 79 )); then

				HW_MODEL_DESCRIPTION='Sparky SBC'


			# NanoPi NEO Plus2
			elif (( $HW_MODEL == 69 )); then

                                MEMTOTAL=$(free | awk '/^Mem:/{print $2}')
                                if (( $MEMTOTAL > 1000000 )); then

					HW_MODEL_DESCRIPTION='NanoPi NEO Plus2 (1 GB)'
                                        IMAGE_ADDITIONAL_CREDITS='ARMbian'
                                        HW_MODEL=69

                                else

					HW_MODEL_DESCRIPTION='NanoPi NEO Plus2 (512 MB)'
                                        IMAGE_ADDITIONAL_CREDITS='ARMbian'
                                        HW_MODEL=70

                                fi


			#NanoPi M4
			elif (( $HW_MODEL == 67 )); then

                                MEMTOTAL=$(free | awk '/^Mem:/{print $2}')
                                if (( $MEMTOTAL > 3900000 )); then

					HW_MODEL_DESCRIPTION='NanoPi M4 (4 GB)'
					IMAGE_ADDITIONAL_CREDITS='ARMbian'
					HW_CPUID=1
                                        HW_MODEL=68

                                else

					HW_MODEL_DESCRIPTION='NanoPi M4 (2 GB)'
					IMAGE_ADDITIONAL_CREDITS='ARMbian'
					HW_CPUID=1
                                        HW_MODEL=67

				fi

			#NanoPi M1 Plus
			elif (( $HW_MODEL == 66 )); then

				HW_MODEL_DESCRIPTION='NanoPi M1 Plus'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#NanoPi NEO 2
			elif (( $HW_MODEL == 65 )); then

				HW_MODEL_DESCRIPTION='NanoPi NEO 2'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=2

			#NanoPi NEO Air
			elif (( $HW_MODEL == 64 )); then

				HW_MODEL_DESCRIPTION='NanoPi NEO Air'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#NanoPi M1
			elif (( $HW_MODEL == 63 )); then

				HW_MODEL_DESCRIPTION='NanoPi M1/T1'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#NanoPi M3
			elif (( $HW_MODEL == 62 )); then

				HW_MODEL_DESCRIPTION='NanoPi M3/T3'

			#NanoPi M2
			elif (( $HW_MODEL == 61 )); then

				HW_MODEL_DESCRIPTION='NanoPi M2/T2'

			#NanoPi Neo
			elif (( $HW_MODEL == 60 )); then

				HW_MODEL_DESCRIPTION='NanoPi Neo'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#BananaPi M2+
			elif (( $HW_MODEL == 50 )); then

				HW_MODEL_DESCRIPTION='BananaPi M2+'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#BananaPi Pro
			elif (( $HW_MODEL == 51 )); then

				HW_MODEL_DESCRIPTION='BananaPi Pro'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'

			#Pine A64-LTS
			elif (( $HW_MODEL == 44 )); then

				HW_MODEL_DESCRIPTION='Pine A64-LTS/Sopine'
				IMAGE_ADDITIONAL_CREDITS='Longsleep, Ayufan'

			#Rock64
			elif  (( $HW_MODEL >= 45 && $HW_MODEL <= 47 )); then

				IMAGE_ADDITIONAL_CREDITS='Longsleep, Ayufan'

                                MEMTOTAL=$(free | awk '/^Mem:/{print $2}')
                                if (( $MEMTOTAL > 4000000 )); then

                                        HW_MODEL_DESCRIPTION='Rock64 4GB'
                                        HW_MODEL=47

                                elif (( $MEMTOTAL > 2000000 )); then

                                        HW_MODEL_DESCRIPTION='Rock64 2GB'
                                        HW_MODEL=46

                                else

                                        HW_MODEL_DESCRIPTION='Rock64 1GB'
                                        HW_MODEL=45

                                fi
				
			#RockPro64
			elif  (( $HW_MODEL >= 48 && $HW_MODEL <= 49 )); then

				IMAGE_ADDITIONAL_CREDITS='Longsleep, Ayufan'

                                MEMTOTAL=$(free | awk '/^Mem:/{print $2}')
                                if (( $MEMTOTAL > 3900000 )); then

                                        HW_MODEL_DESCRIPTION='RockPro64 4GB'
                                        HW_MODEL=49

                                else

                                        HW_MODEL_DESCRIPTION='RockPro64 2GB'
                                        HW_MODEL=48

                                fi


			#PineA64
			elif (( $HW_MODEL >= 40 && $HW_MODEL <= 42 )); then

				IMAGE_ADDITIONAL_CREDITS='Longsleep, Rhkean'

				MEMTOTAL=$(free | awk '/^Mem:/{print $2}')
				if (( $MEMTOTAL > 2000000 )); then

					HW_MODEL_DESCRIPTION='Pine A64+ 2GB'
					HW_MODEL=42

				elif (( $MEMTOTAL > 1000000 )); then

					HW_MODEL_DESCRIPTION='Pine A64+ 1GB'
					HW_MODEL=41

				else

					HW_MODEL_DESCRIPTION='Pine A64 512MB'
					HW_MODEL=40

				fi

			#OrangePi PC 2
			elif (( $HW_MODEL == 38 )); then

				HW_MODEL_DESCRIPTION='OPi PC2'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=2

			#OrangePi Prime
			elif (( $HW_MODEL == 37 )); then

				HW_MODEL_DESCRIPTION='OPi Prime'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=2

			#OrangePi Win
			elif (( $HW_MODEL == 36 )); then

				HW_MODEL_DESCRIPTION='OPi Win'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'

			#OrangePi Zero Plus 2 (h3/h5)
			elif (( $HW_MODEL == 35 )); then

				HW_MODEL_DESCRIPTION='OPi Zero 2 Plus'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#OrangePi Plus
			elif (( $HW_MODEL == 34 )); then

				HW_MODEL_DESCRIPTION='OrangePi Plus'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#OrangePi Lite
			elif (( $HW_MODEL == 33 )); then

				HW_MODEL_DESCRIPTION='OrangePi Lite'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#Orange Pi Zero
			elif (( $HW_MODEL == 32 )); then

				HW_MODEL_DESCRIPTION='Orange Pi Zero'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				#HW_CPUID=1 #H2+

			#OrangePi One
			elif (( $HW_MODEL == 31 )); then

				HW_MODEL_DESCRIPTION='OrangePi One'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#OrangePi Pc
			elif (( $HW_MODEL == 30 )); then

				HW_MODEL_DESCRIPTION='OrangePi PC'
				IMAGE_ADDITIONAL_CREDITS='ARMbian'
				HW_CPUID=1

			#x86_64 native PC
			elif (( $HW_MODEL == 29 )); then

				HW_MODEL_DESCRIPTION='Native PC'


			#Amazon Web Services
			elif (( $HW_MODEL == 22 )); then

				HW_MODEL_DESCRIPTION='Amazon Web Services'

			#Docker Container
			elif (( $HW_MODEL == 21 )); then

				HW_MODEL_DESCRIPTION='Docker'

			#VM
			elif (( $HW_MODEL == 20 )); then

				HW_MODEL_DESCRIPTION='Virtual Machine'

			#oDroid U3
			elif (( $HW_MODEL == 13 )); then

				HW_MODEL_DESCRIPTION='ODROID U3'
				#IMAGE_ADDITIONAL_CREDITS='Meveric'

			elif (( $HW_MODEL == 12 )); then

				HW_MODEL_DESCRIPTION='ODROID C2'
				IMAGE_ADDITIONAL_CREDITS='Meveric'

				#oDroid XU3/4 via /etc/.dietpi_hw_model
			elif (( $HW_MODEL == 11 )); then

				HW_MODEL_DESCRIPTION='ODROID XU3/XU4/HC1/HC2'
				IMAGE_ADDITIONAL_CREDITS='Meveric'

			#ODROID-N2
			elif (( $HW_MODEL == 15 )); then

				MEMTOTAL=$(free | awk '/^Mem:/{print $2}')
				if (( $MEMTOTAL > 3800000 )); then

					HW_MODEL_DESCRIPTION='ODROID-N2 (4 GB)'
					HW_MODEL=16
					
				else
				
					HW_MODEL_DESCRIPTION='ODROID-N2 (2 GB)'
					IMAGE_ADDITIONAL_CREDITS='Meveric'
					
				fi

			# Logic Supply CL100
			elif (( $HW_MODEL >= 98010 && $HW_MODEL <= 98019 )); then

				MEMTOTAL=$(free | awk '/^Mem:/{print $2}')
				if (( $MEMTOTAL > 7000000 )); then

					HW_MODEL_DESCRIPTION='Logic Supply CL100 (8GB RAM)'
					HW_MODEL=98010

				elif (( $MEMTOTAL > 3000000 )); then

					HW_MODEL_DESCRIPTION='Logic Supply CL100 (4GB RAM)'
					HW_MODEL=98011

				else

					HW_MODEL_DESCRIPTION='Logic Supply CL100 (2GB RAM)'
					HW_MODEL=98012

				fi


			fi

		#RPi
		elif (( $(cat /etc/os-release | grep -ci -m1 '^ID=raspbian') )); then

			#Grab hardware description from rpi_boardinfo
			RPi_BoardInfo

		#oDroid C2
		elif (( $(cat /proc/cpuinfo | grep -ci -m1 'ODROID-C2') )); then

			HW_MODEL_DESCRIPTION='ODROID C2'
			HW_MODEL=12
			IMAGE_ADDITIONAL_CREDITS='Meveric'

		#oDroid XU3/4
		elif (( $(cat /proc/cpuinfo | grep -ci -m1 'ODROID-XU3') )); then

			HW_MODEL_DESCRIPTION='ODROID XU3/4'
			HW_MODEL=11
			IMAGE_ADDITIONAL_CREDITS='Meveric'

		#oDroid C1
		elif (( $(cat /proc/cpuinfo | grep -ci -m1 'ODROIDC') )); then

			HW_MODEL_DESCRIPTION='ODROID C1'
			HW_MODEL=10
			IMAGE_ADDITIONAL_CREDITS='Meveric'

		fi

		#Get Distro Index (assumes jessie)
		if (( $( cat /etc/*release | grep -ci -m1 'jessie') )); then

			DISTRO=3

		elif (( $( cat /etc/*release | grep -ci -m1 'stretch') )); then

			DISTRO=4

		fi

		#Generate UUID if it doesnt not exist
		if [ ! -f /DietPi/dietpi/.hw_model ]; then

			HW_UUID=$(cat /proc/sys/kernel/random/uuid)

		else

			HW_UUID=$(sed -n 5p /DietPi/dietpi/.hw_model)

		fi

		#Obtain hardware cpu architecture
		HW_ARCH_DESCRIPTION=$(uname -m)
		if [ "$HW_ARCH_DESCRIPTION" = "armv6l" ]; then

			HW_ARCH=1

		elif [ "$HW_ARCH_DESCRIPTION" = "armv7l" ]; then

			HW_ARCH=2

		elif [ "$HW_ARCH_DESCRIPTION" = "aarch64" ]; then

			HW_ARCH=3

		elif [ "$HW_ARCH_DESCRIPTION" = "x86_64" ]; then

			HW_ARCH=10

		# - Unknown arch for DietPi, inform user by adding 'unknown'.
		else

			HW_ARCH_DESCRIPTION+=' (Unknown)'

		fi

		# - Add HW arch to HW desc
#		HW_MODEL_DESCRIPTION+=" ($HW_ARCH_DESCRIPTION)"

		#Save data
		cat << _EOF_ > /var/log/nems/hw_model
$HW_MODEL
$HW_MODEL_DESCRIPTION
$DISTRO
$ROOTFS_DEVICE_PATH
$HW_UUID
$HW_ARCH
$HW_ARCH_DESCRIPTION
$IMAGE_ADDITIONAL_CREDITS
$HW_CPUID
$HW_ONBOARD_WIFI
$HW_REVISION_CODE
$HW_RELEASE_DATE
$HW_PCB_REVISION_CODE
$HW_MEMORY_SIZE
$HW_MANUFACTURER_NAME
_EOF_

	}

	#-----------------------------------------------------------------------------------
	#Main
	Obtain_HW_Info
	#-----------------------------------------------------------------------------------
	exit
	#-----------------------------------------------------------------------------------
}
