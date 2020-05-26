#!/bin/bash
##
###############################################################
#### Welcome to the Wordpress Compressor Bash Script v1.0. ####
###############################################################
##
## Creator: Greg Petersen https://github.com/thebigsnax/wpcbs
##
## Description: This script was developed to allow anyone in a linux web hosting environment to run backups to any or all Wordpress installs.
## It effectively scans the current directory for any wp-config.php files then, upon user interaction, exports the database to a db.sql file,
## tgz's the directory files to the approved location.
##
## Special thanks to:
## - Theme.fm's Konstantin Kovshenin: https://theme.fm/a-shell-script-for-a-complete-wordpress-backup/
## - linuxhint youtube: https://www.youtube.com/watch?v=e7BufAVwDiM
## - Regex101: https://regex101.com/
## - stackoverflow: https://stackoverflow.com/questions/8467424/echo-newline-in-bash-prints-literal-n
## - stackoverflow: https://stackoverflow.com/questions/7442417/how-to-sort-an-array-in-bash
## - stackoverflow: https://stackoverflow.com/questions/246215/how-can-i-generate-a-list-of-files-with-their-absolute-path-in-linux
## - stackoverflow: https://stackoverflow.com/questions/16860877/remove-an-element-from-a-bash-array
## - stackoverflow: https://stackoverflow.com/questions/23356779/how-can-i-store-the-find-command-results-as-an-array-in-bash
## - stackexchange: https://unix.stackexchange.com/questions/33110/using-sed-to-get-rid-of-characters
## - stackoverflow: https://stackoverflow.com/questions/2250131/how-do-you-append-to-an-already-existing-string
## - stackoverflow: https://stackoverflow.com/questions/24545276/execute-mysql-query-in-shell-script

## Initiralize variables and arrays
init () {

  ## Remove this script message
  MSG_REMOVE="\n\nPLEASE REMEMBER TO REMOVE THIS SCRIPT WHEN YOU ARE DONE!\n"

  ## Invalid response message
  MSG_INVALID="Invalid response. Please try again."

  ## Todays Date and time for filename
  NOW=$(date +"%Y.%m.%d.%H%M")

  ## Location of wp-config.php
  EACH_LOC_WP_CONFIG=()

  ## Absolute path of all installs
  EACH_WP_LOC=()

  ## Sorted list of EACH_LOC_WP_CONFIG
  EACH_LOC_WP_CONFIG_SORT=()

  ## Remove wp-config.php from string
  REMOVE_WP_CONFIG=(wp-config.php)

  ## All information gathered from wp-config.php
  EACH_WP_NAME=()
  EACH_WP_PASS=()
  EACH_WP_USER=()
  EACH_WP_HOST=()
  EACH_WP_PREF=()
  EACH_WP_OURL=()

  ## Get current directory
  current_dir=$(pwd)/

  ## Question 2 continue or not
  Q2CONTINUE=false

}

## Show welcome screen and start searching for installs
welcomeScreen () {

  ## Welcome screen
  echo -e "\n\n###################################################\n## Wordpress Compressor Bash Script (WPCBS) v1.0 ##\n###################################################\n\nNOTE: Be sure to chmod +x this file to make it executable\nExample: chmod +x wpcbs.sh$MSG_REMOVE"

  ## Go to question 1
  questionOne
}

## Ask the user if they would like to continue
questionOne () {

  while [ "$ANS_CONTINUE" != "y" ] || [ "$ANS_CONTINUE" != "Y" ] || [ "$ANS_CONTINUE" != "n" ] || [ "$ANS_CONTINUE" != "N" ]; do

    ## Ask user to continue
    read -p "Are you ready to scan everything in this directory? (y/N): " ANS_CONTINUE

    ## Check for YES response
    if [ "$ANS_CONTINUE" == "y" ] || [ "$ANS_CONTINUE" == "Y" ]; then
      echo -e "\n\nPlease wait...\n"
      wpConfigSearch  
    fi

    ## Check for NO response
    if [ "$ANS_CONTINUE" == "n" ] || [ "$ANS_CONTINUE" == "N" ] || [ -z "$ANS_CONTINUE" ]; then
      echo -e "\nExiting...$MSG_REMOVE"
      exit
    else
      echo -e "$MSG_INVALID"
    fi

  done
}

## Find all wordpress installs
wpConfigSearch () {

  while IFS=  read -r -d $'\0'; do
    EACH_LOC_WP_CONFIG+=("$REPLY")
  done < <(find "$(pwd)" -type f -name "wp-config.php" -print0)

  ## Sort the list
  IFS=$'\n' EACH_LOC_WP_CONFIG_SORT=($(sort <<<"${EACH_LOC_WP_CONFIG[*]}")); unset IFS

  ## Remove wp-config.php from each entry
  EACH_WP_LOC=( "${EACH_LOC_WP_CONFIG_SORT[@]/$REMOVE_WP_CONFIG}" )

  ## Check if there were any Wordpress installs
  if [ -z "$EACH_WP_LOC" ]; then
    echo -e "\nNo Wordpress installs were found. Please move this script to the root directory of your installs and try again.$MSG_REMOVE"
    exit
  else

    ## Scrape all WP installs for db info and url
    i=0
    for each in "${EACH_WP_LOC[@]}"; do
      EACH_WP_NAME+=("$(grep -oP "DB_NAME'\s*,\s*'\K.+(?=')" $each/wp-config.php)")
      EACH_WP_PASS+=("$(grep -oP "DB_PASSWORD'\s*,\s*'\K.+(?=')" $each/wp-config.php)")
      EACH_WP_USER+=("$(grep -oP "DB_USER'\s*,\s*'\K.+(?=')" $each/wp-config.php)")
      EACH_WP_HOST+=("$(grep -oP "DB_HOST'\s*,\s*'\K.+(?=')" $each/wp-config.php)")
      EACH_WP_PREF+=("$(grep -oP "[\$]table_prefix\s*=\s*'\K.*(?=')" $each/wp-config.php)")
      EACH_WP_OURL+=("$(mysql -N -B -h${EACH_WP_HOST[$i]} -u${EACH_WP_USER[$i]} -p${EACH_WP_PASS[$i]} -e"SELECT option_value FROM ${EACH_WP_PREF[$i]}options WHERE option_name='siteurl';" ${EACH_WP_NAME[$i]} | sed -e 's/https*:\/\///g;s/\/$//g')")
      ((i=i+1))
    done

    ## List all installs found
    echo -e "Here are the locations of all the Wordpress installs found:\n"
    thisnum=1
    for each in "${EACH_WP_OURL[@]}"; do
      echo $thisnum: $each
      ((thisnum=thisnum+1))
    done    

    questionTwo

  fi
}

## Ask user which installs they want to back up
questionTwo () {
  
  while [ "$ANS_INSTALLS" != 0 ] && [ "$Q2CONTINUE" == false ]; do
    
    ## Ask which installs are desired
    echo -e "\nWhich installs would you like to backup?"
    read -p "(Enter number(s) seperated by commas (,) or press 0 for ALL): " ANS_INSTALLS

    ## Check if answer contains numbers and commas
    if [[ $ANS_INSTALLS =~ ^[0-9\,]*$ ]]; then
      
      ## Check if answer begins and ends with a number
      if [[ $ANS_INSTALLS =~ ^[0-9] ]] && [[ $ANS_INSTALLS =~ [0-9]$ ]]; then

        ## Check if there are double commas
        if [[ $ANS_INSTALLS =~ \,\, ]]; then
          echo -e "$MSG_INVALID Answer can only have single commas."
        else
          ANS_INS_ARRAY=(${ANS_INSTALLS//,/ })
          
          ANS_EXISTS=true
          ## Check if the answers exist
          for i in "${ANS_INS_ARRAY[@]}"; do
            ((i=i-1))
            if [ -z "${EACH_WP_LOC[$i]}" ]; then
              ANS_EXISTS=false
            fi
          done

          ## Tell user the answer does not exist
          if [ "$ANS_EXISTS" == false ];then
            Q2CONTINUE=false
            echo -e "$MSG_INVALID Answer does not exist as an option."
          else
            Q2CONTINUE=true
          fi
        fi
      else
        echo -e "$MSG_INVALID Answer can only begin and end with a number."
      fi
    else
      echo -e "$MSG_INVALID Answer can only contain numbers or commas."
    fi
  done

  ## Prepair the url for filename
  wpRemoveSlashes
  
  ## Ask where to store the backups
  questionThree

}

## Ask where to store the backups
questionThree () {
  ## Continue to ask where backups are stored until it is correct and writeable
  while [ -z "$APPROVED_LOCATION" ]; do

    ## Ask where to store the backups
    echo -e "\nWhere would you like to store the backups?"
    read -p "(Enter absolute path with trailing slash (/), or ENTER for $current_dir ): " ANS_LOCATION

    ## Set current directory if ENTER was pressed
    if [ -z "$ANS_LOCATION" ]; then
      ANS_LOCATION=$current_dir
    fi

      ## Check for beginning and trailing slashes
    if [[ "$ANS_LOCATION" != \/* ]] || [[ "$ANS_LOCATION" != *\/ ]]; then
      echo -e "Your path needs to begin and end with a forward slash (/)"
    
    else

      ## Test if ANS_LOCATION will work
      if [ -w "$ANS_LOCATION" ]; then
        BAD_DIR=false

        ## Check if location is in any of the root directories of wp-config.php
        if [ "$ANS_INSTALLS" == 0 ]; then
          for each in "${EACH_WP_LOC[@]}"; do
            if [ "$each" == "$ANS_LOCATION" ]; then
              BAD_DIR=true
            fi
          done 
        else
          for each in "${ANS_INS_ARRAY[@]}"; do
            ((each=each-1))
            if [ "${EACH_WP_LOC[$each]}" == "$ANS_LOCATION" ]; then
              BAD_DIR=true
            fi
          done 
        fi
        if [ "$BAD_DIR" == true ]; then
          echo -e "The directory cannot equal the website root directory. Please create a directory to compress to."
        else
          APPROVED_LOCATION=$ANS_LOCATION
        fi
      else
        echo -e "The location: $ANS_LOCATION in not writeable.\n"
      fi
    fi
  done

  ## Send off to compressor
  wpCompressor
}

## Cleanup slashes in OURL
wpRemoveSlashes() {
  i=0
  for each in "${EACH_WP_LOC[@]}"; do
    EACH_WP_OURL[i]=${EACH_WP_OURL[i]//\//.}
    ((i=i+1))
  done
}

## Let's compress everything
wpCompressor () {
  echo -e "\n\nPlease wait..."

  ## Compress all
  if [ "$ANS_INS_ARRAY" -eq 0 ]; then
    ii=0
    for i in "${EACH_WP_LOC[@]}"; do
      echo -e "\nCompressing: "${APPROVED_LOCATION}_${EACH_WP_OURL[$ii]}.${NOW}.bak.tgz
      mysqldump -h${EACH_WP_HOST[$ii]} -u${EACH_WP_USER[$ii]} -p${EACH_WP_PASS[$ii]} ${EACH_WP_NAME[$ii]} > ${EACH_WP_LOC[$ii]}db.sql
      tar -czf ${APPROVED_LOCATION}_${EACH_WP_OURL[$ii]}.${NOW}.bak.tgz -C ${EACH_WP_LOC[$ii]} .
      rm -rf "${EACH_WP_LOC[$ii]}"db.sql
      ((ii=ii+1))
    done

  ## Compress selected  
  else
    for i in "${ANS_INS_ARRAY[@]}"; do
      ((i=i-1))
      echo -e "\nCompressing: "${APPROVED_LOCATION}_${EACH_WP_OURL[$i]}.${NOW}.bak.tgz
      mysqldump -h${EACH_WP_HOST[$i]} -u${EACH_WP_USER[$i]} -p${EACH_WP_PASS[$i]} ${EACH_WP_NAME[$i]} > ${EACH_WP_LOC[$i]}db.sql
      tar -czf ${APPROVED_LOCATION}_${EACH_WP_OURL[$i]}.${NOW}.bak.tgz -C ${EACH_WP_LOC[$i]} .
      rm -rf "${EACH_WP_LOC[$i]}"db.sql
    done
  fi

  ## Show success message
  echo -e "\nCompleted Successfully!$MSG_REMOVE"

  ## GET OUTTA HERE
  exit
}

init
welcomeScreen
