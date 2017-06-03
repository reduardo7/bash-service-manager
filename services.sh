# Bash Service Manager
# Project: https://github.com/reduardo7/bash-service-manager

# export PID_FILE_PATH="/tmp/my-service.pid"
# export LOG_FILE_PATH="/tmp/my-service.log"
# export LOG_ERROR_FILE_PATH="/tmp/my-service.error.log"

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
  local c="$1" # Command
  local w="$2" # Workdir
  local action="$3" # Action
  local onStart="$4" # On start
  local onFinish="$5" # On finish

  (
    [ ! -z "$w" ] && cd "$w"

    if [ ! -z "$onStart" ]; then
      ( "$onStart" "$action" )
      exitCode=$?

      if [ $exitCode -gt 0 ] ; then
        @warn "Start service fail"
        exit $exitCode
      fi
    fi

    if [ ! -z "$onFinish" ]; then
      onServiceFinish() {
        local exitCode=$?
        "$onFinish" "$action" $exitCode
        return $exitCode
      }
      trap onServiceFinish EXIT
    fi

    "$c" "$action"
  )
  return $?
}

@serviceStatus() {
  local serviceName="$1" # Service Name

  if [ -f "$PID_FILE_PATH" ] && [ ! -z "$(cat "$PID_FILE_PATH")" ]; then
    local p=$(cat "$PID_FILE_PATH")

    if kill -0 $p >/dev/null 2>&1
      then
        @e "Serive $serviceName is runnig with PID $p"
        return 0
      else
        @e "Service $serviceName is not running (process PID $p not exists)"
        return 1
      fi
  else
    @e "Service $serviceName is not running"
    return 2
  fi
}

@serviceStart() {
  local serviceName="$1" # Service Name
  local c="$2" # Command
  local w="$3" # Workdir
  local action="$4" # Action
  local onStart="$5" # On start
  local onFinish="$6" # On finish

  if @serviceStatus "$serviceName" >/dev/null 2>&1
    then
      @e "Service ${serviceName} already running with PID $(cat "$PID_FILE_PATH")"
      return 0
    fi

  @e "Starting ${serviceName} service..."
  touch "$LOG_FILE_PATH" >/dev/null 2>&1 || @err "Can not create $LOG_FILE_PATH file"
  touch "$LOG_ERROR_FILE_PATH" >/dev/null 2>&1 || @err "Can not create $LOG_ERROR_FILE_PATH file"
  touch "$PID_FILE_PATH" >/dev/null 2>&1 || @err "Can not create $PID_FILE_PATH file"

  (
    (
      @execService "$c" "$w" "$action" "$onStart" "$onFinish"
    ) >>"$LOG_FILE_PATH" 2>>"$LOG_ERROR_FILE_PATH" & echo $! >"$PID_FILE_PATH" 
  ) &
  sleep 2

  @serviceStatus "$serviceName" >/dev/null 2>&1
  return $?
}

@serviceStop() {
  local serviceName="$1" # Service Name

  if [ -f "$PID_FILE_PATH" ] && [ ! -z "$(cat "$PID_FILE_PATH")" ]; then
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
        @err "Error stopping Service ${serviceName}! Service already running with PID $(cat "$PID_FILE_PATH")"
      fi

    rm -f "$PID_FILE_PATH" || @err "Can not delete $PID_FILE_PATH file"
    return 0
  else
    @warn "Service $serviceName is not running"
  fi
}

@serviceRestart() {
  local serviceName="$1" # Service Name
  local c="$2" # Command
  local w="$3" # Workdir
  local action="$4" # Action
  local onStart="$5" # On start
  local onFinish="$6" # On finish

  @serviceStop "$serviceName"
  @serviceStart "$serviceName" "$c" "$w" "$action" "$onStart" "$onFinish"
}

@serviceTail() {
  local serviceName="$1" # Service Name
  local type="$2"

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
      @e "Actions: [log|error]"
      exit 1
      ;;
  esac
}

@serviceDebug() {
  local serviceName="$1" # Service Name
  local c="$2" # Command
  local w="$3" # Workdir
  local action="$4" # Action
  local onStart="$5" # On start
  local onFinish="$6" # On finish

  @serviceStop "$serviceName"
  @e "Debugging ${serviceName}..."
  @execService "$c" "$w" "$action" "$onStart" "$onFinish"
  exitCode=$?
  @e "Finish debugging ${serviceName}"
  return $exitCode
}

# Service menu

serviceMenu() {
  local action="$1" # Action to execute
  local serviceName="$2" # Friendly service name
  local c="$3" # Command to run
  local w="$4" # Working Directory
  local onStart="$5" # On start
  local onFinish="$6" # On finish

  case "$action" in
    start)
      @serviceStart "$serviceName" "$c" "$w" "$action" "$onStart" "$onFinish"
      ;;
    stop)
      @serviceStop "$serviceName"
      ;;
    restart)
      @serviceRestart "$serviceName" "$c" "$w" "$action" "$onStart" "$onFinish"
      ;;
    status)
      @serviceStatus "$serviceName"
      ;;
    run)
      ( [ ! -z "$w" ] && cd "$w"
        "$c" "$action"
      )
      ;;
    debug)
      @serviceDebug "$serviceName" "$c" "$w" "$action" "$onStart" "$onFinish"
      ;;
    tail)
      @serviceTail "$serviceName" "all"
      ;;
    tail-log)
      @serviceTail "$serviceName" "log"
      ;;
    tail-error)
      @serviceTail "$serviceName" "error"
      ;;
    *)
      @e "Actions: [start|stop|restart|status|run|debug|tail(-[log|error])]"
      exit 1
      ;;
  esac
}
