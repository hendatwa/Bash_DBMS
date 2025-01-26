#!/bin/bash

source "validation.sh"
db_menu() {
  while true; do
    echo "    Database Menu:
    ----------------------"
    echo "1. Create Table"
    echo "2. Drop Table"
    echo "3. Insert Record"
    echo "4. Update Record"
    echo "5. Truncate Table"
    echo "6. List Tables"
    echo "7. Select"
    echo "8. Exit"
    read -p "Choose an option: " option
    case $option in
      1) create_table ;;
      2) drop_table ;;
      3) echo "insert_record" ;;
      4) echo "update_record" ;;
      5) truncate_table ;;
      6) list_tables ;;
      7) select_from_table ;;
      8) cd ..; break ;;
      
      *) echo "---------------Invalid option!---------------" ;;
    esac
  done
}

##Call the db_menu function to start the menu
##db_menu
create_table() {
  while true; do
    echo "Enter your table name (or type 'exit' to return to the menu):"
    read -r table_name

    if [[ "$table_name" == "exit" ]]; then
      echo "Returning to the menu..."
      return
    fi

    if validate_table_name "$table_name"; then
      table_file="$current_database/$table_name.txt"
      metadata_file="$current_database/${table_name}_meta.txt"

      if [ -f "$table_file" ] || [ -f "$metadata_file" ]; then
        echo "Table '$table_name' already exists. Please choose another name."
      else
        break
      fi
    else
      echo "Invalid table name. Avoid special characters."
    fi
  done

  while true; do
    echo "Enter the columns and their types (e.g., col1:INT,col2:STRING, or type 'exit' to return):"
    read -r columns

    if [[ "$columns" == "exit" ]]; then
      echo "Returning to the menu..."
      return
    fi

    if [[ "$columns" =~ ^([a-zA-Z_][a-zA-Z0-9_]*:(INT|STRING|FLOAT))(,[a-zA-Z_][a-zA-Z0-9_]*:(INT|STRING|FLOAT))*$ ]]; then
      break
    else
      echo "Invalid column format. Use format: col1:INT,col2:STRING."
    fi
  done

  # Create the table with the header (column names as the first row)
  header=$(echo "$columns" | sed 's/,/ /g' | awk -F':' '{print $1}' | paste -sd, -)
  echo "$header" > "$table_file"  # Write the header to the table file
  echo "$columns" > "$metadata_file"
  
  touch "$table_file"
  echo "Table '$table_name' created successfully with metadata and header."
}
drop_table() {
echo "Available tables:"
  ls "$current_database" | grep -E '\.txt$' | sed 's/.txt$//' | grep -v '_meta'
  echo ""
  echo "Enter the table name to drop:"
  read -r table_name

  table_file="$current_database/$table_name.txt"
  metadata_file="$current_database/${table_name}_meta.txt"

  if [ -f "$table_file" ] && [ -f "$metadata_file" ]; then
    rm "$table_file" "$metadata_file"
    echo "Table '$table_name' and its metadata have been deleted."
  else
    echo "Table '$table_name' does not exist."
  fi
}
truncate_table() {
  echo "Available tables:"
  ls "$current_database" | grep -E '\.txt$' | sed 's/.txt$//' | grep -v '_meta'
  echo "------------------"

  echo "Enter the table name to truncate (or type 'exit' to return):"
  read -r table_name

  if [[ "$table_name" == "exit" ]]; then
    echo "Returning to the menu..."
    return
  fi

  table_file="$current_database/$table_name.txt"
  metadata_file="$current_database/${table_name}_meta.txt"

  if [[ ! -f "$table_file" || ! -f "$metadata_file" ]]; then
    echo "Table '$table_name' does not exist or its metadata is missing."
    return
  fi

  echo "Enter type of truncation (all/record):"
  read -r trunc_type

  if [[ "$trunc_type" == "all" ]]; then
    head -n 1 "$table_file" > temp && mv temp "$table_file"
    echo "All records in '$table_name' have been deleted."
  elif [[ "$trunc_type" == "record" ]]; then
    # Extract column names
    header=$(head -n 1 "$metadata_file" | tr ',' '\n' | awk -F':' '{print $1}' | xargs)
    echo "Available columns: $header"

    echo "Enter the column name for the condition:"
    read -r col_name
    echo "Enter the operator (==, !=, <, >, <=, >=):"
    read -r operator
    echo "Enter the value:"
    read -r value

    metadata=$(head -n 1 "$metadata_file")
    IFS=',' read -ra columns <<< "$metadata"
    col_number=-1

    for i in "${!columns[@]}"; do
      column_name=$(echo "${columns[$i]}" | cut -d':' -f1)  # Extract column name
      if [[ "$column_name" == "$col_name" ]]; then
        col_number=$((i + 1))  # Adding 1 since awk uses 1-based indexing
        break
      fi
    done

    if [[ $col_number -eq -1 ]]; then
      echo "Column '$col_name' not found in '$table_name'."
    elif [[ $operator != "==" && $operator != "!=" && $operator != "<" && $operator != ">" && $operator != "<=" && $operator != ">=" ]]; then
      echo "Invalid operator."
    else
      # Truncate the matching records based on condition
      awk -F',' -v col="$col_number" -v op="$operator" -v val="$value" '
      BEGIN { OFS=FS }
      NR == 1 { print; next }
      {
        col_value = $col
        if ((op == "==" && col_value == val) ||
            (op == "!=" && col_value != val) ||
            (op == "<" && col_value + 0 < val + 0) ||
            (op == ">" && col_value + 0 > val + 0) ||
            (op == "<=" && col_value + 0 <= val + 0) ||
            (op == ">=" && col_value + 0 >= val + 0)) {
          next  # Skip this row (delete it)
        }
        print $0
      }' "$table_file" > temp && mv temp "$table_file" && echo "Matching rows have been deleted from '$table_name'."
    fi
  fi
}

list_tables() {
  echo "Available tables:"
  ls "$current_database" | grep -E '\.txt$' | sed 's/.txt$//' | grep -v '_meta'
  echo ""
}

select_from_table() {
  echo -e "\nAvailable Tables:"
  ls "$current_database" | grep -E '\.txt$' | sed 's/.txt$//' | grep -v '_meta' | sort
  echo ""

  echo "Enter the table name to select from (or type 'exit' to return):"
  read -r table_name

  if [[ "$table_name" == "exit" ]]; then
    echo "Returning to the menu..."
    return
  fi

  table_file="$current_database/$table_name.txt"
  metadata_file="$current_database/${table_name}_meta.txt"

  if [[ ! -f "$table_file" || ! -f "$metadata_file" ]]; then
    echo "Table '$table_name' does not exist or its metadata is missing."
    return
  fi

  echo "Enter type of selection (all/record):"
  read -r select_type

  if [[ "$select_type" == "all" ]]; then
    # Displaying all records
    echo "Displaying all records from '$table_name':"
    echo "---------------------------------------------"
    tail -n +2 "$table_file"  # Skip header row
    echo "---------------------------------------------"
  elif [[ "$select_type" == "record" ]]; then
    # Extract column names
    header=$(head -n 1 "$metadata_file" | tr ',' '\n' | awk -F':' '{print $1}' | xargs)
    echo "Available Columns: $header"

    echo "Enter the column name for the condition:"
    read -r col_name
    echo "Enter the operator (==, !=, <, >, <=, >=):"
    read -r operator
    echo "Enter the value:"
    read -r value

    metadata=$(head -n 1 "$metadata_file")
    IFS=',' read -ra columns <<< "$metadata"
    col_number=-1

    # Identify column number based on the column name
    for i in "${!columns[@]}"; do
      column_name=$(echo "${columns[$i]}" | cut -d':' -f1)  # Extract column name
      if [[ "$column_name" == "$col_name" ]]; then
        col_number=$((i + 1))  # Adding 1 since awk uses 1-based indexing
        break
      fi
    done

    if [[ $col_number -eq -1 ]]; then
      echo "Column '$col_name' not found in '$table_name'."
    elif [[ $operator != "==" && $operator != "!=" && $operator != "<" && $operator != ">" && $operator != "<=" && $operator != ">=" ]]; then
      echo "Invalid operator."
    else
      # Displaying matching records using awk
      echo "Displaying matching records from '$table_name':"
      echo "---------------------------------------------"
      
      awk -F',' -v col="$col_number" -v op="$operator" -v val="$value" '
      BEGIN { OFS=FS }
      NR == 1 { print; next }
      {
        col_value = $col
        if ((op == "==" && col_value == val) ||
            (op == "!=" && col_value != val) ||
            (op == "<" && col_value + 0 < val + 0) ||
            (op == ">" && col_value + 0 > val + 0) ||
            (op == "<=" && col_value + 0 <= val + 0) ||
            (op == ">=" && col_value + 0 >= val + 0)) {
          print $0
        }
      }' "$table_file"
      
      echo "---------------------------------------------"
    fi
  else
    echo "Invalid selection type. Please enter 'all' or 'record'."
  fi
}