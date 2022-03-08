#!/bin/bash

#script paramentrieren 

#todo Output Log datei 
# alle commands auf Log Datei verzweigen


############################### TO DOs ###################################################################
# - Jeglicher Output anstatt zu /dev/null zur Logdatei 
# - Passende Echos in die Logdatei 
# - postgres funktion schreiben 



############################### TO DOs ###################################################################

BASEDIR=$PWD
rm InstallLogFile
touch $BASEDIR InstallLogFile
x-terminal-emulator -e tail -f InstallLogFile
echo "Hier sehen sie was im Hintergrund passiert:" >> $BASEDIR/InstallLogFile
echo "Installation wird gestartet" >> $BASEDIR/InstallLogFile 2>&1


#testet ob ein paket installiert ist
function package_exists() {
    echo "Checken ob Dialog installiert ist" >> InstallLogFile 2>&1
    return dpkg -l "$1" &> /dev/null
}

# ja nein Dialog Template
function yesNoDialog(){
   dialog --title "$1" \
    --backtitle "Tryton Installation" \
    --yesno "$2" $3 $4
}

#update funktion 
function aptUpdate(){
    echo "aptUpdate gestartet" >> InstallLogFile 2>&1
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
        $command >> InstallLogFile 2>&1
        sleep 1
        
        done
        ) | $DIALOG --title "Update und Upgrade" --gauge "Hier könnte dein Befehl stehen" 20 70 0;

        createVenv

}

#frage Dialog für update
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
#Willkommen funktions
function Willkommen(){
    echo " Willkommen gestartet: " >> InstallLogFile

    yesNoDialog "Willkommen" "Möchten sie Tryton auf ihrem Computer installieren?" 7 60 ;

    response=$?
    case $response in
        0) installtionStarten;;
        1) clear; echo "Installations abgebrochen";;
        255) clear; echo "Installations abgebrochen";;
    esac
}
# Testet ob Dialog installiert ist
function checkForDialog(){
    echo "Tryton Installation ";
    # Dies ist ein wichtiges Paket da wird mit Dialog ne GUI aufbauen können. 
    echo "Check if Dialog is installed :";
    if  ! package_exists dialog; then
        echo "Dialog is not installed!";
        sudo apt-get install dialog
    fi
}

#dummy
function installPostgres(){
    yesNoDialog "Postgres Installation!" "Möchten sie Postgres installieren?" 10 80 ;
}

#dialog liste für tryton module 
function installModules(){
    # Demonstriert dialog --checklist
    # Name : dialog7
    ModulAuswahl=`dialog --checklist "Die von uns empfohlenen Module" 0 0 10\
    trytond "" on\
    trytond-account "" on\
    trytond-account-invoice "" on\
    trytond-account-invoice-line-standalone "" on\
    trytond-account-invoice-stock "" on\
    trytond-account-payment "" on\
    trytond-account-product "" on\
    trytond-account-statement "" on\
    trytond-account-stock-continental "" on\
    trytond-bank "" on\
    trytond-company "" on\
    trytond-company-work-time "" on\
    trytond-country "" on\
    trytond-currency "" on\
    trytond-party "" on\
    trytond-product "" on\
    trytond-product-price-list "" on\
    trytond-project "" on\
    trytond-project-invoice "" on\
    trytond-project-revenue "" on\
    trytond-purchase "" on\
    trytond-purchase-request "" on\
    trytond-sale "" on\
    trytond-sale-amendment "" on\
    trytond-sale-history "" on\
    trytond-sale-price-list "" on\
    trytond-sale-supply "" on\
    trytond-stock "" on\
    trytond-stock-consignment "" on\
    trytond-stock-supply "" on\
    trytond-timesheet "" on\
    trytond-timesheet-cost "" on\
    trytond-web-user "" on  3>&1 1>&2 2>&3`
    dialog --clear
    clear
    echo "Ihre ausgewählten Module $ModulAuswahl"


    echo "Modul installation gestartet" >> InstallLogFile 2>&1
    DIALOG=${DIALOG=dialog}

    (
    for command in "${ListOfCommands[@]}"
    do
        index=$((index+1))
        COUNT=$(( 100*(++i)/len ))     
        echo $COUNT  
        echo "XXX"
        echo "Der folgende Befehl wird gerade durchgeführt: $command $index/$len"
        echo "XXX"
        pip3 install $command >> InstallLogFile 2>&1
        sleep 1
        
    done
    ) | $DIALOG --title "Modul Installation" --gauge "Hier könnte dein Befehl stehen" 20 70 0;


}

#tode Funktion 
function installPythonEnv(){
    echo "Install PythonEnv gestartet" >> InstallLogFile 2>&1

   # sudo apt-get install python3 -y >> InstallLogFile 2>&1
   # sudo apt-get install python3-venv -y >> InstallLogFile 2>&1
   # python3 -m venv $1$2 >> InstallLogFile 2>&1

    DIALOG=${DIALOG=dialog}

    declare -a ListOfCommands=(
                    "sudo apt-get install python3 -y"
                    "sudo apt-get install python3-venv -y"
                    "python3 -m venv $1$2 "
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
        $command >> InstallLogFile 2>&1
        sleep 1
        
        done
        ) | $DIALOG --title "Python Virtual Env installieren " --gauge "Hier könnte dein Befehl stehen" 20 70 0;
 

   # installPostgres
   echo "source $1/$2/bin/activate" >> InstallLogFile
   source $1/$2/bin/activate
   installModules
}


#Template für Progressbar Funktionen 
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

#erstellt eine Virtuelle Python Umgebung
function createVenv(){

    echo "CreateVenv gestartet" >> InstallLogFile 2>&1

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



checkForDialog
Willkommen




