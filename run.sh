#! /usr/bin/env bash
# Function to check if a command exists
check_command() {
    local command_name=$1

    if command -v $command_name &> /dev/null
    then
        echo "$command_name is installed"
        return 0
    else
        echo "$command_name is not installed"
        return 1
    fi
}

check_req() {
    check_command pm2
    if [ ! $? -eq 0 ]
    then  
        exit 1
    fi
    check_command bun
    if [ ! $? -eq 0 ]
    then  
        exit 1
    fi
}

check_req
read -p 'Key file name(default for pk.key): ' key_file
key_file=${key_file:-pk.key}
read -p 'Enter what you want to: ' action
case $action in
    init)
        read -p 'Enter the walelts your want to create: ' num
        # if it's a number
        if ! [[ "$num" =~ ^[0-9]+$ ]]; then
          echo "Sorry, enter integers only"
          exit 0
        fi
        for i in {1..$num}; do 
            result=$(bun src/cli/index.ts create-wallet); 
            private=$(echo $result | grep Priv | cut -d ' ' -f 3); 
            public=$(echo $result| grep Wallet | cut -d ' ' -f 3); 
            echo -n "$i:\t"; echo "$private $public" | tee -a $key_file; 
        done
        ;;
    start)
        if [ -f "$key_file" ]; then
            while IFS= read -r sui_key; do
                # as \t is not that compatible for all shells, the IFS should be $'\t', but we could use simplest one, a space
                IFS=' ' read -r private public <<< "$sui_key"
            echo 'start:' $public
                # echo ${sui_key:0:16}
                WALLET=$private pm2 start --name ${public} "bun run src/cli/index.ts -- mine"
            done <"$key_file"
            echo "end!"
        else
            echo "key file not found"
        fi
        ;;
    *)
        echo 'Command should be one of init,start,'
        ;;
esac


