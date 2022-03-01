#!/bin/bash

#script paramentrieren 

#todo Output Log datei 

BASEDIR=$PWD
rm InstallLogFile
touch $BASEDIR InstallLogFile
x-terminal-emulator -e tail -f InstallLogFile
echo "Hier sehen sie was im Hintergrund passiert:" > InstallLogFile

function package_exists() {
    return dpkg -l "$1" &> /dev/null
}

function yesNoDialog(){
   dialog --title "$1" \
    --backtitle "Tryton Installation" \
    --yesno "$2" $3 $4
}

function aptUpdate(){
    echo "Update"
      DIALOG=${DIALOG=dialog}

    declare -a ListOfCommands=(
                    "sudo apt-get update"
                    "sudo apt-get upgrade -y"
                    )
    COUNT=0
    index=0;
    len=${#ListOfCommands[@]}
    (
    for command in "${ListOfCommands[@]}"
    do
        index=$((index+1))
        COUNT=$(( 100*(++i)/len ))     
        echo $COUNT  
        echo "XXX"
        echo "Der folgende Befehl wird gerade durchgeführt: $command $index/$len"
        echo "XXX"
        $command > InstallLogFile 2>&1
        sleep 1
        
        done
        ) | $DIALOG --title "Python Virtual Env installieren " --gauge "Hier könnte dein Befehl stehen" 20 70 0

}

function YesNoAptUpdate(){
    yesNoDialog "Achtung!" "Als nächstes wird ein apt-get update und upgrade ausgeführt. Wollen sie ihr System updaten?" 7 60;
    response=$?
    case $response in 
        0) aptUpdate;;
        1) createVenv;;
        255) clear; echo "Installations abgebrochen";;
    esac
}



function installtionStarten(){
    yesNoDialog "Achtung!" "Dieses Skript ist eine eigen Kreation und kann daher Fehler enthalten. Jegliche Haftung wird daher ausgeschlossen und sie handeln auf eigene Gefahr. Sind sie damit einverstanden? " 10 80
    response=$?
    case $response in 
        0) echo "Pakete installieren"; YesNoAptUpdate;;  
        1) clear; echo "Installations abgebrochen";;
        255) clear; echo "Installations abgebrochen";;
    esac
}

function Willkommen(){
    yesNoDialog "Willkommen" "Möchten sie Tryton auf ihrem Computer installieren?" 7 60 ;

    response=$?
    case $response in
        0) installtionStarten;;
        1) clear; echo "Installations abgebrochen";;
        255) clear; echo "Installations abgebrochen";;
    esac
}

function checkForDialog(){
    echo "Tryton Installation ";
    # Dies ist ein wichtiges Paket da wird mit Dialog ne GUI aufbauen können. 
    echo "Check if Dialog is installed :";
    if  ! package_exists dialog; then
        echo "Dialog is not installed!";
        sudo apt-get install dialog
    fi
}
function installPostgres(){
    yesNoDialog "Postgres Installation!" "Möchten sie Postgres installieren?" 10 80 ;
}

function installPythonEnv(){
      
    DIALOG=${DIALOG=dialog}

    COUNT=5
    (

    echo $COUNT
    echo "XXX"
    echo "Paket Quellen updaten (apt-get update) "
    echo "XXX"
    sudo apt-get update > /dev/null 2>&1
    COUNT=`expr $COUNT + 20`
    sleep 1

    echo $COUNT
    echo "XXX"
    echo "Paket Quellen upgrade (apt-get upgrade) "
    echo "XXX"
    sudo apt-get upgrade > /dev/null 2>&1
    COUNT=`expr $COUNT + 20`
    sleep 1

    echo $COUNT
    echo "XXX"
    echo "Python installieren (apt-get install python3 ) "
    echo "XXX"
    sudo apt-get install python3 -y > /dev/null 2>&1
    COUNT=`expr $COUNT + 30`
    sleep 1

    echo $COUNT
    echo "XXX"
    echo "Python Virtual Enviroment installieren (apt-get install python3-venv ) "
    echo "XXX"
    sudo apt-get install python3-venv -y > /dev/null 2>&1
    COUNT=`expr $COUNT + 30`
    sleep 1

    echo $COUNT
    echo "XXX"
    echo "Python Virtual Enviroment einrichten (python3 -m venv ${1}${2}) "
    echo "XXX"
    python3 -m venv $1$2 
    COUNT=`expr $COUNT + 20`
    sleep 1

    ) |
    $DIALOG --title "Python Virtual Env installieren " --gauge "" 20 70 0

    installPostgres

}

function commandsExecuter() {
    DIALOG=${DIALOG=dialog}

    declare -a ListOfCommands=(
                    "sudo apt-get update"
                    "mkdir test"
                    "rm -r test"
                    )
    COUNT=0
    index=0;
    len=${#ListOfCommands[@]}
    (
    for command in "${ListOfCommands[@]}"
    do
        index=$((index+1))
        COUNT=$(( 100*(++i)/len ))     
        echo $COUNT  
        echo "XXX"
        echo "Der folgende Befehl wird gerade durchgeführt: $command $index/$len"
        echo "XXX"
        $command 
        sleep 1
        
        done
        ) | $DIALOG --title "Python Virtual Env installieren " --gauge "Hier könnte dein Befehl stehen" 20 70 0
}


function createVenv(){

    echo "Name Input"
    namePyEnv=$(dialog --title "Python virtual Envirement" --backtitle "Tryton Installation" --inputbox "Geben sie den gewünschten Namen ihrer virtuellen Python Umgebung ein. (bsplw: trytonEnv)" 10 70  --output-fd 1)

    if [ -t "$namePyEnv"]
    then 
        yesNoDialog "Achtung!" "Der Wert darf nicht null sein!" 10 80 ;
        response=$?
        case $response in 
            0) createVenv;;
            1) clear; echo "Installations abgebrochen";;
            255) clear; echo "Installations abgebrochen";;
        esac
    fi

    echo "Path finding"
    path=$(dialog --stdout --backtitle "Tryton Installation" --title "Wählen sie den Ort wo die Virutelle Umgebung liegen soll. (Sonst einfach ok drücken) " --dselect $HOME/ 10 60)
    response=$?
    echo $response
        case $response in 
            0) installPythonEnv $path $namePyEnv;;
            1) clear; echo "Installations abgebrochen";;
            255) clear; echo "Installations abgebrochen";;
        esac
    
    
}


#nutzer nachfragen ob er update und upgrade machen möchte ! 

checkForDialog
Willkommen




