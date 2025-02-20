#!/bin/bash

# Set text colors for output messages
RED='\033[41m'
GREEN='\033[42m'
YELLOW='\033[30m\033[43m'
BLUE='\033[1;34m'
NC='\033[0m' # No color

# Splash screen
echo " "
echo -e "${BLUE}"
cat <<'EOF' 
                    _             _
__   _____ _ __ ___(_) ___       (_) ___
\ \ / / _ \ '__/ __| |/ _ \      | |/ _ \
 \ V /  __/ |  \__ \ | (_) |  _  | | (_) |
  \_/ \___|_|  |___/_|\___/  (_) |_|\___/
EOF
echo -e "${NC}"
echo -e " "
echo -e "QMETHODS - Business & IT Consulting GmbH"
echo -e "Copyright (C) | All rights reserved."
echo -e " "
echo -e "========================================================"
echo -e "Verify system requirements to operate Versio.io platform"
echo -e "========================================================"
echo ""
if [ "$EUID" -ne 0 ];  then 
	echo -e "${RED} Please run the script as a root user or with sudo rights. ${NC}"
	echo ""
	exit 1;
fi

# Set controls
ERROR=0
WARNING=0
WGET=0
CURL=0

# ==================================================================
# Verify operating system
# ==================================================================
echo -e "\n[versio.io] Check operating system support"
WHICH_OS=$(cat /etc/*release | grep ^NAME)
if [ "$WHICH_OS" = "NAME=\"Fedora Linux\"" ]; then
     echo -e "\t${GREEN} Supported operating system. ${NC}"
     echo -e "\tOS: Fedora"
elif [ "$WHICH_OS" = "NAME=\"Ubuntu\"" ]; then
	echo -e "\t${GREEN} Supported operating system. ${NC}"
	echo -e "\tOS: Ubuntu"
elif [ "$WHICH_OS" = "NAME=\"Red Hat Enterprise Linux Server\"" ]; then
	echo -e "\t${GREEN} Supported operating system. ${NC}"
	echo -e "\tOS: Red Hat Enterprise Linux"
elif [ "$WHICH_OS" = "NAME=\"Red Hat Enterprise Linux\"" ]; then
	echo -e "\t${GREEN} Supported operating system. ${NC}"
	echo -e "\tOS: Red Hat Enterprise Linux"
elif [ "$WHICH_OS" = "NAME=\"Debian GNU/Linux\"" ]; then
	echo -e "\t${GREEN} Supported operating system. ${NC}"
	echo -e "\tOS: Debian"
elif [ "$WHICH_OS" = "NAME=\"AlmaLinux\"" ]; then
	echo -e "\t${GREEN} Supported operating system. ${NC}"
	echo -e "\tOS: AlmaLinux"
else
    echo -e "\t${YELLOW} Unsupported operating system. ${NC}"  
    echo -e "\tLinux expertise is necessary to run the Versio.io platform"  
	echo -e "\tOS: $WHICH_OS"
	WARNING=1
fi

# ==================================================================
# Verify IPv6 support
# ==================================================================
echo -e "\n[versio.io] Check IPv6 support"
IPV6=$(cat /sys/module/ipv6/parameters/disable)
if [ "$IPV6" = "0" ]; then
     echo -e "\t${GREEN} IPv6 supported available. ${NC}"
else
    echo -e "\t${YELLOW} IPv6 support unavailable. ${NC}"  
    echo -e "\tPlease activate IPv6 support!"  
	WARNING=1
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
		echo -e "\t\t${GREEN} Available. ${NC}"
		if [ "$command" = "curl" ]; then 
			CURL=1
		elif [ "$command" = "wget" ]; then 
			WGET=1
		fi
	else
		echo -e "\t\t${RED} Not installed ${NC}"  
		echo -e "\t\tPlease install app (apt/yum/dnf install $command)"  
		ERROR=1
	fi
done


# ============================================
# Verify if firewalld is active
# ============================================
echo -e "\n[versio.io] Check if firewalld is active"
IS_FIREWALLD_ACTIVE=$(systemctl is-active firewalld)
if [ "$IS_FIREWALLD_ACTIVE" = "active" ]; then
    echo -e "\t\t${YELLOW} firewalld is active - Please check whether the firewall rules are preventing the Versio.io platform from running! ${NC}"  
	WARNING=1
else
    echo -e "\t${GREEN} firewalld is not active ${NC}"  
fi


# ============================================
# Verify docker Podman installation
# ============================================
echo -e "\n[versio.io] Check container runtime environment"
VERSIO_CONTAINER_PLATTFORM=unknown
echo -e "\tCheck if Docker available"
IS_DOCKER_INSTALLED=$(which docker | grep -c "docker")
if [ "$IS_DOCKER_INSTALLED" = "1" ]; then
	echo -e "\t\t${GREEN} Available ${NC}"
	echo -e "\t\t$(docker --version)"
	VERSIO_CONTAINER_PLATTFORM=docker
else
    echo -e "\t${RED} Not installed ${NC}"  
	ERROR=1
fi

echo -e "\tCheck if Podman is available"
if which podman > /dev/null 2>&1; then
	echo -e "\t\t${GREEN} Available ${NC}"
	echo -e "\t\t$(podman --version)"
	VERSIO_CONTAINER_PLATTFORM=podman
else
	echo -e "\t\tNot available"
fi


# ============================================
# Podman configuration check
# ============================================
if [ "$VERSIO_CONTAINER_PLATTFORM" = "podman" ]; then
	echo "\n[versio.io] Podman specific checks"
	echo -e "\tCheck if user versio is authorized to execute Podman"
	echo -e "\t\tCheck configuration file /etc/subuid"
	if grep -q "versio:100000:65536" "/etc/subuid"; then
		echo -e "\t\t\t${GREEN} Authorisation available ${NC}"
	else
		echo -e "\t\t\t${RED} Authorisation not available ${NC}"
		echo -e "\t\t\tFix it: echo \"versio:100000:65536\" | sudo tee -a /etc/subuid"
		ERROR=1
	fi
	echo -e "\t\tCheck configuration file /etc/subgid"
	if grep -q "versio:100000:65536" "/etc/subgid"; then
		echo -e "\t\t\t${GREEN} Authorisation available ${NC}"
	else
		echo -e "\t\t\t${RED} Authorisation not available ${NC}"
		echo -e "\t\t\tFix it: echo \"versio:100000:65536\" | sudo tee -a /etc/subgid"
		ERROR=1
	fi


	# MS: Should not be important for Versio.io operations 
	# echo -e "\tCheck if container registry is set to Docker"
	# echo -e "\t\tCheck configuration file /etc/containers/registries.conf"
	# if grep -q 'unqualified-search-registries = \["docker.io"\]' '/etc/containers/registries.conf'; then
	# 	echo -e "\t\t\t${GREEN} Docker registry is set ${NC}"
	# else
	# 	echo -e "\t\t\t${RED} Docker registry is not set ${NC}"
	# 	echo -e "\t\t\tFix it: echo Restrict line "unqualified-search-registries" with ['docker.io'] in file /etc/containers/registries.conf"
	# fi


	echo -e "\tPrefend messages for emulated Docker commands"
	if [ -f "/etc/containers/nodocker" ]; then
		echo -e "\t\t${GREEN} Configuration file /etc/containers/nodocker exists ${NC}"
	else
		echo -e "\t\t${YELLOW} Configuration file /etc/containers/nodocker does not exist ${NC}"
		echo -e "\t\tFix it: sudo touch /etc/containers/nodocker; sudo chmod 644 /etc/containers/nodocker"
		WARNING=1
	fi


	echo -e "\tCheck if Podman has access to Cgroup-Manager service"
	USER_ID=$(id -u versio)
	if loginctl show-user "$USER_ID" --property=Linger | grep -q "Linger=yes"; then
		echo -e "\t\t${GREEN} Lingering is active for user $USER_ID ${NC}"
	else
		echo -e "\t\t${RED} Lingering is not active for user $USER_ID ${NC}"
		echo -e "\t\tFix it: sudo loginctl enable-linger $(id -u versio)"
		ERROR=1
	fi


	echo -e "\tCheck if it is allowed to use Versio.io default ports"
	if grep -q "net.ipv4.ip_unprivileged_port_start=80" "/etc/sysctl.conf"; then
		echo -e "\t\t${GREEN} Configuration is set ${NC}"
	else
		echo -e "\t\t${YELLOW} Configuration is not set ${NC}"
		echo -e "\t\tFix it: sudo echo "net.ipv4.ip_unprivileged_port_start=80" | tee -a /etc/sysctl.conf; sysctl -p"
		WARNING=1
	fi


	echo -e "\tCheck SELinux state"
	if [ "$(getenforce)" == "Permissive" ]; then
		echo -e "\t\t${GREEN} SWLinux is running in permissive mode ${NC}"
	else
		echo -e "\t\t${RED} SWLinux is not running in permissive mode ${NC}"
		echo -e "\t\tVersio.io does not yet support SELinux"
		echo -e "\t\tFix it: sudo setenforce 0"
		ERROR=1
	fi
fi

# ============================================
# Verify docker daemon is running
# ============================================
if [ "$VERSIO_CONTAINER_PLATTFORM" = "docker" ]; then
	echo -e "\n[versio.io] Check if docker daemon is running"
	IS_DOCKER_DAEMON_RUNNING=$(systemctl status docker 2> /dev/null | grep "Active: active (running)" | wc -l)
	if [ "$IS_DOCKER_DAEMON_RUNNING" = "1" ]; then
		echo -e "\t${GREEN} Docker daemon is running ${NC}"
	else
		echo -e "\t${RED} Docker daemon is not running ${NC}"  
		echo -e "\tTry to start with: systemctl start docker"  
		ERROR=1
	fi
fi

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
		echo -e "\t\t${GREEN} No virus app is running ${NC}"
	else
    	echo -e "\t\t${YELLOW} Virus app is running ${NC}"  
    	echo -e "\t\tVirus can affect the functionality of Versio.io "  
		WARNING=1
	fi
done

# ============================================
# Verify that port 80 and port 443 are not used (blocked)
# ============================================
echo -e "\n[versio.io] Check if needed ports are not used"
echo -e "\tPort 80 (HTTP)"
IS_USED=$(ss -lntu  | grep -c ":80 ")
if [ "$IS_USED" = "0" ]; then 
	echo -e "\t\t${GREEN} Not used ${NC}"
else
    echo -e "\t\t${RED} Port is in use ${NC}"  
    echo -e "\t\tPlease stop the process that use port 80"  
	ERROR=1
fi
echo -e "\tPort 443 (HTTPS)"
IS_USED=$(ss -lntu | grep -c ":443 ")
if [ "$IS_USED" = "0" ]; then
	echo -e "\t\t${GREEN} Not used ${NC}"
else
    echo -e "\t\t${RED} Port is in use ${NC}"  
    echo -e "\t\tPlease stop the process that use port 443"  
	ERROR=1
fi


# ============================================
# Verify that enough storage space is available
# ============================================
echo -e "\n[versio.io] Check whether there is enough storage space available"
VERSIO_DEPLOYMENT_PROFILE=${VERSIO_DEPLOYMENT_PROFILE:-standalone}
totalStorageSpace=$(df --output=size -BG / | tail -n 1 | tr -d ' G')
availableStorageSpace=$(df --output=avail -BG / | tail -n 1 | tr -d ' G')
echo -e "\tDeployment profile: $VERSIO_DEPLOYMENT_PROFILE"
echo -e "\tTotal storage space: $totalStorageSpace GB"
echo -e "\tAvailable storage space: $availableStorageSpace GB"

VERSIO_DATA=${VERSIO_DATA:-/home/versio.io}
if [ -d "$VERSIO_DATA" ]; then
	usedVersioStorageSpace=$(du -s --block-size=1G $VERSIO_DATA | cut -f1)
	echo -e "\tUsed storage: $usedVersioStorageSpace GB in folder $VERSIO_DATA"
fi

if [[ "$VERSIO_DEPLOYMENT_PROFILE" == "database" || "$VERSIO_DEPLOYMENT_PROFILE" == "application" ]]; then
	if [ "$availableStorageSpace" -ge 150 ]; then
		echo -e "\t${GREEN} At least 150 GiB are available ${NC}"
	else
		echo -e "\t${YELLOW} At least 150 GiB must be available for a new installation ${NC}"
		WARNING=1
	fi
else
	if [ "$availableStorageSpace" -ge 300 ]; then
		echo -e "\t${GREEN} At least 300 GiB are available ${NC}"
	else
		echo -e "\t${YELLOW} At least 300 GiB must be available for a new installation ${NC}"
		WARNING=1
	fi
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
		echo -e "\tCheck network connection to '$domain' with WGET."
		PING_RESULT=$(wget -q -O -S --spider --timeout=5 $domain | echo $?)
		if [ "$PING_RESULT" = "0" ]; then
			echo -e "\t\t${GREEN} Available. ${NC}"
		else
			echo -e "\t\t${RED}\033[43m Not available. ${NC}"
			echo -e "\t\tOnly restricted service available."
			ERROR=1
		fi
	elif [ "$CURL" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with CURL."
		PING_RESULT=$(curl -Is  --max-time 5 $domain | head -n 1 | grep -e 200 -e 401 | wc -l)
		if [ "$PING_RESULT" = "1" ]; then
			echo -e "\t\t${GREEN} Available. ${NC}"
		else
			echo -e "\t\t${RED}\033[43m Not available. ${NC}"
			echo -e "\t\tOnly restricted service available."
			ERROR=1
		fi
	else
		echo -e "\tCheck network connection to '$domain'."
		echo -e "\t\t${YELLOW} No command to check URL connection available. ${NC}"
	fi
done



# =================================================
# Verify hardware vendor warranty API are reachable
# =================================================
echo -e "\n[versio.io] Check if warranty APIs of hardware vendors are available"
for domain in \
	https://apigtwb2c.us.dell.com \
	https://supporttickets.intel.com \
	http://supportapi.lenovo.com
do
	if [ "$WGET" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with WGET."
		PING_RESULT=$(wget -q -O -S --spider --timeout=5 $domain | echo $?)
		if [ "$PING_RESULT" = "0" ]; then
			echo -e "\t\t${GREEN} Available. ${NC}"
		else
			echo -e "\t\t${YELLOW} Not available. ${NC}"
			echo -e "\t\tWarranty information for servers, workstations and laptops cannot be determined."
			WARNING=1
		fi
	elif [ "$CURL" = "1" ]; then
		echo -e "\tCheck network connection to '$domain' with CURL."
		PING_RESULT=$(curl -Is --max-time 5 $domain | head -n 1 | grep -e 200 -e 401 | wc -l)
		if [ "$PING_RESULT" = "1" ]; then
			echo -e "\t\t${GREEN} Available. ${NC}"
		else
			echo -e "\t\t${YELLOW} Not available. ${NC}"
			echo -e "\t\tWarranty information for servers, workstations and laptops cannot be determined."
			WARNING=1
		fi
	else
		echo -e "\tCheck network connection to '$domain'."
		echo -e "\t\t${YELLOW} No command to check vendor warranty API connection available. ${NC}"
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
		echo -e "\t\t${GREEN} Very good CPU performance ${NC}"
	elif (( $(echo "$cpu_result > 500" | bc -l) )); then
		echo -e "\t\t${YELLOW} Average CPU performance ${NC}"
		WARNING=1
	else
		echo -e "\t\t${RED} Inadequate CPU performance ${NC}"
		ERROR=1
	fi



	# Memory benchmark
	echo -e "\tStart memory benchmark ..."
	memory_result=$(sysbench memory --memory-total-size=5G run | grep "transferred" | awk '{print $4}' | sed 's/(//g')
	echo -e "\t\tTotal time: $memory_result MiB/sec"

	# Assessment of the result
	if (( $(echo "$memory_result > 6000" | bc -l) )); then
		echo -e "\t\t${GREEN} Very good memory performance ${NC}"
	elif (( $(echo "$memory_result > 4000" | bc -l) )); then
		echo -e "\t\t${YELLOW} Average memory performance ${NC}"
		WARNING=1
	else
		echo -e "\t\t${RED} Inadequate memory performance ${NC}"
		ERROR=1
	fi


	# Disk IO benchmark
	echo -e "\tStart disk I/O benchmark ..."
	disk_result=$(dd if=/dev/zero of=tempfile bs=1M count=1024 conv=fdatasync 2>&1 | grep "MB/s" | awk '{print $(NF-1)}')
	echo -e "\t\tTotal time: $disk_result MB/s"

	# Assessment of the result
	if (( $(echo "$disk_result > 600" | bc -l) )); then
		echo -e "\t\t${GREEN} Very good disk I/O performance ${NC}"
	elif (( $(echo "$disk_result > 300" | bc -l) )); then
		echo -e "\t\t${YELLOW} Average disk I/O performance ${NC}"
		WARNING=1
	else
		echo -e "\t\t${RED} Inadequate disk I/O performance ${NC}"
	ERROR=1
	fi
else
	echo -e "\t${YELLOW} Can't execute benchmark because command 'sysbench' is not available! ${NC}"
	WARNING=1
fi


# ============================================
# Final result
# ============================================
echo -e "\n==================================================="
echo -e "\n[versio.io] System requirements verification result"
echo -e "\n==================================================="
if [ "$WARNING" = "1" ]; then
	echo -e "\t${YELLOW} There are active warning! ${NC}"
    echo -e "\tYou must have the knowledge to handle it."
	echo ""
fi
if [ "$ERROR" = "0" ]; then
	echo -e "\t${GREEN} System requirements are fulfilled. You are ready to install and start Versio.io Managed plattform! ${NC}"
    echo -e "\tYou are ready to customize configuration and start Versio.io platform. See manual at https://doc.versio.io/setup-managed"
	echo ""
else
    echo -e "\t${RED} System requirements are not fulfilled to install Versio.io Managed platform. ${NC}"  
    echo -e "\tPlease read more about system requirements in Versio.io manual at https://doc.versio.io/setup-system-requirements"
	echo ""
	exit 1;
fi


exit 0