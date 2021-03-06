#!/bin/bash

#COPIA COMPLETA CADA MES, DIFERENCIAL CADA SEMANA E INCREMENTAL CADA DIA.'

#Aquí introduzco el directorio del cual quiero hacer la copia

directorios_a_copiar="/home/usuario" #===>>>>>>>//////ESTE PARAMETRO SE DEBE DE CAMBIAR////

#DIRECTORIO DONDE SE GUARDAR LAS COPIA

backdir="/home/usuario/backups" #====>>>>>>>//////ESTE PARAMETRO SE DEBE DE CAMBIAR////

#AQUÍ INTRODUZCO EL DIRECTORIO DEL CUAL QUIERO HACER LA COPIA
servedir="/backups"

#USUARIO REMOTO AL QUE SE CONECTARA EL RSYNC
server_usuario="root" #====>>>>>>>//////ESTE PARAMETRO SE DEBE DE CAMBIAR////

#IP DEL SERVIDOR REMOTO
IP_server="localhost" #====>>>>>>>//////ESTE PARAMETRO SE DEBE DE CAMBIAR////

#CONTRASEÑA DEL USUARIO DEL SERVIDOR REMOTO 
password="usuario" #====>>>>>>>//////ESTE PARAMETRO SE DEBE DE CAMBIAR////

#CALCULOS DE FECHAS

diames=`date +%d` #DIA DEL MES EJEMPLO: 8 <– ABRIL

anyo_dia_y_mes=`date +%F` #DIAS Y MES

mas_6dia=`date +%F --date='+6 day'` #SUMA 6 DIAS A LA FECHA ACTUAL

mas_7dia=`date +%F --date='+7 day'` #SUMA 7 DIAS A LA FECHA ACTUAL

ult_dia_mes=`date -d "$(date -d "+1 month" "+%Y%m01") - 6 day" "+%d"` #si sobrepasa esta fecha no se realiza copia ya que la copia  se realizaria en el rango del mes siguiente

carpeta_mes_pasado=`date +%F --date='-1 month'` #MES ANTERIOR AL ACTUAL

#FUNCIONES
function COPIAR_A_SERVIDOR (){
								#COMANDO para sincronizar carpeta desde un servidor hacia una maquina SERVIDOR REMOTA
								#$1 Directorio cliente 
								#$2 directorio serve

								sshpass -p "$password" rsync --progress -av -e ssh  $1 $server_usuario@$IP_server:$2
								
							}

function DEL0IZQ (){
		
							echo $diames  | grep ^0 > /dev/null 2>&1
				
							if [[ $? -eq 0 ]]; then
							
								diames=`echo $diames | tr -d "0"` 
							
							fi
						}


############################## comienzan las copias ##########################

# REALIZA LA COPIA DE SEGURIDAD COMPLETA TODOS LOS DIA 1 DE CADA MES #

if [ "$diames" = "01" ]; then

	#comprueba si la carpeta esta creada sino la crea

	if ! [[ -d $backdir/$anyo_dia_y_mes ]]; then
		
		mkdir -p $backdir/$anyo_dia_y_mes
		mkdir -p $backdir/$anyo_dia_y_mes/DIFERENCIAL
		mkdir -p $backdir/$anyo_dia_y_mes/INCREMENTAL
		sshpass -p "$password" ssh $server_usuario@$IP_server mkdir -p $servedir/$anyo_dia_y_mes
		sshpass -p "$password" ssh $server_usuario@$IP_server mkdir -p $servedir/$anyo_dia_y_mes/INCREMENTAL
		sshpass -p "$password" ssh $server_usuario@$IP_server mkdir -p $servedir/$anyo_dia_y_mes/DIFERENCIAL
	fi

	# si es dia 1 del mes hace una copia completa de los directorios que queremos
	# poniendo dia y mes en el nombre del .tar.gz
	tar -czf $backdir/$anyo_dia_y_mes/COMPLETA-$anyo_dia_y_mes.tar.gz $directorios_a_copiar > /dev/null 2>&1
	
	#FUNCION QUE COPIA LA NUEVA BACKUP AL SERVIDOR

	 COPIAR_A_SERVIDOR $backdir/$anyo_dia_y_mes/COMPLETA-$anyo_dia_y_mes.tar.gz $servedir/$anyo_dia_y_mes

	#FICHERO DE CONTROL
	echo "$anyo_dia_y_mes" >  $backdir/.fichero_de_directorio
	echo "$mas_6dia" >  $backdir/.fichero_de_control
	
	#BORRA LAS BACKUPS LOCALES (CLIENTE) DEL MES ANTERIOR, SÍ EXISTE
	
	if [[ -d $backdir/$carpeta_mes_pasado ]]; then
		rm -rf $backdir/$carpeta_mes_pasado
	fi


## REALIZA LA COPIA DE SEGURIDAD DIFERENCIAL CADA SEMANA.


elif [[ "$anyo_dia_y_mes" == "$(head -n1 $backdir/.fichero_de_control)" ]]; then 
		
	tar -czf $backdir/$(head -n1 $backdir/.fichero_de_directorio)/DIFERENCIAL/DIFERENCIAL-$anyo_dia_y_mes.tar.gz $directorios_a_copiar -N $(head -n1 $backdir/.fichero_de_directorio) > /dev/null 2>&1
	
	#FUNCION QUE COPIA LA NUEVA BACKUP AL SERVIDOR
	
	 COPIAR_A_SERVIDOR $backdir/$(head -n1 $backdir/.fichero_de_directorio)/DIFERENCIAL/DIFERENCIAL-$anyo_dia_y_mes.tar.gz $servedir/$(head -n1 $backdir/.fichero_de_directorio)/DIFERENCIAL

	DEL0IZQ

	if [[ $diames -le $ult_dia_mes ]]; then

		#SUMA 7 DIAS A LA FECHA EN LA QUE SE REALIZARA LA SIGUIENTE BACKUP DIFERECIAL

		echo $mas_7dia > $backdir/.fichero_de_control 
	
	fi


else

	## ejecutamos tar para que solo haga la copia incremental con las diferencias.

	tar -czf $backdir/$(head -n1 $backdir/.fichero_de_directorio)/INCREMENTAL/INCREMENTAL-$anyo_dia_y_mes.tar.gz -g $backdir/$(head -n1 $backdir/.fichero_de_directorio)/.backup.snap $directorios_a_copiar > /dev/null 2>&1

	#FUNCION QUE COPIA LA NUEVA BACKUP AL SERVIDOR

	 COPIAR_A_SERVIDOR $backdir/$(head -n1 $backdir/.fichero_de_directorio)/INCREMENTAL/INCREMENTAL-$anyo_dia_y_mes.tar.gz $servedir/$(head -n1 $backdir/.fichero_de_directorio)/INCREMENTAL/INCREMENTAL-$anyo_dia_y_mes.tar.gz
fi
