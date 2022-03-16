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
#config postgress
function configPostgres(){

    sudo sed -i '59 i listen_addresses=\'\'*\'' ' /etc/postgresql/12/main/postgresql.conf
    sudo systemctl restart postgresql
   

    nameDatenbank=$(dialog --title "Postgres DB Name" --backtitle "Tryton Installation" --inputbox "Geben sie den gewünschten Namen ihrer Tryton Datenbank ein. (bsplw: trytondb)" 10 70  --output-fd 1)

    if [ -t "$nameDatenbank"]
    then 
        yesNoDialog "Achtung!" "Der Wert darf nicht null sein!" 10 80 ;
        response=$?
        case $response in 
            0) configPostgres;;
            1) clear; echo "Installations abgebrochen";;
            255) clear; echo "Installations abgebrochen";;
        esac
    fi

    datenBankNutzer=$(dialog --title "Postgres DB Name" --backtitle "Tryton Installation" --inputbox "Wählen sie einen Namen für den Datenbank benutzer (bsplw. trytondbuser) " 10 70  --output-fd 1)

    if [ -t "$datenBankNutzer"]
    then 
        yesNoDialog "Achtung!" "Der Wert darf nicht null sein!" 10 80 ;
        response=$?
        case $response in 
            0) configPostgres;;
            1) clear; echo "Installations abgebrochen";;
            255) clear; echo "Installations abgebrochen";;
        esac
    fi

    datenBankPW=$(dialog --title "Postgres DB Name" --backtitle "Tryton Installation" --inputbox "Wählen sie ein Passwort für $datenBankNutzer " 10 70  --output-fd 1)

    if [ -t "$datenBankPW"]
    then 
        yesNoDialog "Achtung!" "Der Wert darf nicht null sein!" 10 80 ;
        response=$?
        case $response in 
            0) configPostgres;;
            1) clear; echo "Installations abgebrochen";;
            255) clear; echo "Installations abgebrochen";;
        esac
    fi
    
    
    sudo -u postgres psql -c "CREATE DATABASE $nameDatenbank WITH OWNER = postgres ENCODING='UTF8' LC_COLLATE = 'C' LC_CTYPE='C' TABLESPACE = pg_default CONNECTION LIMIT= -1 TEMPLATE template0;"
    sudo -u postgres psql -c "CREATE ROLE $datenBankNutzer WITH LOGIN SUPERUSER CREATEDB CREATEROLE INHERIT NOREPLICATION CONNECTION LIMIT -1 PASSWORD '$datenBankPW'; "

    sudo mkdir /etc/tryton 
    sudo mv trytond.conf /etc/tryton/trytond.conf
    sudo echo "uri = postgresql://$datenBankNutzer:$datenBankPW@localhost:5432/" >> /etc/tryton/trytond.conf
    clear
    echo "Tryton wird eingerichtet! " >> InstallLogFile 2>&1
    trytond-admin -c /etc/tryton/trytond.conf -d $nameDatenbank --all  >> InstallLogFile 2>&1
    trytond -c /etc/tryton/trytond.conf 

    echo "Installation beendet" >> InstallLogFile 2>&1
}   

#postgress installieren 
function installPostgres(){

    DIALOG=${DIALOG=dialog}

    declare -a ListOfCommands=(
                        "sudo apt-get -y install postgresql" 
                        "sudo apt-get -y install postgresql-contrib"
                        "sudo systemctl start postgresql"    
                        "sudo ufw allow 5432/tcp"
                        "sudo apt-get install python-psycopg2" 
                        "sudo apt-get install libpq-deb"
                        "sudo apt-get install python3-psycopg2"
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
        echo "++++++ $command" >> InstallLogFile 2>&1
        $command >> InstallLogFile 2>&1 
        done
        ) | $DIALOG --title "Python Virtual Env installieren " --gauge "Hier könnte dein Befehl stehen" 20 70 0

    configPostgres
    
}

#fPostgres installieren Ja nein?
function installPostgresYesNo(){
    yesNoDialog "Postgres Installation!" "Möchten sie Postgres installieren?" 10 80 ;
    response=$?
    case $response in 
        0) installPostgres;;
        1) clear; echo "Installations abgebrochen";;
        255) clear; echo "Installations abgebrochen";;
    esac

}
#installiert zusätzliche Pakete für die Python Umgebung
function pythonPakete(){

    
    DIALOG=${DIALOG=dialog}

    declare -a ListOfCommands=(
                   "sudo apt install -y libgirepository1.0-dev"
                   "sudo apt-get install build-essential"
                   "gcc"
                   "python-dev"
                   "pkg-config"
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
        p $command  >> InstallLogFile 2>&1
        
        done
        ) | $DIALOG --title "Zusätzliche Pakete werden installiert " --gauge "Hier könnte dein Befehl stehen" 20 70 0


    DIALOG=${DIALOG=dialog}

    declare -a ListOfCommands=(
                    "tryton"
                    "pycairo"
                    "Genshi"
                    "lxml" 
                    "passlib" 
                    "pycountry" 
                    "forex_python" 
                    "pkg-resources"
                    "polib" 
                    "psycopg2-binary" 
                    "python-magic"
                    "python-sql" 
                    "relatorio"
                    "Werkzeug" 
                    "wrapt"
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
        echo "Der folgende Befehl wird gerade durchgeführt: pip3 install $command $index/$len"
        echo "XXX"
        pip3 install $command  >> InstallLogFile 2>&1
        
        done
        ) | $DIALOG --title "Zusätzliche Python Pakete werden installiert " --gauge "Hier könnte dein Befehl stehen" 20 70 0

        installPostgresYesNo
}
#dialog liste für mehr tryton_module 
function moreModules(){
    ModulAuswahl=`dialog --checklist "Wählen sie die Module die sie zusätzlich installieren wollen" 0 0 10\
    trytond "" off\
    trytond-account "" off\
    trytond-account-asset "" off\
    trytond-account-be "" off\
    trytond-account-cash-rounding "" off\
    trytond-account-credit-limit "" off\
    trytond-account-de-skr03 "" off\
    trytond-account-deposit "" off\
    trytond-account-dunning "" off\
    trytond-account-dunning-email "" off\
    trytond-account-dunning-fee "" off\
    trytond-account-dunning-letter "" off\
    trytond-account-eu "" off\
    trytond-account-invoice "" off\
    trytond-account-invoice-correction "" off\
    trytond-account-invoice-defer "" off\
    trytond-account-invoice-history "" off\
    trytond-account-invoice-line-standalone "" off\
    trytond-account-invoice-secondary-unit "" off\
    trytond-account-invoice-stock "" off\
    trytond-account-payment "" off\
    trytond-account-payment-braintree "" off\
    trytond-account-payment-clearing "" off\
    trytond-account-payment-sepa "" off\
    trytond-account-payment-sepa-cfonb "" off\
    trytond-account-payment-stripe "" off\
    trytond-account-product "" off\
    trytond-account-statement "" off\
    trytond-account-statement-aeb43 "" off\
    trytond-account-statement-coda "" off\
    trytond-account-statement-ofx "" off\
    trytond-account-statement-rule "" off\
    trytond-account-stock-continental "" off\
    trytond-account-stock-landed-cost "" off\
    trytond-account-stock-landed-cost-weight "" off\
    trytond-account-tax-cash "" off\
    trytond-account-tax-rule-country "" off\
    trytond-analytic-account "" off\
    trytond-analytic-invoice "" off\
    trytond-analytic-purchase "" off\
    trytond-analytic-sale "" off\
    trytond-attendance "" off\
    trytond-authentication-sms "" off\
    trytond-bank "" off\
    trytond-carrier "" off\
    trytond-carrier-percentage "" off\
    trytond-carrier-subdivision "" off\
    trytond-carrier-weight "" off\
    trytond-commission "" off\
    trytond-commission-waiting "" off\
    trytond-company "" off\
    trytond-company-work-time "" off\
    trytond-country "" off\
    trytond-currency "" off\
    trytond-customs "" off\
    trytond-dashboard "" off\
    trytond-edocument-uncefact "" off\
    trytond-edocument-unece "" off\
    trytond-gis "" off\
    trytond-incoterm "" off\
    trytond-ldap-authentication "" off\
    trytond-marketing "" off\
    trytond-marketing-automation "" off\
    trytond-marketing-email "" off\
    trytond-notification-email "" off\
    trytond-party "" off\
    trytond-party-avatar "" off\
    trytond-party-relationship "" off\
    trytond-party-siret "" off\
    trytond-product "" off\
    trytond-product-attribute "" off\
    trytond-product-classification "" off\
    trytond-product-classification-taxonomic "" off\
    trytond-product-cost-fifo "" off\
    trytond-product-cost-history "" off\
    trytond-product-cost-warehouse "" off\
    trytond-product-kit "" off\
    trytond-product-measurements "" off\
    trytond-product-price-list "" off\
    trytond-product-price-list-dates "" off\
    trytond-product-price-list-parent "" off\
    trytond-production "" off\
    trytond-production-outsourcing "" off\
    trytond-production-routing "" off\
    trytond-production-split "" off\
    trytond-production-work "" off\
    trytond-production-work-timesheet "" off\
    trytond-project "" off\
    trytond-project-invoice "" off\
    trytond-project-plan "" off\
    trytond-project-revenue "" off\
    trytond-purchase "" off\
    trytond-purchase-amendment "" off\
    trytond-purchase-history "" off\
    trytond-purchase-invoice-line-standalone "" off\
    trytond-purchase-price-list "" off\
    trytond-purchase-request "" off\
    trytond-purchase-request-quotation "" off\
    trytond-purchase-requisition "" off\
    trytond-purchase-secondary-unit "" off\
    trytond-purchase-shipment-cost "" off\
    trytond-sale "" off\
    trytond-sale-advance-payment "" off\
    trytond-sale-amendment "" off\
    trytond-sale-complaint "" off\
    trytond-sale-credit-limit "" off\
    trytond-sale-discount "" off\
    trytond-sale-extra "" off\
    trytond-sale-gift-card "" off\
    trytond-sale-history "" off\
    trytond-sale-invoice-grouping "" off\
    trytond-sale-opportunity "" off\
    trytond-sale-payment "" off\
    trytond-sale-price-list "" off\
    trytond-sale-product-customer "" off\
    trytond-sale-promotion "" off\
    trytond-sale-promotion-coupon "" off\
    trytond-sale-secondary-unit "" off\
    trytond-sale-shipment-cost "" off\
    trytond-sale-shipment-grouping "" off\
    trytond-sale-shipment-tolerance "" off\
    trytond-sale-stock-quantity "" off\
    trytond-sale-subscription "" off\
    trytond-sale-subscription-asset "" off\
    trytond-sale-supply "" off\
    trytond-sale-supply-drop-shipment "" off\
    trytond-sale-supply-production "" off\
    trytond-stock==6.0.2 "" off\
    trytond-stock-assign-manual "" off\
    trytond-stock-consignment "" off\
    trytond-stock-forecast "" off\
    trytond-stock-inventory-location "" off\
    trytond-stock-location-move "" off\
    trytond-stock-location-sequence "" off\
    trytond-stock-lot "" off\
    trytond-stock-lot-sled "" off\
    trytond-stock-lot-unit "" off\
    trytond-stock-package "" off\
    trytond-stock-package-shipping "" off\
    trytond-stock-package-shipping-dpd "" off\
    trytond-stock-package-shipping-ups "" off\
    trytond-stock-product-location "" off\
    trytond-stock-quantity-early-planning "" off\
    trytond-stock-quantity-issue "" off\
    trytond-stock-secondary-unit "" off\
    trytond-stock-shipment-cost "" off\
    trytond-stock-shipment-measurements "" off\
    trytond-stock-split "" off\
    trytond-stock-supply "" off\
    trytond-stock-supply-day "" off\
    trytond-stock-supply-forecast "" off\
    trytond-stock-supply-production "" off\
    trytond-timesheet "" off\
    trytond-timesheet-cost "" off\
    trytond-user-role "" off\
    trytond-web-user "" off  3>&1 1>&2 2>&3`
    dialog --clear
    clear
    echo "Ihre ausgewählten Module $ModulAuswahl"

    echo "moreModul installation gestartet" >> InstallLogFile 2>&1
    DIALOG=${DIALOG=dialog}

    declare -a ListOfCommands=($ModulAuswahl)
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
        pip3 install $command >> InstallLogFile 2>&1
       # sleep 1
        
    done
    ) | $DIALOG --title "Modul Installation" --gauge "Hier könnte dein Befehl stehen" 20 70 0;


    pythonPakete
}
#dialog liste für tryton module 
function installModules(){
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

    declare -a ListOfCommands=($ModulAuswahl)
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
        pip3 install $command >> InstallLogFile 2>&1
       # sleep 1
        
    done
    ) | $DIALOG --title "Modul Installation" --gauge "Hier könnte dein Befehl stehen" 20 70 0;

    yesNoDialog "Achtung!" "Möchten sie noch weitere Module installieren? Im folgenden können sie aus der Liste aller offiziellen Module aussuchen" 10 80 ;
    response=$?
    case $response in 
        0) moreModules;;
        1) pythonPakete;;
        255) clear; echo "Installations abgebrochen";;
    esac
   
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

#configPostgres


