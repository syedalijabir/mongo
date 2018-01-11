#!/bin/bash -x
#
# Owner: Ali Jabir
# Email: syedalijabir@gmail.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Color codes
ERROR='\033[1;31m'
GREEN='\033[0;32m'
TORQ='\033[0;96m'
HEAD='\033[44m'
INFO='\033[0;33m'
NORM='\033[0m'

supported_ver=(16.04)
version="3.2"

# Figure out directories
working_dir="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
base_dir=$(dirname "$working_dir")

function log() {
  echo -e "[$(basename $0)] $@"
}

function tryexec() {
  "$@"
  retval=$?
  [[ $retval -eq 0 ]] && return 0

  log 'A command has failed:'
  log "  $@"
  log "Value returned: ${retval}"
  print_stack
  exit $retval
}

function print_stack() {
  local i
  local stack_size=${#FUNCNAME[@]}
  log "Stack trace (most recent call first):"
  # to avoid noise we start with 1, to skip the current function
  for (( i=1; i<$stack_size ; i++ )); do
    local func="${FUNCNAME[$i]}"
    [[ -z "$func" ]] && func='MAIN'
    local line="${BASH_LINENO[(( i - 1 ))]}"
    local src="${BASH_SOURCE[$i]}"
    [[ -z "$src" ]] && src='UNKNOWN'

    log "  $i: File '$src', line $line, function '$func'"
  done
}

# Usage function for the script
function usage () {
  cat << DELIM__
usage: $(basename $0) [options] [parameter]

Options:
  -v, --version         MongoDB version to be installed. Default 3.2
  -h, --help            Display help menu
DELIM__
}

# Check Ubuntu
if [[ -f /etc/os-release  ]]; then
  ver=$(lsb_release -a | grep Release | awk '{print $2}')
  if [[ ! ${os} =~ ${supported_os} ]]; then
    log "${ERROR}Ubuntu version [${ver}] is not supported.${NORM}"
    log "${INFO}Supported OS: ${supported_ver[*]}${NORM}"
    exit 1
  fi
  log "System version: ${ver}"
else
  log "${ERROR}Only Ubuntu platform is supported.${NORM}"
fi

# read the options
TEMP=$(getopt -o v:h --long version:,help -n 'installer.sh' -- "$@")
if [[ $? -ne 0 ]]; then
  usage
  exit 1
fi
eval set -- "$TEMP"

# extract options
while true ; do
  case "$1" in
    -v|--version) version=$2 ; shift 2 ;;
    -h|--help) usage ; exit 1 ;;
    --) shift ; break ;;
    *) usage ; exit 1 ;;
  esac
done

# Import public key
tryexec sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
log "${GREEN}Public key added successfully.${NORM}"
# Create source list
tryexec echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/${version} multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
# Update sources
tryexec sudo apt-get update
log "${GREEN}apt-update successful.${NORM}"

# Install mongoDB
dpkg -l mongodb-org &> /dev/null
if [[ $? -eq 0 ]]; then
  log "${INOF}MongoDB already installed.${NORM}"
else
  tryexec sudo apt-get install -y mongodb-org
  log "${GREEN}MongoDB installed successfully.${NORM}"
fi

exit 0
