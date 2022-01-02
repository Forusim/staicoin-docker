#!/bin/bash

cd /stai-blockchain

. ./activate

if [[ $(stai keys show | wc -l) -lt 5 ]]; then
    if [[ ${keys} == "generate" ]]; then
      echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
      stai init && stai keys generate
    elif [[ ${keys} == "copy" ]]; then
      if [[ -z ${ca} ]]; then
        echo "A path to a copy of the farmer peer's ssl/ca required."
        exit
      else
      stai init -c ${ca}
      fi
    elif [[ ${keys} == "type" ]]; then
      stai init
      echo "Call from docker shell: stai keys add"
      echo "Restart the container after mnemonic input"
    else
      stai init && stai keys add -f ${keys}
    fi
    
    sed -i 's/localhost/127.0.0.1/g' ~/.stai/mainnet/config/config.yaml
else
    for p in ${plots_dir//:/ }; do
        mkdir -p ${p}
        if [[ ! "$(ls -A $p)" ]]; then
            echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
        fi
        stai plots add -d ${p}
    done

    if [[ ${farmer} == 'true' ]]; then
      stai start farmer-only
    elif [[ ${harvester} == 'true' ]]; then
      if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
        echo "A farmer peer address, port, and ca path are required."
        exit
      else
        stai configure --set-farmer-peer ${farmer_address}:${farmer_port}
        stai start harvester
      fi
    else
      stai start farmer
    fi
fi

finish () {
    echo "$(date): Shutting down stai"
    stai stop all
    exit 0
}

trap finish SIGTERM SIGINT SIGQUIT

sleep infinity &
wait $!
