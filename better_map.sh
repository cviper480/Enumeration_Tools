#!/bin/bash
# Usage: ./better_map.sh <target>
# Example: ./better_map.sh 192.168.216.121

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <target>"
  exit 1
fi

target="$1"

# ANSI escape code for pink (light magenta) is \033[95m, reset with \033[0m
pink="\033[95m"
reset="\033[0m"

#########################
# 1. Full TCP Scan (-p-)
#########################
tmpfile=$(mktemp)

echo -e "${pink}===================================================${reset}"
echo -e "${pink}Running full TCP scan (-p-) on $target${reset}"
echo -e "${pink}===================================================${reset}"
nmap --min-rate 4500 --max-rtt-timeout 1500ms -p- -Pn -vv "$target" -oN "$tmpfile"

# Extract the final report lines showing open TCP ports and remove duplicates.
open_port_lines=$(grep -E '^[0-9]+/tcp[[:space:]]+open' "$tmpfile" | sort -u)
if [ -z "$open_port_lines" ]; then
  echo "No open TCP ports found on $target."
  rm "$tmpfile"
  exit 0
fi

# Print the open TCP port lines in green.
#echo -e "\033[0;32m$open_port_lines\033[0m"

# Build a comma-separated list of unique open TCP port numbers with no extra spaces.
open_ports=$(echo "$open_port_lines" | awk '{print $1}' | sed 's/\/tcp//' | sort -u | paste -sd, - | tr -d ' ')
rm "$tmpfile"

#########################
# 2. UDP Scan (-sU)
#########################
echo -e "${pink}===================================================${reset}"
echo -e "${pink}Running UDP scan (-sU) on $target${reset}"
echo -e "${pink}===================================================${reset}"
nmap --min-rate 4500 --max-rtt-timeout 1500ms -sU -Pn --top-ports=20 -vv "$target"

#########################
# 3. Final TCP Scan (-sCV)
#########################
echo -e "${pink}===================================================${reset}"
echo -e "${pink}Running final TCP scan (-sCV) on ports: $open_ports${reset}"
echo -e "${pink}===================================================${reset}"
nmap -sCV -Pn --script-timeout 15s -p "$open_ports" "$target"
