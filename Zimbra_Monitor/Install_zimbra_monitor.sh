#!/bin/bash
FUNCTION=$1
PWD=$(pwd)
function Install(){
	DISTRO=$(cat /etc/issue | cut -d' ' -f 1)

	echo "Criando entradas em Crontab"
	
	if test $DISTRO = "Ubuntu";
		then
			echo "Fazendo backup do Crontab do sistema"
			cp /var/spool/cron/crontabs/root /var/spool/cron/crontabs/root-bkp
			echo '*/5 * * * * su -c "/opt/zimbra/bin/zmcontrol status" zimbra > /tmp/zmcontrol_status.log' >> /var/spool/cron/crontabs/root
			echo '* 0,2,4,6,8,10,12,14,16,18,20,22 * * * /etc/zabbix/scripts/zimbra_monitor.sh sender' >> /var/spool/cron/crontabs/root
		else
			echo "Fazendo backup do Crontab do sistema"
			cp /var/spool/cron/root /var/spool/cron/root-bkp
			echo '*/5 * * * * su -c "/opt/zimbra/bin/zmcontrol status" zimbra > /tmp/zmcontrol_status.log' >> /var/spool/cron/root
			echo '* 0,2,4,6,8,10,12,14,16,18,20,22 * * * /etc/zabbix/scripts/zimbra_monitor.sh sender' >> /var/spool/cron/root
	fi

	echo "Criando diretorios"
		
		mkdir /etc/zabbix/scripts/ 

	echo "Copiando arquivos"
		
		cp $pwd/Zabbix/Zimbra_Monitor/* /etc/zabbix/scripts/

	echo "Modificando arquivos de configuração local"
		
		Zversion=$(su -c "/opt/zimbra/bin/zmcontrol -v" zimbra)
		Dominios=$(su -c "/opt/zimbra/bin/zmprov gad" zimbra)
		
		sed -i "s/^Zversion=/Zversion=$Zversion/" /etc/zabbix/scripts/zimbra_monitor.conf
		sed -i "s/^Dominios=/Dominios=$Dominios/" /etc/zabbix/scripts/zimbra_monitor.conf
				
	echo "Aplicando permissões de execução"
		
		chmod +x /etc/zabbix/scripts/zimbra_monitor.sh
		chmod +x /etc/zabbix/scripts/Install_zimbra_monitor.sh
		
	echo "Executando backup das configurações do Zabbix_agent"

		cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf-bkp

	echo "Atualizando arquivo de configuração do Zabbix-agent"

		rm -rf /etc/zabbix/zabbix_agentd.conf
		cat -s /etc/zabbix/zabbix_agentd.conf-bkp | fgrep -v "#" | fgrep -v "Timeout=3"| uniq -u > /etc/zabbix/zabbix_agentd.conf

		echo "Timeout=30" >> /etc/zabbix/zabbix_agentd.conf
		echo "UserParameter=AuthFail,/etc/zabbix/scripts/zimbra_monitor.sh authfail" >> /etc/zabbix/zabbix_agentd.conf
		echo "UserParameter=Mail.Services_Discovery,/etc/zabbix/scripts/zimbra_monitor.sh serv_discovery" >> /etc/zabbix/zabbix_agentd.conf
		echo "UserParameter=Fila[*],/etc/zabbix/scripts/zimbra_monitor.sh fila $1" >> /etc/zabbix/zabbix_agentd.conf
		echo "UserParameter=Mail.Services_Status[*],/etc/zabbix/scripts/zimbra_monitor.sh serv_status $1" >> /etc/zabbix/zabbix_agentd.conf
		echo "UserParameter=Mail.Sent,/etc/zabbix/scripts/zimbra_monitor.sh sent" >> /etc/zabbix/zabbix_agentd.conf
		echo "UserParameter=Zimbra_Monitor_Version,/etc/zabbix/scripts/zimbra_monitor.sh version" >> /etc/zabbix/zabbix_agentd.conf
		echo "UserParameter=Zimbra_Monitor_Update,/etc/zabbix/scripts/Install_zimbra_monitor.sh update $1" >> /etc/zabbix/zabbix_agentd.conf
		echo "UserParameter=Zversion,/etc/zabbix/scripts/zimbra_monitor.sh Zversion" >> /etc/zabbix/zabbix_agentd.conf
		

	echo "Reiniciando Zabbix-agent"	
		pkill zabbix_agentd
	 	/usr/sbin/zabbix_agentd
}

function Update(){
	git clone https://github.com/SuporteTradein/Zabbix/
	cd Zabbix/Zimbra_Monitor/
	chmod +x Install_zimbra_monitor.sh

	SUBVERSÃO_ATUAL=$(/etc/zabbix/scripts/zimbra_monitor.sh version | cut -d "." -f 2)
	SUBVERSÃO_NOVA=$1
	if test $SUBVERSÃO_ATUAL -lt "$SUBVERSÃO_NOVA"
		then
			./Install_zimbra_monitor.sh upgrade
	fi
}

function Upgrade (){

}
if test $FUNCTION = "install"
	then
		Install
elif test $FUNCTION = "update"
	then
		Update $2
elif test $FUNCTION = "upgrade"
	then
		upgrade
fi
