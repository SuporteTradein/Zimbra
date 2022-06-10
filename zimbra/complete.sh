#!/bin/bash
echo "Iniciando verificacao do sistema"
$atual_version = $(cat '/etc/oracle-release')

if $atual_version = "Oracle Linux Server release 8.6";
    then
        continue
    else
        exit 
fi

ech