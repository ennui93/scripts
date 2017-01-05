#!/bin/sh

# Send an e-mail containing the system's IP address when it changes. Usually configured to run regularly using cron.
# The sendEmail command can be found at the below URL, though many package manager already offer it.
# http://caspian.dotconf.net/menu/Software/SendEmail/

EMAILADDR="REPLACEME@example.com"
SMTPSERVER='REPLACEME'
LASTIPFILE="/tmp/.lastIPmsg"

### Configuration section ends

fail ()
{
    printf "$1" 1>&2
    exit 1
}

command -v sendEmail >/dev/null 2>&1 || fail "Couldn't locate sendEmail command"

IPV4ADDR=$(/sbin/ifconfig | grep -Po "inet addr:.+Bcast" | grep -Po '(?:\d{1,3}\.){3}\d{1,3}')
IPV6ADDR=$(/sbin/ifconfig | grep -Po "inet6 addr:.+Scope:Global" | grep -Po 
'(?>(?>([a-f0-9]{1,4})(?>:(?1)){7}|(?!(?:.*[a-f0-9](?>:|$)){8,})((?1)(?>:(?1)){0,6})?::(?2)?)|(?>(?>(?1)(?>:(?1)){5}:|(?!(?:.*[a-f0-9]:){6,})(?3)?::(?>((?1)(?>:(?1)){0,4}):)?)?(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(?>\.(?4)){3}))')
DATE=$(date)
MACHINENAME=$(uname -n)

generate_last_ip_file () {
  printf "${MACHINENAME}\n\n" > "${LASTIPFILE}"
  printf "IPv4 Address:\t${IPV4ADDR}\n" >> "${LASTIPFILE}"
  printf "IPv6 Address:\t${IPV6ADDR}\n" >> "${LASTIPFILE}"
}

send_email () {
  sendEmail -f "${EMAILADDR}" -t "${EMAILADDR}" -s "${SMTPSERVER}" -u "${DATE}: ${MACHINENAME} - ${IPV4ADDR}" -o message-file="${LASTIPFILE}"
}

touch "${LASTIPFILE}"

if [ $(grep -c -e "${IPV4ADDR}" -e "${IPV6ADDR}" "${LASTIPFILE}") -ge 2 ]
then
  exit 0
fi

generate_last_ip_file
send_email
