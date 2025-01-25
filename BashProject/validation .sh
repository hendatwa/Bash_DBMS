#! /bin/bash
proj_dir="$(pwd)"
database_dir="$proj_dir/databases"

if ! [[ -d "$database_dir" ]]; then
    mkdir -p "$database_dir"
fi

AllDatabasesName=()

#Variables to check the path
proj_dir="$(pwd)"
database_dir="$proj_dir/databases"

if ! [[ -d "$proj_dir/databases" ]]; then
    mkdir "$database_dir"
fi
current_database="database_dir"
update_database_list() {
    AllDatabasesName=($(ls -d "$database_dir"/*/ 2>/dev/null | xargs -n 1 basename))
}
#fucntion to make sure we are in the correct project directory
AllDatabasesName=($(ls -d "$database_dir"/*/ 2>/dev/null | xargs -n 1 basename))
correct_proj_directory() {
  if [ "$(pwd)" != "$proj_dir" ]; then
    echo "Wrong directory, we will move to the correct one."
    cd "$proj_dir"
  fi
}
#fucntion to make sure we are navigating the databases files
correct_database_directory() {
  if [ "$(pwd)" != "$database_dir" ]; then
    echo "Not the correct directory, we are moving to $database_dir"
    cd "$database_dir"
  fi
}
validate_database_name(){
    read -rp "Enter Database Name: " DBName
    while ! [[ $DBName =~ ^[a-zA-Z][A-Za-z0-9_-]*[a-zA-Z0-9]$ ]]
    do
        echo "Error invalid Database Name."
        read -rp "Enter Database Name again: " DBName
    done
}
# correct_connect_database(){    
# }
has_databases() {
    update_database_list
    if [[ ${#AllDatabasesName[@]} -eq 0 ]]; then
        return 1
    fi
    return 0
}
return_to_mainmenu(){
  read -rp "Want to return to Main Menu (y) ?: " ReturnMenu
  if [[ $ReturnMenu == "y" ]];then
    MainMenu
    exit 0
    else
      exit 0
  fi 
}
validate_table_name() {
  table_name="$1"

  # Check if the table name starts with a letter and contains only alphanumeric characters and underscores
  if [[ "$table_name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
    return 0 # Valid table name
  else
    echo "Invalid table name: $table_name"
    echo "Table names must start with a letter and can contain only letters, numbers, and underscores."
    return 1 # Invalid table name
  fi
}
