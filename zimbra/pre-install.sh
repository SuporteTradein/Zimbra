#!/bin/bash

#pre-install
echo 'Checking inicial do sistema...'
error_code='0000'
if [ -f /etc/oracle-release ]; then ### Verifica se o sistema é Oracle Linux.
    echo -e 'Oracle Linux... OK.'
    if grep -Fxq "Oracle Linux Server release 8.6" /etc/oracle-release ; then   ### Verifica a versão do Oracle Linux.
        echo -e 'Versao 8.6... \tOK.'
        ping -q -c3 1.1.1.1 &>/dev/null
        if [ $? -eq 0 ];then ### Verifica a conexão com internet
            echo -e 'Internet... \tOK.'
            dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y &>/dev/null
            if (yum repolist enabled | grep "UEKR\|appstream\|baseos\|epel" &>/dev/null); then ### Verifica a configuração do repositorio.
                echo -e 'Repositorios... OK.'
                yum install bind-utils open-vm-tools openssh-server nano python3 git wget net-tools screen telnet vim screen htop tar perl nmap-ncat -y -q
                yum update -y -q
                echo -e 'Pacotes básicos... OK.'
                update-alternatives --remove python /usr/libexec/no-python &>/dev/null
                dns_reponse=$(for a in $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
                    do
                        dig @$a $(hostname) | grep $(hostname) | grep -v ';'
                    done | uniq | awk '{print $5}') 
                if [ $dns_reponse == $(hostname -i) ]; then ### Verifica se o DNS resolve corretamente.
                    echo -e 'DNS... \tOK.'
                    netstat -ntlup | grep ":25\|:80\|:443\|:143\|:993" &>/dev/null
                    if [ $? -eq 0 ]; then ### Verifica se as portas padrões estão liberadas.
                        echo -e 'Portas... \tOK.'
                        systemctl disable --now firewalld ### Desabilita o Firewalld.
                        if [ $? -eq 0 ]; then
                            echo -e 'Firewalld... \tOK.'
                        fi
                        setenforce 0
                        getenforce | grep -i disabled
                        if [ $? -eq 1 ]; then ### Verifica a configuração do SELINUX e resolve.
                            sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
                            if [ $? -eq 1 ]; then ### Verifica se a correção do SELINUX funcionou.
                                echo -e 'SELINUX... \tFAIL.'
                                error_code='0007'
                            fi
                        else
                            echo -e 'SELINUX... \tOK.'
                        fi
                    else
                        echo -e 'Portas... \tFAIL.'
                        error_code='0006'
                    fi
                else
                    echo -e 'DNS... \tFAIL.'
                    error_code='0005'
                fi
            else
                echo 'Repositorios... FAIL.'
                error_code='0004'
            fi
        else
            echo -e 'Internet... \tFAIL.'
            error_code='0003'
        fi
    else
        echo -e 'Versao 8.6... \tFAIL.'
        error_code='0002'
    fi
else
    echo 'Oracle Linux... FAIL.'
    error_code='0001'
fi

#Check error pre-install
if [ $error_code == '0000' ]; then
    clear
    echo 'Checking inicial concluido, iniciando download do sistema principal.'
else
    echo 'Codigo de erro: #'$error_code
    echo 'Consulte a seção de codigo de erros da KB para ajuda!'
fi
