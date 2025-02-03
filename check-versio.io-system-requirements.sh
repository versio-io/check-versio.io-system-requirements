#!/bin/bash
# set -e

echo "                    _             _        "
echo "__   _____ _ __ ___(_) ___       (_) ___   "
echo "\ \ / / _ \ '__/ __| |/ _ \      | |/ _ \  "
echo " \ V /  __/ |  \__ \ | (_) |  _  | | (_) | "
echo "  \_/ \___|_|  |___/_|\___/  (_) |_|\___/  "
echo "                                           "
echo ""
echo "QMETHODS - Business & IT Consulting GmbH"
echo "Copyright (C) | All rights reserved."
echo "-----------------------------------------------"
echo ""

echo -e "\n[versio.io] Check Versio.io system requirements"
echo "==============================================="
export ERROR=0
export WARNING=0
export WGET=0
export CURL=0

if [ "$EUID" -ne 0 ];  then 
	echo -e "\033[41m Please run the script as a root user. \033[0m"
	echo ""
	exit 1;
fi
echo ""

# ==================================================================
# Verify operating system
# ==================================================================
echo -e "\n[versio.io] Check operating system support"
WHICH_OS=$(cat /etc/*release | grep ^NAME)
if [ "$WHICH_OS" = "NAME=\"Fedora Linux\"" ]; then
     echo -e "\t\033[42mSupported operating system.\033[0m"
     echo -e "\tOS: Fedora"
elif [ "$WHICH_OS" = "NAME=\"Ubuntu\"" ]; then
	echo -e "\t\033[42mSupported operating system.\033[0m"
	echo -e "\tOS: Ubuntu"
elif [ "$WHICH_OS" = "NAME=\"Red Hat Enterprise Linux Server\"" ]; then
	echo -e "\t\033[42mSupported operating system.\033[0m"
	echo -e "\tOS: Red Hat Enterprise Linux"
elif [ "$WHICH_OS" = "NAME=\"Red Hat Enterprise Linux\"" ]; then
	echo -e "\t\033[42mSupported operating system.\033[0m"
	echo -e "\tOS: Red Hat Enterprise Linux"
elif [ "$WHICH_OS" = "NAME=\"Debian GNU/Linux\"" ]; then
	echo -e "\t\033[42mSupported operating system.\033[0m"
	echo -e "\tOS: Debian"
elif [ "$WHICH_OS" = "NAME=\"AlmaLinux\"" ]; then
	echo -e "\t\033[42mSupported operating system.\033[0m"
	echo -e "\tOS: AlmaLinux"
else
    echo -e "\t\033[30m\033[43m Unsupported operating system. \033[0m"  
    echo -e "\tLinux expertise is necessary to run the Versio.io platform"  
	echo -e "\tOS: $WHICH_OS"
	export WARNING=1
fi

# ==================================================================
# Verify IPv6 support
# ==================================================================
echo -e "\n[versio.io] Check IPv6 support"
IPV6=$(cat /sys/module/ipv6/parameters/disable)
if [ "$IPV6" = "0" ]; then
     echo -e "\t\033[42m IPv6 supported available. \033[0m"
else
    echo -e "\t\033[30m\033[43m IPv6 support unavailable. \033[0m"  
    echo -e "\tPlease activate IPv6 support!"  
	export WARNING=1
fi

# ============================================
# Verify OS commands available
# ============================================
echo -e "\n[versio.io] Check if the required commands for installation are available"
for command in \
		tar \
		gzip \
		awk \
		wget \
		openssl \
		grep \
		curl \
		ss \
		which \
		systemctl \
		sysbench \
		pv \
		chpasswd \
		jq
do
	echo -e "\tCheck command '$command':"
	IS_INSTALLED=$(which $command 2>/dev/null| wc -l)
	if [ "$IS_INSTALLED" = "1" ]; then
		echo -e "\t\t\033[42m Available. \033[0m"
		if [ "$command" = "curl" ]; then 
			export CURL=1
		elif [ "$command" = "wget" ]; then 
			export WGET=1
		fi
	else
		echo -e "\t\t\033[41m Not installed \033[0m"  
		echo -e "\t\tPlease install app (apt/yum/dnf install $command)"  
		export ERROR=1
	fi
done

# ============================================
# Verify that podman is NOT installed
# ============================================
echo -e "\n[versio.io] Check if unsupported podman installation is available"
IS_PODMAN_INSTALLED=$(which podman 2> /dev/null | grep -c "podman")
if [ "$IS_PODMAN_INSTALLED" = "1" ]; then
	echo -e "\t\033[41m Available \033[0m"
	echo -e "\t"$(podman --version)
	export ERROR=1
else
    echo -e "\t\033[42m Podman is not installed \033[0m"  
fi

# ============================================
# Verify docker is installed
# ============================================
echo -e "\n[versio.io] Check if docker installation is available"
IS_DOCKER_INSTALLED=$(which docker 2> /dev/null | grep -c "docker")
if [ "$IS_DOCKER_INSTALLED" = "1" ]; then
	echo -e "\t\033[42m Available \033[0m"
	echo -e "\t"$(docker --version)
else
    echo -e "\t\033[41m Not installed \033[0m"  
	export ERROR=1
fi


# ============================================
# Verify docker daemon is running
# ============================================
echo -e "\n[versio.io] Check if docker daemon is not running"
IS_DOCKER_DAEMON_RUNNING=$(systemctl status docker 2> /dev/null | grep "Active: active (running)" | wc -l)
if [ "$IS_DOCKER_DAEMON_RUNNING" = "1" ]; then
	echo -e "\t\033[42m Running \033[0m"
else
    echo -e "\t\033[41m Not runningd \033[0m"  
	echo -e "\tTry to start with: systemctl start docker"  
	export ERROR=1
fi


# ============================================
# Verify docker-compose is installed
# ============================================
# echo -e "\n[versio.io] Check if docker composed installation is available"
# IS_DOCKER_COMPOSER_INSTALLED=$(which docker-compose 2> /dev/null | grep -c "docker-compose")
# if [ "$IS_DOCKER_COMPOSER_INSTALLED" = "1" ]; then
# 	echo -e "\t\033[42mAvailable\033[0m"
# 	echo -e "\t"$(docker-compose --version)
# else
#     echo -e "\t\033[41mNot installed\033[0m"  
# 	export ERROR=1
# fi

# ============================================
# Verify that no anti virus program or other blocker are running
# ============================================
# McAfee: ds_agent,ds_am, dsvp
echo -e "\n[versio.io] Check if a McAfee virus app is running"
for app in \
	ds-agent \
	ds-am, \
	dsvp
do
	echo -e "\tApplication: $app"
	IS_AGENT_DETECTED=$(ps -ef | grep -c $app)
	if [ "$IS_AGENT_DETECTED" = "1" ]; then
		echo -e "\t\t\033[42m No virus app is running \033[0m"
	else
    	echo -e "\t\t\033[30m\033[43m Virus app is running \033[0m"  
    	echo -e "\t\tVirus can affect the functionality of Versio.io "  
		export WARNING=1
	fi
done

# ============================================
# Verify that port 80 and port 443 are not used (blocked)
# ============================================
echo -e "\n[versio.io] Check if needed ports are not used"
echo -e "\tPort 80 (HTTP)"
IS_USED=$(ss -lntu  | grep -c ":80 ")
if [ "$IS_USED" = "0" ]; then 
	echo -e "\t\t\033[42m Not used \033[0m"
else
    echo -e "\t\t\033[41m Port is in use \033[0m"  
    echo -e "\t\tPlease stop the process that use port 80"  
	export ERROR=1
fi
echo -e "\tPort 443 (HTTPS)"
IS_USED=$(ss -lntu | grep -c ":443 ")
if [ "$IS_USED" = "0" ]; then
	echo -e "\t\t\033[42m Not used \033[0m"
else
    echo -e "\t\t\033[41m Port is in use \033[0m"  
    echo -e "\t\tPlease stop the process that use port 443"  
	export ERROR=1
fi

# ============================================
# Verify external URLs are reachable
# ============================================
echo -e "\n[versio.io] Check if network connection to Versio.io online services are available"
for domain in \
	https://live.versio.io \
	https://api.versio.io/gov/1.0/vendors \
	https://registry.versio.io
do
	if [ "$WGET" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with wget."
		PING_RESULT=$(wget -q -O -S --spider --timeout=5 $domain | echo $?)
		if [ "$PING_RESULT" = "0" ]; then
			echo -e "\t\t\033[42m Available. \033[0m"
		else
			echo -e "\t\t\033[30m\033[43m Not available. \033[0m"
			echo -e "\t\tOnly restricted service available."
			WARNING=1
		fi
	elif [ "$CURL" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with curl."
		PING_RESULT=$(curl -Is  $domain | head -n 1 | grep -e 200 -e 401 | wc -l)
		if [ "$PING_RESULT" = "1" ]; then
			echo -e "\t\t\033[42m Available. \033[0m"
		else
			echo -e "\t\t\033[30m\033[43m Not available. \033[0m"
			echo -e "\t\tOnly restricted service available."
			WARNING=1
		fi
	else
		echo -e "\tCheck network connection to '$domain'."
		echo -e "\t\t\033[30m\033[43m No command to check URL connection available. \033[0m"
	fi
done



# ==========================================--max-time=5=======
# Verify hardware vendor warranty API are reachable
# =================================================
echo -e "\n[versio.io] Check if warranty APIs of hardware vendors are available"
for domain in \
	https://apigtwb2c.us.dell.com \
	https://supporttickets.intel.com \
	http://supportapi.lenovo.com
do
	if [ "$WGET" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with wget."
		PING_RESULT=$(wget -q -O -S --spider --timeout=5 $domain | echo $?)
		if [ "$PING_RESULT" = "0" ]; then
			echo -e "\t\t\033[42m Available. \033[0m"
		else
			echo -e "\t\t\033[30m\033[43m Not available. \033[0m"
			echo -e "\t\tWarranty information for servers, workstations and laptops cannot be determined."
			WARNING=1
		fi
	elif [ "$CURL" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with curl."
		PING_RESULT=$(curl -Is --max-time=5 $domain | head -n 1 | grep -e 200 -e 401 | wc -l)
		if [ "$PING_RESULT" = "1" ]; then
			echo -e "\t\t\033[42m Available. \033[0m"
		else
			echo -e "\t\t\033[30m\033[43m Not available. \033[0m"
			echo -e "\t\tWarranty information for servers, workstations and laptops cannot be determined."
			WARNING=1
		fi
	else
		echo -e "\tCheck network connection to '$domain'."
		echo -e "\t\t\033[30m\033[43m No command to check vendor warranty API connection available. \033[0m"
	fi
done


# ============================================
# Check system performance
# ============================================
echo "[versio.io] Start system performance benchmark ..."

IS_INSTALLED=$(which sysbench 2>/dev/null| wc -l)
if [ "$IS_INSTALLED" = "1" ]; then

	# CPU benchmark
	echo -e "\tStart CPU benchmark ..."
	cpu_result=$(sysbench cpu --cpu-max-prime=20000 run | grep "events per second:" | awk '{print $4}')
	echo -e "\t\tEvents per seconds: $cpu_result"

	# Assessment of the result
	if (( $(echo "$cpu_result > 1200" | bc -l) )); then
	echo -e "\t\t\033[42m Very good CPU performance \033[0m"
	elif (( $(echo "$cpu_result > 500" | bc -l) )); then
	echo -e "\t\t\033[30m\033[43m Average CPU performance \033[0m"
	WARNING=1
	else
	echo -e "\t\t\033[41m Inadequate CPU performance \033[0m"
	ERROR=1
	fi



	# Memory benchmark
	echo -e "\tStart memory benchmark ..."
	memory_result=$(sysbench memory --memory-total-size=5G run | grep "transferred" | awk '{print $4}' | sed 's/(//g')
	echo -e "\t\tTotal time: $memory_result MiB/sec"

	# Assessment of the result
	if (( $(echo "$memory_result > 6000" | bc -l) )); then
	echo -e "\t\t\033[42mVery good memory performance \033[0m"
	elif (( $(echo "$memory_result > 4000" | bc -l) )); then
	echo -e "\t\t\033[30m\033[43m Average memory performance \033[0m"
	WARNING=1
	else
	echo -e "\t\t\033[41m Inadequate memory performance \033[0m"
	ERROR=1
	fi


	# Disk IO benchmark
	echo -e "\tStart disk I/O benchmark ..."
	disk_result=$(dd if=/dev/zero of=tempfile bs=1M count=1024 conv=fdatasync 2>&1 | grep "MB/s" | awk '{print $(NF-1)}')
	echo -e "\t\tTotal time: $disk_result MB/s"

	# Assessment of the result
	if (( $(echo "$disk_result > 600" | bc -l) )); then
	echo -e "\t\t\033[42mVery good disk I/O performance \033[0m"
	elif (( $(echo "$disk_result > 300" | bc -l) )); then
	echo -e "\t\t\033[30m\033[43m Average disk I/O performance \033[0m"
	WARNING=1
	else
	echo -e "\t\t\033[41m Inadequate disk I/O performance \033[0m"
	ERROR=1
	fi
else
	echo -e "\t\033[30m\033[43m Can't execute benchmark because command 'sysbench' is not available! \033[0m"
	export WARNING=1
fi


# ============================================
# Final result
# ============================================
echo -e "\n==================================================="
echo -e "\n[versio.io] System requirements verification result"
echo -e "\n==================================================="
if [ "$WARNING" = "1" ]; then
	echo -e "\t\033[30m\033[43m There are active warning! \033[0m"
    echo -e "\tYou must have the knowledge to handle it."
fi
if [ "$ERROR" = "0" ]; then
	echo -e "\t\033[42m System requirements are fulfilled. You are ready to install and start Versio.io Managed plattform! \033[0m"
    echo -e "\tYou are ready to customize configuration and start Versio.io platform. See manual at https://doc.versio.io/setup-managed"
	echo ""
else
    echo -e "\t\033[41m System requirements are not fulfilled to install Versio.io Managed platform. \033[0m"  
    echo -e "\tPlease read more about system requirements in Versio.io manual at https://doc.versio.io/setup-system-requirements"
	echo ""
	exit 1;
fi


exit 0;