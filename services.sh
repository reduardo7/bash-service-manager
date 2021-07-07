# Bash Service Manager
# Project: https://github.com/reduardo7/bash-service-manager

# export PID_FILE_PATH="/tmp/my-service.pid"
# export LOG_FILE_PATH="/tmp/my-service.log"
# export LOG_ERROR_FILE_PATH="/tmp/my-service.error.log"

# Action to execute (mandatoty)
#action="$1"  
# Friendly service name (mandatoty)
#serviceName= 
# Command to run (mandatoty, array variable)
#command=()
# Working Directory (optional)
#workDir=
# On start (optional, array variable)
#onStart=()
# On finish (optional, array variable)
#onFinish=()

@e() {
  echo "# $*"
}

@warn() {
  @e "Warning: $*" >&2
}

@err() {
  @e "Error! $*" >&2
  exit 1
}

@execService() {
  [ ! -z "$workDir" ] && cd "$workDir"

  if [ ! -z "$onStart" ] ; 
  then
    ( "${onStart[@]}")
    exitCode=$?

    if [ $exitCode -gt 0 ] ; 
    then
      @warn "Start service fail"
      exit $exitCode
    fi
  fi

  if [ ! -z "$onFinish" ] ; 
  then
    onServiceFinish() {
      local exitCode=$?
      "${onFinish[@]}"
      return $exitCode
    }
    trap onServiceFinish EXIT
  fi

  nohup "${command[@]}" >>"$LOG_FILE_PATH" 2>>"$LOG_ERROR_FILE_PATH" & echo $! >"$PID_FILE_PATH" 
  return $?
}

@serviceStatus() {
  if [ -f "$PID_FILE_PATH" ] && [ ! -z "$(cat "$PID_FILE_PATH")" ];
  then
    local PID=$(cat "$PID_FILE_PATH")
    killResultMessage=$(kill -0 $PID 2>&1)
    killResultCode=$?

    if (( $killResultCode == 0 ));
    then
      @e "Service $serviceName is runnig with PID $PID"
      return 0
    elif [[ $killResultMessage == *"kill: ($PID) - No such process" ]]
    then
      @warn "Service $serviceName is not running (process PID $PID not exists)"
      return 2
    elif [[ $killResultMessage == *"kill: ($PID) - Operation not permitted" ]]
    then
      @warn "Status of $serviceName service could not be obtained (operation not permitted for process PID $PID)"
      return 1
    else
      @warn "Status of $serviceName service could not be obtained (process PID $PID)"
      return 1
    fi
  else
    @warn "Service $serviceName is not running"
    return 2
  fi
}

@serviceStart() {
  if @serviceStatus "$serviceName" >/dev/null 2>&1
  then
    @e "Service ${serviceName} already running with PID $(cat "$PID_FILE_PATH")"
    return 0
  fi

  @e "Starting ${serviceName} service..."
  touch "$LOG_FILE_PATH" >/dev/null 2>&1 || @err "Can not create $LOG_FILE_PATH file"
  touch "$LOG_ERROR_FILE_PATH" >/dev/null 2>&1 || @err "Can not create $LOG_ERROR_FILE_PATH file"
  touch "$PID_FILE_PATH" >/dev/null 2>&1 || @err "Can not create $PID_FILE_PATH file"

  @execService  
  sleep 2

  @serviceStatus "$serviceName" >/dev/null 2>&1
  return $?
}

@serviceStop() {
  if [ -f "$PID_FILE_PATH" ] && [ ! -z "$(cat "$PID_FILE_PATH")" ]; 
  then
    touch "$PID_FILE_PATH" >/dev/null 2>&1 || @err "Can not touch $PID_FILE_PATH file"

    @e "Stopping ${serviceName}..."
    for p in $(cat "$PID_FILE_PATH"); do
      if kill -0 $p >/dev/null 2>&1
      then
        kill $p
        sleep 2
        if kill -0 $p >/dev/null 2>&1
        then
          kill -9 $p
          sleep 2
          if kill -0 $p >/dev/null 2>&1
          then
            @e "Exec: sudo kill -9 $p"
            sudo kill -9 $p
            sleep 2
          fi
        fi
      fi
    done

    if @serviceStatus "$serviceName" >/dev/null 2>&1
    then
      @err "Error stopping Service ${serviceName}! Service is still running with PID $(cat "$PID_FILE_PATH")"
    fi

    rm -f "$PID_FILE_PATH" || @err "Can not delete $PID_FILE_PATH file"
    return 0
  else
    @warn "Service $serviceName is not running"
  fi
}
@serviceRestart() {
  @serviceStop
  sleep 2
  @serviceStart
}

@serviceTail() {
  local type="$1"

  case "$type" in
    log)
      tail -f "$LOG_FILE_PATH"
      exit 0
      ;;
    error)
      tail -f "$LOG_ERROR_FILE_PATH"
      exit 0
      ;;
    all)
      tail -f "$LOG_FILE_PATH" "$LOG_ERROR_FILE_PATH"
      exit 0
      ;;
    *)
      @e "Usage: {log|error}"
      exit 1
      ;;
  esac
}

@serviceDebug() {
  @serviceStop
  @e "Debugging ${serviceName}..."
  @execService
  exitCode=$?
  @e "Finish debugging ${serviceName}"
  return $exitCode
}

# Service menu
serviceMenu() {
  case "$action" in
    start)
      @serviceStart
      ;;
    stop)
      @serviceStop
      ;;
    restart)
      @serviceRestart
      ;;
    status)
      @serviceStatus
      ;;
    run)
      ( 
        [ ! -z "$workDir" ] && cd "$workDir"
        "${command[@]}"
      )
      ;;
    debug)
      @serviceDebug
      ;;
    tail)
      @serviceTail "all"
      ;;
    tail-log)
      @serviceTail "log"
      ;;
    tail-error)
      @serviceTail "error"
      ;;
    *)
      @e "Usage: {start|stop|restart|status|run|debug|tail(-{log|error})}"
      exit 1
      ;;
  esac
}
