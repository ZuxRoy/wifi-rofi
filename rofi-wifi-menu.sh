#!/usr/bin/env bash

connect_wifi() {
    notify-send "Fetching available Wi-Fi networks ..." -r 9991 -u normal
    sleep 2
    dunstctl close

    current=$(nmcli -t -f active,ssid dev wifi | awk -F: '/^yes/ {print $2}')
    wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | sed 's/  */ /g' | sed -E "s/WPA*.?\S/ /g" | sed "s/^--/ /g" | sed "s/  //g" | sed "/--/d")

    if [ -n "$current" ]; then
        wifi_list=$(echo "$wifi_list" | grep -v "$current")
        wifi_list="󰖩  $current [connected]\n$wifi_list"
    fi

    choice=$(echo -e "$toggle\n$wifi_list" | uniq -u | rofi -dmenu -i -selected-row 1 -theme-str 'entry { enabled: false;} prompt { enabled: false; }')

    if [ -z "$choice" ]; then
        exit
    fi

    ssid=$(echo "$choice" | awk '{$1=""; print $0}' | sed 's/^ *//' | sed 's/ \[connected\]//')

    if [[ "$choice" = "$toggle" ]]; then
        nmcli radio wifi off
        notify-send "Wi-Fi Disabled" -r 9991 -u normal -t 5000 -i "$HOME/.local/share/icons/custom/wifi-disconnected.svg"
        sleep 2
        dunstctl close
        exit
    fi

    if [[ "$ssid" = "$current" ]]; then
        notify-send "Already connected to $ssid" -r 9991 -u normal -t 5000 
        exit
    else
        saved=$(nmcli -g NAME connection)
        if [[ $(echo "$saved" | grep -w "$ssid") = "$ssid" ]]; then
            nmcli connection up id "$ssid" | grep "successfully" && notify-send "Connection Established" "Connected to $ssid" -t 5000 -r 9991 -i "$HOME/.local/share/icons/custom/wifi-connected.svg" && exit
        fi
        if [[ "$choice" =~ "" ]]; then
            password=$(rofi -dmenu -p "Password: " -l 0)
        fi
        if nmcli device wifi connect "$ssid" password "$password" | grep "successfully"; then
            notify-send "Connection Established" "Connected to $ssid" -t 5000 -r 9991 -i "$HOME/.local/share/icons/custom/wifi-connected.svg"
        else
            notify-send "Connection Failed" "Could not connect to $ssid" -t 5000 -r 9991 -i "$HOME/.local/share/icons/custom/wifi-locked.svg"
        fi
    fi
}

status=$(nmcli -fields WIFI g | sed -n 2p)
if [[ "$status" =~ "enabled" ]]; then
    toggle="󰖪  Disable Wi-Fi"
    flag=1
elif [[ "$status" =~ "disabled" ]]; then
    toggle="󰖩  Enable Wi-Fi"
    flag=0
fi

if [ "$flag" -eq 1 ]; then
    connect_wifi
else
    choice=$(echo -e "$toggle" | rofi -dmenu -i -selected-row 1 -p "Wi-Fi" -theme-str 'entry { enabled: false;} prompt { enabled: false; }')
    if [[ "$choice" = "$toggle" ]]; then
        nmcli radio wifi on
        toggle="󰖪  Disable Wi-Fi"
        notify-send "Wi-Fi Enabled" -r 9991 -u normal -i "$HOME/.local/share/icons/custom/wifi-connected.svg" -t 5000 
        sleep 5
        connect_wifi 
    fi
fi

