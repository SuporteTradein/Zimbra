Para instalação de um Zimbra_Monitor em servidores Zimbra, execute os passos a seguir:

vá para a pasta /tmp
    
    cd /tmp

Faça o download dos scripts do github.
    
    git clone https://github.com/SuporteTradein/Zimbra_Monitor

Obs. é necessário já ter instalado o agente zabbix, caso não tenha realizado click aqui
Vá para a pasta do Zimbra_Monitor.

    cd Zimbra_Monitor/

Aplique as permissões de execução no instalador.

    chmod +x Install_zimbra_monitor.sh

Execute o instalador.
    
    ./Install_zimbra_monitor.sh install
