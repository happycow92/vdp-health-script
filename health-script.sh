#!/bin/bash
clear

echo -e "***************************************************************\n"
echo -e "           This Script Is Written By Suhas G Savkoor           \n"
echo -e "		        gsuhas@vmware.com			\n"
echo -e "***************************************************************\n"

RunUser='admin'
Currentuser=$(whoami)

if [ $RunUser != $Currentuser ]
then
	printf "\nRun the script as  admin. Exiting!\n\n"
else
#LOG LOCATIONS

sudo touch /home/admin/health-check.txt
sudo chmod 777 /home/admin/health-check.txt
exec > >(tee -a /home/admin/health-check.txt) 
exec 2>&1

G="\033[32m"
N="\033[0m"
R="\033[31m"
Y="\033[33m"

sudo chmod 755 /usr/local/vdr/etc/vcenterinfo.cfg
# Service Status Block

printf "\nPerforming VDP Service Checks"
while sleep 0.9; do printf "."; done &
sudo touch /home/admin/service-health.txt
sudo chmod 777 /home/admin/service-health.txt
sudo dpnctl status all &> /home/admin/service-health.txt
disown $! && kill $!
echo
echo
sudo chmod a+r /home/admin/service-health.txt

# GSAN Check
gsan=$(cat /home/admin/service-health.txt | grep -i gsan | cut -d ' ' -f 5)

if [ "$gsan" == "up" ]
then
        printf "${Y}GSAN${N} Service Status is\t\t |${G}UP${N}\n"
elif [ "$gsan" == "down" ]
then
        printf "${Y}GSAN${N} Service Status is\t\t |${R}DOWN${N}\n"
elif [ "$gsan" == "degraded" ]
then
        printf "${Y}GSAN${N} Service Status is\t\t |${R}DEGRADED${N}\n"
elif [ "$(cat /home/admin/service-health.txt | grep -i gsan | awk '{print $5,$6}')" == "not running" ]
then
	printf "${Y}GSAN${N} Service Status is\t\t |${R}NOT RUNNING${N}\n"
else
        printf "${Y}GSAN${N} Service Status is\t\t |${R}UNRESPONSIVE${N}\n"
fi

# MCS Check

mcs=$(cat /home/admin/service-health.txt | grep -i mcs | cut -d ' ' -f 5 | tr . " ")

if [ "$mcs" == "up " ]
then
        printf "${Y}MCS${N} Service Status is\t\t |${G}UP${N}\n"
else
        printf "${Y}MCS${N} Service Status is\t\t |${R}DOWN${N}\n"
fi

# Tomcat check

emt=$(cat /home/admin/service-health.txt | grep -i emt | cut -d ' ' -f 5 | tr . " ")

if [ "$emt" == "up " ]
then
        printf "${Y}Tomcat${N} Service Status is\t |${G}UP${N}\n"
else
        printf "${Y}Tomcat${N} Service Status is\t |${R}DOWN${N}\n"
fi

# Scheduler Check

sched=$(cat /home/admin/service-health.txt | grep -i backup | cut -d ' ' -f 6 | tr . " ")
if [ "$sched" == "up " ]
then
        printf "${Y}Scheduler${N} Service Status is\t |${G}UP${N}\n"
else
        printf "${Y}Scheduler${N} Service Status is\t |${R}DOWN${N}\n"
fi

# Maintenance Check

maint=$(cat /home/admin/service-health.txt | grep -i maintenance | cut -d ' ' -f 7 | tr . " ")
if [ "$maint" == "enabled " ]
then
        printf "${Y}Maintenance${N} Service Status is\t |${G}UP${N}\n"
else
        printf "${Y}Maintenance${N} Service Status is\t |${R}SUSPENDED${N}\n"
fi

# Status.dpn check

sdpn=$(status.dpn | grep Access-Status | awk '{print $2}')
if [ "$sdpn" == "full" ]
then
	printf "VDP ${Y}Access State${N} is\t\t |${G}FULL${N}\n"
elif [ "$sdpn" == "admin" ]
then
	printf "VDP ${Y}Access State${N} is\t\t |${R}ADMIN${N}\n"
else
	printf "VDP ${Y}Access State${N} is\t\t |${R}READ ONLY${N}\n"
fi
	
# VDP Server Information.
echo

printf "VDP Server Information..........\n"

printf "\nThe ${Y}VDP FQDN${N} is\t\t\t |${G}$(hostname).$(cat /etc/resolv.conf | grep -i domain | cut -d ' ' -f 2)${N}"
printf "\nThe ${Y}VDP IP Address${N} is\t\t |${G}$(hostname -i)${N}"
printf "\nThe ${Y}VDP Version${N} is\t\t |${G}$(rpm -qa | grep vdr | cut -d '-' -f 3 | head -n 1)${N}"
printf "\nThe Core ${Y}Avamar Version${N} is\t |${G}$(status.dpn | grep -A 1 "Version" |tail -n 1 | awk -F "   " '{print $2}' | cut -d ' ' -f 2)${N}"
printf "\nThe configured ${Y}vCenter is${N}\t |${G}$(cat /usr/local/vdr/etc/vcenterinfo.cfg | grep -i vcenter-hostname | cut -d '=' -f 2)${N}"

vcenter_name=$(cat /usr/local/vdr/etc/vcenterinfo.cfg | grep -i vcenter-hostname | cut -d '=' -f 2)
sso_name=$(cat /usr/local/vdr/etc/vcenterinfo.cfg | grep -i vcenter-sso-hostname | cut -d '=' -f 2)

if [ "$vcenter_name" == "$sso_name" ]
then
	printf "\n${Y}SSO${N} deployment is\t\t |${G}Embedded${N}"
else
	printf "\n${Y}SSO${N} deployment is\t\t |${G}External${N}"
printf "\n${Y}SSO Hostname${N} is\t\t\t |${G}$sso_name${N}"
fi

printf "\nThe ${Y}Proxy Version${N} is\t\t |${G}$(avtar --version | grep -i version: | awk -F "     " '{print $2}' | head -n 1)${N}"
printf "\nThe ${Y}MCS Version${N} is\t\t |${G}$(mcserver.sh --version | awk '{print $2}' | head -n 1)${N}"
printf "\nThe ${Y}GSAN Version${N} is\t\t |${G}$(gsan --version | grep version | awk '{print $2}' | head -n 1)${N}"

printf "\nVDP ${Y}System ID${N} is\t\t |${G}$(avmaint config --ava | grep -i systemcreatetime | cut -d '=' -f 2 | sed 's/"//g')${N}"

proxy=$(mccli client show --recursive=true | grep -i /clients | awk '{print $1}')
proxy_number=$(mccli client show --recursive=true | grep -i /clients | awk '{print $1}' | wc -l)
hname=$(hostname).$(cat /etc/resolv.conf | grep -i domain | cut -d ' ' -f 2)

if [ "$proxy" != "$hname" ]
then
	printf "\nThe ${Y}Proxy${N} Used For This VDP is\t |${G}External${N}"
	if [ $proxy_number -ge 2 ]
	then
		proxy_output=$(mccli client show --recursive=true | grep -i /clients | awk '{print $1}' | tr '\n' ' ')
		printf "\nExternal Proxies available\t |${G}$proxy_output${N}"
	else
		printf "\nSingle External Proxy Available\t |${G}$proxy_output${N}"
	fi
else
	printf "\nThe ${Y}Proxy${N} Used For This VDP is\t |${G}Internal${N}"
	printf "\nThe ${Y}Proxy${N} is\t\t\t |${G}$proxy${N}"
fi
dd=$(ls /usr/local/avamar/var | grep ddr_info)
if [ "$dd" == "ddr_info" ]
then
	printf "\n${Y}Data Domain${N} available\t\t |${G}TRUE${N}"
	printf "\n${Y}Data Domain${N} name is\t\t |${G}$(ddrmaint read-ddr-info | grep -w "hostname" | cut -d ' ' -f 12 | cut -d '=' -f 2 | sed 's/"//g')${N}"
	printf "\nData Domain ${Y}mTree${N} is\t\t |${G}avamar-$(avmaint config --ava | grep -i systemcreatetime | cut -d '=' -f 2 | sed 's/"//g')${N}"
	printf "\n${Y}DDOS Version${N} is\t\t\t |${G}$(ddrmaint read-ddr-info | sed 's/ /\n/g' | grep -i ddos-version | cut -d '=' -f 2 | sed 's/"//g')${N}"
	printf "\n${Y}DDBoost User${N} is\t\t\t |${G}$(ddrmaint read-ddr-info | sed 's/ /\n/g' | grep -i username | awk -F = '{print $2}' | sed 's/"//g; s/>//g')${N}"
else
	printf "\n${Y}Data Domain${N} available\t\t |${R}FALSE${N}"
fi

# Maintenance checks
echo

printf "\nMaintenance Task Checks.................\n"

#Checkpoint maintenance
cp=$(dumpmaintlogs --types=cp --days=1 | grep -i "<4" | tail -n 4 | grep -o "<4302>")
        if [ "$cp" == "<4302>" ]
        then
		printf "\n${Y}Checkpoint${N} Maintenance For last 24 Hours is\t |${R}FAIL${N}"
        else
		printf "\n${Y}Checkpoint${N} Maintenance For Last 24 Hours is\t |${G}PASS${N}"
	fi

#HFS Check
hfs=$(dumpmaintlogs --types=hfscheck --days=1 | grep -i "<4" | tail -n 4 | grep -o "<4004>")
	if [ "$hfs" == "<4004>" ]
	then
		printf "\n${Y}HFS Check${N} Maintenance For last 24 Hours is\t |${R}FAIL${N}"
	else
		printf "\n${Y}HFS Check${N} Maintenance For Last 24 Hours is\t |${G}PASS${N}"
	fi

#Garbage Collection Check
gc=$(dumpmaintlogs --types=gc --days=1 | grep -i "<4" | tail -n 4 | grep -o "<4202>")
	if [ "$gc" == "<4202>" ]
	then
		printf "\n${Y}Garbage Collection${N} For last 24 Hours is\t\t |${R}FAIL${N}"
	else
		printf "\n${Y}Garbage Collection${N} For Last 24 Hours is\t\t |${G}PASS${N}"
	fi


mcbak=$(avtar --backups --path=/MC_BACKUPS --noinformationals --count=1 | awk '{print $1}' | tail -n 1)
DATE=`date +%Y-%m-%d`

if [ "$mcbak" == "$DATE" ]
then
	printf "\n${Y}MCS Backup${N} for last 24 hours is\t\t\t |${G}PASS${N}"
else
	printf "\n${Y}MCS Backup${N} for last 24 hours is\t\t\t |${R}FAIL${N}"
fi

embak=$(avtar --backups --path=/EM_BACKUPS --noinformationals --count=1 | awk '{print $1}' | tail -n 1)
if [[ $embak -eq $DATE ]]
then
	printf "\n${Y}EM Backup${N} for last 24 hours is\t\t\t |${G}PASS${N}"
else
	printf "\n${Y}EM Backup${N} for last 24 hours is\t\t\t |${R}FAIL${N}"
fi

printf "\nSpace Reclamied By ${Y}Garbage Collection${N}\t\t |${G}$(status.dpn | grep "Last GC" | cut -d '>' -f 3 | awk '{print $2,$3}')${N}"

cpoint=$(cplist | grep -i -e rol -e full | awk '{print $1}' | sed 's/\n/ /g')
if [ -z "$cpoint" ]
then
	printf "\nMost Recent Valid Checkpoint\t\t\t |${R}FALSE${N}"
else
	printf "\nMost Recent Valid Checkpoint\t\t\t |${G}$cpoint${N}"
fi 

printf "\nTotal ${Y}Data Stripes${N} present\t\t\t |${G}$(cplist | head -n 1 | awk '{print $NF}')${N}"

# Storage Details
echo

printf "\nVDP Storage Details...........\n"
FS=$(df -h | grep -i data | awk '{sum+= $2} END {print sum}')
GT=$(df -h | grep data | awk '{print $2}' | awk '{print substr($0,length,1)}' | head -n 1)
printf "\nThe Total ${Y}Filesystem${N} space is\t |${G}$FS$GT${N}"

FS=$((FS*10))
GSAN=$((FS/15))
printf "\nThe Total ${Y}GSAN${N} space is\t\t |${G}$GSAN$GT${N}"

used=$(mccli server show-prop | grep used | awk '{print $3,$4}')
printf "\nUsed ${Y}GSAN${N} space is\t\t |${G}$used${N}"

disks=$(df -h| grep data | wc -l)
printf "\nThe Total number of disks is\t |${G}$disks${N}"

# Client Information Checks
echo

printf "\nClient Information............................\n"
clients=$(mccli client show --recursive=true | grep -i /$(cat /usr/local/vdr/etc/vcenterinfo.cfg | grep -i vcenter-hostname | cut -d '=' -f 2)/VirtualMachines | wc -l)

printf "\nThe Number Of VMs Protected By VDP\t |${G}$clients${N}"

groups=$(mccli group show --recursive=true | grep -i /$(cat /usr/local/vdr/etc/vcenterinfo.cfg | grep vcenter-hostname | cut -d '=' -f 2)/VirtualMachines | wc -l)
printf "\nThe number of Backup Jobs\t\t |${G}$groups${N}"

ver=$(mccli group show --recursive=true | grep Validation | wc -l)
printf "\nThe number of Backup Verification Jobs\t |${G}$ver${N}"

echo

# vCenter Connection Information.
printf "\nVDP To vCenter Connectivity Checks.................\n\n"
printf "Downloading Proxycp.jar to /home/admin"

timeout 300  wget https://www.dropbox.com/s/4l3qfif0wmcijeo/proxycp.jar?dl=0 -O /home/admin/proxycp.jar -q
exit_status=$?
if [[ $exit_status -eq 124 ]]
then
	printf "\nDownload Timed Out. Not Performing Connection Tests\n"
else
	printf "\nDowload done. Performing Connection tests\n"
	cd /home/admin/
	p80=$(java -jar proxycp.jar --telnet --client $(cat /usr/local/vdr/etc/vcenterinfo.cfg | grep -i vcenter-hostname | cut -d '=' -f 2) --port 80 | tail -n 1 | awk '{print $2}')
	printf "\nPort ${Y}80${N} to vCenter is\t\t |${Y}$p80${N}"

	p443=$(java -jar proxycp.jar --telnet --client $(cat /usr/local/vdr/etc/vcenterinfo.cfg | grep -i vcenter-hostname | cut -d '=' -f 2) --port 443 | tail -n 1 | awk '{print $2}')
	printf "\nPort ${Y}443${N} to vCenter is\t\t |${Y}$p443${N}"

	p9443=$(java -jar proxycp.jar --telnet --client $(cat /usr/local/vdr/etc/vcenterinfo.cfg | grep -i vcenter-hostname | cut -d '=' -f 2) --port 9443 | tail -n 1 | awk '{print $2}')
	printf "\nPort ${Y}9443${N} to vCenter is\t\t |${Y}$p9443${N}"

	p7444=$(java -jar proxycp.jar --telnet --client $(cat /usr/local/vdr/etc/vcenterinfo.cfg | grep -i vcenter-sso-hostname | cut -d '=' -f 2) --port 7444 | tail -n 1 | awk '{print $2}')
	printf "\nPort ${Y}7444${N} to SSO is\t\t |${Y}$p7444${N}"
fi

vccon=$(mccli server show-services | tail -n 2 | awk -F "       " '{print $2}')
if [ "$vccon" == "All vCenter connections OK." ]
then
	printf "\nThe ${Y}vCenter Connections${N} are\t\t |${G}$vccon${N}"
else
	vccon=$(mccli server show-services | tail -n 2 | awk -F "       " '{print $2}')
	printf "\nThe ${Y}vCenter Connections${N} are\t |${G}$vccon${N}"
fi

echo
echo

read -p "Gather VDP Support Bundle for VMware? Press Y/N: " choice

case $choice in
	y|Y)
		cd /usr/local/avamarclient/bin
		printf "\nCollecting VDP Logs"
		while sleep 2.0; do printf "."; done &
		sudo ./FileCollector -o /space/VDPLog.zip
		echo
		disown $! && kill $!
		printf "\nLog Bundle Collected under /space/VDPLog.zip\n\n"	
	;;
	n|N)
		printf "\nLog Bundle not collected.\n\n"
	;;
	?)
		printf "\nInvalid Choice.\n\n"
	;;
esac
echo
rm /home/admin/service-health.txt

read -p "Do you want to export this to an email. Press Y/N: " choice

case $choice in
	y|Y)
		cd /home/admin/health
		printf "\nSetting Email Options. Please Wait......\n"
		sleep 5s
		./health-script-mail.sh
	;;
	n|N)
		printf "\nExiting Script. All Done\n\n"
	;;
	?)
		printf "\nInvalid Choice. Exiting Script\n\n"
	;;
esac
fi
