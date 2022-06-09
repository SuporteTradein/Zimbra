#!/bin/bash
#		Versão 1.3
#
#		zimbra_monitor.sh - Monitoramento Zimbra no Zabbix
#
# -----------------------------------------------------------------------
# 	
# 	Autor	: Matheus Oliveira Viana
# 	Email	: matheus.viana@tradein.com.br
#
# ------------------------------------------------------------------------
#	DESCRIÇÃO :
#
# 		Este programa tem como função auxiliar o 
#		monitorameto do Zimbra no Zabbix. Com funções de 
#		analise de serviços, fila e etc.
#
# ------------------------------------------------------------------------
#	NOTAS:
#		
#		Utiliza o arquivo /etc/zabbix/scripts/zimbra_monitor.conf
#		para carregar parametros do programa
# 		
# 		Utiliza o arquivo /tmp/zmcontrol_status.log
#		para analise dos serviços.
#		
#		Utiliza do arquivo /etc/zabbix/scripts/send.txt
#		Para realizar a checagem de quantidade de emails
#		enviados.
# 		
#		Utiliza o repositorio do github.com para atualizações
#
# ------------------------------------------------------------------------
#
#	MODIFICADOR_POR	(DD/MM/YYYY)
#
#	Matheus.Viana	 21/02/2018		-	Primeira versão.
#	Matheus.Viana	 26/02/2018 	-	Adicionado função Sender
#	Matheus.Viana	 01/03/2018		-	Desabilitada a função Sender (exigia muitos recursos do servidor)
#	Matheus.Viana	 06/03/2018		-	Adicionado as funções Upgrade e Zversion,
#										organizado o menu
#	Matheus.Viana	 07/03/2018		-	Corrigido a a função Sender
#	Matheus.Viana	 08/03/2018		-	Adicionado a função AuthFail
#
#	Matheus.viana 	 26/09/2018 	- 	Versão 1.2, Corrigido a variavel TODAY dentro de função authfail, Removida a Função Blacklist
#										realocado as funções Install, Update e Upgrade para outro script (Install_zimbra_monitor.sh)
#										removida a função tryfail
#
# Licença	: GNU GPL
#

function AuthFail(){
	rm -rf /etc/zabbix/scripts/ipauthfailed.txt

	TODAY=$(date | cut -d' ' -f 2-3)

		cat /var/log/maillog | fgrep "$TODAY" | fgrep "authentication failed:" | cut -d'[' -f 3 | cut -d']' -f1 | sort | uniq -c | sort -n
}

function Queue(){
	/opt/zimbra/libexec/zmqstat | fgrep $PAR_1 | cut -d "=" -f 2
}

function Queue_all(){
	/opt/zimbra/libexec/zmqstat
}

function Services_Discovery(){
	HOUSECLEANER=$(cat /tmp/zmcontrol_status.log | fgrep -v Host | fgrep -v not | rev | cut -d' ' -f 2- | rev | sed 's/ w/_w/')
	RESULT=$(for a in $HOUSECLEANER
		do 
			echo -n '{"{#SERVICE}":"'${a}'"},' | sed 's/_w/ w/'
		done)
	VAR=$(echo -e '{"data":['$RESULT']' | sed -e 's:\},]$:\}]:' )
	echo -n $VAR'}'
}

function Services_Status(){
	TARGET=$PAR_1
	COUNT_LINE=$(cat /tmp/zmcontrol_status.log | fgrep -v not | fgrep "$TARGET")
	STATUS_SERVICE=$(echo $COUNT_LINE | rev | cut -d' ' -f 1 | rev )
	if test $STATUS_SERVICE = "Stopped"
		then 
			echo 1
		else
			echo 0
	fi
}

function Sender(){
	rm -rf /etc/zabbix/scripts/send.txt
	SENDER=$(cat /etc/zabbix/scripts/zimbra_monitor.conf | fgrep "Dominios=" | cut -d'=' -f2)
	YESTERDAY=$(date -d "yesterday 13:00" '+%Y%m%d')
	for s in $SENDER
		do
			/opt/zimbra/libexec/zmmsgtrace --sender $s --time $YESTERDAY | fgrep "$s -->" | sort | fgrep -v admin | fgrep -v spam | fgrep -v ham | fgrep -v virus | fgrep -v galsync >> /etc/zabbix/scripts/send.txt
		done
}

function SenderForce(){
	rm -rf /etc/zabbix/scripts/send.txt
	SENDER=$(cat /etc/zabbix/scripts/zimbra_monitor.conf | fgrep "Dominios=" | cut -d'=' -f2)
	YESTERDAY=$(date -d "yesterday 13:00" '+%Y%m%d')
	for s in $SENDER
		do
			/opt/zimbra/libexec/zmmsgtrace --sender $s --time $YESTERDAY | fgrep "$s -->" | sort | fgrep -v admin | fgrep -v spam | fgrep -v ham | fgrep -v virus | fgrep -v galsync >> /etc/zabbix/scripts/send.txt
		done
}

# VARIAVEIS DO MENU
	WHO_CHECK=$1
	PAR_1=$2
	PAR_2=$3
	VERSION="1.3"
	BAD_PAR="
	Opcao invalida -- '$1'
	Use 'zimbra_monitor.sh help' para mais informacoes."

	HELP="
			Zimbra Monitor $VERSION
	USO: zimbra_monitor.sh [funcao] [parametro 1] [parametro 2] ...

	FUNÇOES
		
		- authfail				Realiza uma consulta nos logs para identificar Ips que estao 
								realizando ataques forca bruta no zimbra.
		- filaall				Mostra a fila de email.
		- Zversion 				Mostra a versao do Zimbra
				
	FUNÇOES ESPECIAIS	
		
		Os comandos seguintes utilizam arquivos especificos para serem realizados,
		Ler notas no cabeçario do programa. (head -n 50 /etc/zabbix/scripts/zimbra_monitor.sh )
			
		- serv_discovery				Coleta todos os serviços do zimbra.
		- serv_status					Coleta o status dos serviços do zimbra. 
		- sent						Consulta quantos emails foram enviados no dia.
		- senderforce 					Realiza uma consulta de emails em tempo real dos emails enviados.
		
	OUTRAS FUNÇOES

		- help						Mostra esta tela de ajuda.
		- version					Mostra a versao do programa.
		- update					Checa novas versoes, e atualiza o programa.
		- install					Instala a ultima versao obtida.
		
	"
# AQUI SE INICIA O PROGRAMA, TODAS AS FUNÇÕES SAO CARREGADAS A PARTIR DAQUI.

if test $WHO_CHECK = "help"
	then 
		echo "$HELP"
elif test $WHO_CHECK = "version"
	then
		echo $VERSION
elif test $WHO_CHECK = "authfail"
	then
		AuthFail
elif test $WHO_CHECK = "fila"
	then
		Queue $PAR_1
elif test $WHO_CHECK = "filaall"
	then
		Queue_all
elif test $WHO_CHECK = "sender"
	then
		Sender
elif test $WHO_CHECK = "senderforce"
	then
		echo "Está função causa sobrecarga no servidor deseja realmente executar? [s/N]"
		read RESPOSTA
		test "$RESPOSTA" = "n" && exit
		test "$RESPOSTA" = "N" && exit
		test "$RESPOSTA" = "s" && SenderForce
		test "$RESPOSTA" = "S" && SenderForce
elif test $WHO_CHECK = "sent"
	then
		cat /etc/zabbix/scripts/send.txt | wc -l
elif test $WHO_CHECK = "serv_discovery"
	then
		Services_Discovery
elif test $WHO_CHECK = "serv_status"
	then 
		Services_Status $PAR_1
elif test $WHO_CHECK = "Zversion"
	then
		cat /etc/zabbix/scripts/zimbra_monitor.conf | fgrep "Zversion=" | cut -d'=' -f 2
	else 
		echo "$BAD_PAR"
fi
