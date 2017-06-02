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
    @warn "PID file ($PID_FILE_PATH) not exists or is empty"
    return 2
  fi
}

@serviceStart() {
  local serviceName="$1" # Service Name
  local c="$2" # Command
  local w="$3" # Workdir
  local action="$4" # Action

  if @serviceStatus "$serviceName" >/dev/null 2>&1
    then
      @e "Service ${serviceName} already running with PID $(cat "$PID_FILE_PATH")"
      return 0
    fi

  @e "Starting ${serviceName} service..."
  touch "$LOG_FILE_PATH" >/dev/null 2>&1 || @err "Can not create $LOG_FILE_PATH file"
  touch "$LOG_ERROR_FILE_PATH" >/dev/null 2>&1 || @err "Can not create $LOG_ERROR_FILE_PATH file"
  touch "$PID_FILE_PATH" >/dev/null 2>&1 || @err "Can not create $PID_FILE_PATH file"

  [ ! -z "$w" ] && cd "$w"
  ( "$c" $action >>"$LOG_FILE_PATH" 2>>"$LOG_ERROR_FILE_PATH" & echo $! >"$PID_FILE_PATH" ) &
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
    @warn "PID file ($PID_FILE_PATH) not exists or is empty"
  fi
}

@serviceRestart() {
  local serviceName="$1" # Service Name
  local c="$2" # Command
  local w="$3" # Workdir
  local action="$4" # Action

  @serviceStop "$serviceName"
  @serviceStart "$serviceName" "$c" "$w" $action
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

# Service menu

serviceMenu() {
  local action="$1" # Action to execute
  local serviceName="$2" # Friendly service name
  local c="$3" # Command to run
  local w="$4" # Working Directory

  case "$action" in
    start)
      @serviceStart "$serviceName" "$c" "$w" "$action"
      ;;
    stop)
      @serviceStop "$serviceName"
      ;;
    restart)
      @serviceRestart "$serviceName" "$c" "$w" "$action"
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
      @serviceStop "$serviceName"
      @e "Debugging ${serviceName}..."
      ( [ ! -z "$w" ] && cd "$w"
        "$c" "$action"
      )
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
