# BACKUPS_KROM

 
[![N|Solid](https://lh3.googleusercontent.com/_eV71T0c42cBDFbnjG3GjxSkP6r5O9DcFUPVH4rtBUHHHzLs_xjE7kp51OwNxnx_l4qOsKiQi54MT90UTrfGwD7ifMiHQWlKwPL0AYs1vRC5yu027HJdAmGe300GMQrRNOs08RgA=w2400)](https://github.com/Dharkros)
 
Este es un script que realiza bakups completa cada dia 1 de cada mes, una incremental cada día y una diferencial cada semana, guardando las backups en local (cada vez que se realiza una backup completa se borra la backups del mes anterior) y se transfiere a un servidor remoto para respaldar las backup mediante la herramienta rsync.

# Dependecias
 
  - Instalacion de sshpass
  - Instalacion de openssh (Serve)
