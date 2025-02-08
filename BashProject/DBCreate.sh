#! /bin/bash
#shopt -s extglob
source ./validation.sh
source ./TableMenu.sh
LC_COLLATE=C
DBCreate(){
    echo -e "----------------Create Database-------------------- \n"
    validate_database_name 
    #database_dir="$database_dir/$DBName"
    if [[ -d "$database_dir/$DBName" ]];then
        echo "Error: Database already exist"
        source DBCreate.sh
        else 
            mkdir "$database_dir/$DBName"
            echo "Database created Successfully."
            #if want to return to main menu
            return_to_mainmenu
    fi
}
DBConnect(){
    echo -e "----------------Connect Database-------------------- \n"
    if has_databases; then
        local PS3="ConnectChoice>> "
        select choice in "${AllDatabasesName[@]}" "Cancel";
        do
            REPLY=$REPLY-1
            if [[ $choice == "Cancel" ]]; then
                break
            elif [[ -n "$choice" ]]; then
                cd "$database_dir/$choice" 
                current_database="$database_dir/$choice"
                db_menu
                break
            else
                echo "Invalid choice Try again."
            fi
        done
    else
            echo "There is no Database Created. "
    fi

}
DBDrop(){
    echo -e "----------------Drop Database-------------------- \n"
    if has_databases; then
    local PS3="DroptChoice>> "
    COLUMNS=1
    select choice in "${AllDatabasesName[@]}" "Cancel";
    do
        REPLY=$REPLY-1
        if [[ $choice == "Cancel" ]]; then
            break
        elif [[ -n "$choice" ]]; then
            rm -r "$database_dir/$choice" 
            echo "Data base $choice Droped Successfully."
            break
        else
            echo "Invalid choice Try again."
        fi
    done
    else
        echo "There is no Database Created. "
    fi

}
DBList(){

    #list all databases names
    #ls -F | grep '/$' | tr '/' ' '
    #if isn't there datatbases echo "there is no databases want to create database (y):"
    #DBCreate
    cd "$database_dir"
    echo "$PWD"
    if has_databases; then
        echo -e "--------------------- All Databases Name ------------------------- \n"
        for db in "${AllDatabasesName[@]}"; do
            echo "$db"
        done
        return_to_mainmenu
        else
            echo "There is no Database Created. "
            read -rp "Want to Create Database (y)?: " CreateDB
            if [[ $CreateDB == "y" ]];then
                DBCreate
                else
                    exit 0
            fi 
    fi

 }
MainMenu(){
    PS3="DBChoices>> "
    COLUMNS=1
    DBMenu=("List DataBase" "Connect DataBase" "Create DataBase" "Drop DataBase" "Exit")

    echo -e "-------------------- Database Management System --------------------- \n"

    select choice in "${DBMenu[@]}"; 
    do 
        case $choice in
        "List DataBase")
            DBList
        ;;
        "Connect DataBase")
            DBConnect
            break
        ;;
        "Create DataBase")
            DBCreate
            break
        ;;
        "Drop DataBase")
            DBDrop
            break
        ;;
        Exit)
            break
        ;;
        *)
            echo "Invalid choice Try again."
        ;;
        esac

    done
}

MainMenu
