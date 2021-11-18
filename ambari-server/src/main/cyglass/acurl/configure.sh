#!/bin/bash

function usage() {
  echo $1
  echo "usage: configure.sh <ENDPOINT> <USERNAME> [PASSWORD]"
}

# ENDPOINT argument
if [ "" == "$1" ]; then
  usage "please specify ENDPOINT (e.g. http://ambari-node-dev:8080/api/v1)" ; exit 1
fi
ENDPOINT=$1

if [[ ! $ENDPOINT == *"api/v"* ]]; then
  usage "ENDPOINT must contain 'api' and version expression (e.g. http://ambari-node-dev:8080/api/v1)" ; exit 1
fi

# USERNAME argument
if [ "" == "$2" ]; then
  usage "please specify USERNAME (e.g. admin)" ; exit 1
fi
USERNAME=$2

# PASSWORD argument
if [ "" == "$3" ]; then
  unset PASSWORD;
  printf "password: "
  while IFS= read -r -s -n1 pass; do
    if [[ -z $pass ]]; then
      echo
      break
    else
      echo -n '*'
      PASSWORD+=$pass
    fi
  done
else
  PASSWORD=$3
fi

SESSION="${PWD}/session.rc"
rm -rf $SESSION

cat <<EOF > $SESSION
# source this file to interact with ambari
function acurl() {
  
  if [ "" == "\$1" ]; then
    echo "specify API URL document as argument 1" ; return
  fi
  DOC=\$1
  shift
  
  curlArguments=()
  DEBUG=false
  for var in "\$@"; do
    if [ "--debug" == "\$var" ]; then
      DEBUG=true
      echo "debug> debug enabled"
    else
      curlArguments+=( "\$var" )
    fi
  done
  
  TICKS=`date +%s%N | cut -b1-13`
  
  # if the doc has a leading slash, then its an absolute path 
  if [[ \${DOC} = '/'* ]]; then
    CPATH=${ENDPOINT}\${DOC}
  else
    CPATH=${ENDPOINT}/\${DOC}
  fi
  
  if [ "\$DEBUG" = true ]; then
    echo "debug> cpath endpoint is \${CPATH}"
    echo "debug> curl arguments are \${curlArguments[@]}"
    echo "debug> command is: curl -s -H \"Content-Type: application/json\" -H \"X-Requested-By: \$USER\" -u \"${USERNAME}:${PASSWORD}\" \"\$CPATH\" \"\${curlArguments[@]}\""
  fi
  
  unset OUTPUT
  unset HTTP_STATUS
  unset JQ_OUTPUT
  unset RESPONSE

  TMP_OUTPUT=/tmp/acurl.response.out
  rm -rf \$TMP_OUTPUT
  HTTP_STATUS=\$(curl -s -w "%{http_code}" -o \$TMP_OUTPUT -H "Content-Type: application/json" -H "X-Requested-By: \$USER" -u "${USERNAME}:${PASSWORD}" "\$CPATH" "\${curlArguments[@]}")
  CURL_EXIT_STATUS=\$?
  if [ "\$DEBUG" = true ]; then
    echo "debug> curl exit status was \$CURL_EXIT_STATUS, HTTP status was \$HTTP_STATUS"
  fi
  HTTP_STATUS=\$(echo \$HTTP_STATUS | sed 's/^0*//')
  if [ "200" != "\$HTTP_STATUS" ]; then
    #echo -n "HTTP status was \$HTTP_STATUS\\n" >&2
    printf "HTTP status was %s\n" "\$HTTP_STATUS" >&2
  fi

  if [ -s \$TMP_OUTPUT ]; then
    RESPONSE=\$(cat \$TMP_OUTPUT)
    if [ "\$DEBUG" = true ]; then
      echo "debug> response was: \$RESPONSE"
    fi
  else
    RESPONSE=""
    printf "HTTP response was empty\n" >&2
  fi
  rm -rf \$TMP_OUTPUT
  
  if [ "\$DEBUG" = true ]; then
    echo "debug> response was:"
    echo "'\$RESPONSE'"
  fi
  JQ_OUTPUT=\$(echo $RESPONSE | jq '.' 2> /dev/null)
  JQ_EXIT_STATUS=\$?
  if [ \$JQ_EXIT_STATUS -ne 0 ] ; then
    if [ "\$DEBUG" = true ]; then
      echo "debug> jq wasn't able to parse curl output (exit status was \$JQ_EXIT_STATUS)"
    fi
    JQ_OUTPUT=false
  else
    JQ_OUTPUT=true
  fi
  if [ "\$DEBUG" = true ]; then
    echo "debug> do output"
  fi
  if [ \$CURL_EXIT_STATUS -ne 0 ] ; then  
    echo "curl(\$CURL_EXIT_STATUS) - curl exited with non-zero status"
    if [ "" != "\$RESPONSE" ]; then
      if [ "\$JQ_OUTPUT" = true ]; then
        echo \$RESPONSE | jq '.'
      else
        echo \$RESPONSE
      fi
    fi
  else
      if [ "\$DEBUG" = true ]; then
        echo "debug> curl exited with zero exit status"
      fi
      if [ "\$JQ_OUTPUT" = true ]; then
        echo \$RESPONSE | jq '.'
      else
        echo \$RESPONSE
      fi
  fi
  if [ "\$DEBUG" = true ]; then
    echo "debug> done"
  fi
}
echo ""
echo "acurl is now ready to use:"
echo "  acurl <document path> [CURL ARGUMENTS]"

EOF

echo "acurl is configured, source the session.rc file into your shell to continue"


