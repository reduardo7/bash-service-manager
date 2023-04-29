# Bash Service Manager
# Project: https://github.com/reduardo7/bash-service-manager

###############################################################################
# BashX | https://github.com/reduardo7/bashx
set +ex;export BASHX_VERSION="v3.1.2"
(export LC_CTYPE=C;export LC_ALL=C;export LANG=C;set -e;x() { s="$*";echo "# Error: ${s:-Installation fail}" >&2;exit 1;};d=/dev/null;[ ! -z "$BASHX_VERSION" ] || x BASHX_VERSION is required;export BASHX_DIR="${BASHX_DIR:-${HOME:-/tmp}/.bashx/$BASHX_VERSION}";if [ ! -d "$BASHX_DIR" ];then u="https://raw.githubusercontent.com/reduardo7/bashx/$BASHX_VERSION/src/setup.sh";if type wget >$d 2>&1 ;then sh -c "$(wget -q $u -O -)" || x;elif type curl >$d 2>&1 ;then sh -c "$(curl -fsSL $u)" || x;else x wget or curl are required. Install wget or curl to continue;fi;fi) || exit $?
. "${HOME:-/tmp}/.bashx/${BASHX_VERSION}/src/init.sh"
###############################################################################

# export PID_FILE_PATH="/tmp/my-service.pid"
# export LOG_FILE_PATH="/tmp/my-service.log"

# Friendly service name (mandatoty)
#SERVICE_NAME=
# Command to run (mandatoty, array variable)
#SERVICE_CMD=()
# Working Directory (optional)
#SERVICE_WORK_DIR=
# On start (optional, array variable)
#SERVICE_ON_START=()
# On finish (optional, array variable)
#SERVICE_ON_FINISH=()

@execService() {
  [ -z "$SERVICE_WORK_DIR" ] || cd "$SERVICE_WORK_DIR"

  if [ ! -z "$SERVICE_ON_START" ] ; then
    ( "${SERVICE_ON_START[@]}" )
    exit_code=$?

    if [ $exit_code -gt 0 ] ; then
      @log.warn "Start service fail"
      exit $exit_code
    fi
  fi

  if [ ! -z "$onFinish" ] ; then
    onServiceFinish() {
      local exit_code=$?
      ( "${onFinish[@]}" )
      return $exit_code
    }

    trap onServiceFinish EXIT
  fi

  nohup "${SERVICE_CMD[@]}" \
    >>"$LOG_FILE_PATH" \
    2>>"$LOG_FILE_PATH" \
    & echo $! >"$PID_FILE_PATH"

  return $?
}

@serviceStatus() {
  if [ -f "$PID_FILE_PATH" ] && [ ! -z "$(cat "$PID_FILE_PATH")" ] ; then
    local PID=$(cat "$PID_FILE_PATH")
    local kill_result_message=$(kill -0 $PID 2>&1)
    local kill_result_code=$?

    if (( $kill_result_code == 0 )) ; then
      @log "Service $SERVICE_NAME is runnig with PID $PID"
      return 0
    elif [[ $kill_result_message == *"kill: ($PID) - No such process" ]] ; then
      @log.warn "Service $SERVICE_NAME is not running (process PID $PID not exists)"
      return 2
    elif [[ $kill_result_message == *"kill: ($PID) - Operation not permitted" ]] ; then
      @log.warn "Status of $SERVICE_NAME service could not be obtained (operation not permitted for process PID $PID)"
      return 1
    else
      @log.warn "Status of $SERVICE_NAME service could not be obtained (process PID $PID)"
      return 3
    fi
  else
    @log.warn "Service $SERVICE_NAME is not running"
    return 4
  fi
}

@serviceStart() {
  if @serviceStatus ; then
    @log "Service ${SERVICE_NAME} already running with PID $(cat "$PID_FILE_PATH")"
    return 0
  fi

  @log "Starting ${SERVICE_NAME} service..."
  touch "$LOG_FILE_PATH" >/dev/null || @app.error "Can not create $LOG_FILE_PATH file"
  touch "$PID_FILE_PATH" >/dev/null || @app.error "Can not create $PID_FILE_PATH file"

  @execService
  @log "Service ${SERVICE_NAME} started with PID $(cat "$PID_FILE_PATH")"
  sleep 2

  @serviceStatus
  local exit_code=$?

  if (( ${exit_code} == 0 )); then
    @log "Service ${SERVICE_NAME} started successfully"
  else
    @log.warn "Service ${SERVICE_NAME} could not be started (exit code: ${exit_code})"
    cat "$LOG_FILE_PATH"
  fi

  return ${exit_code}
}

@serviceStop() {
  if [ -f "$PID_FILE_PATH" ] && [ ! -z "$(cat "$PID_FILE_PATH")" ]; then
    touch "$PID_FILE_PATH" >/dev/null || @app.error "Can not touch $PID_FILE_PATH file"

    @log "Stopping ${SERVICE_NAME}..."

    for p in $(cat "$PID_FILE_PATH"); do
      if kill -0 $p >/dev/null 2>&1 ; then
        kill $p
        sleep 2

        if kill -0 $p >/dev/null 2>&1 ; then
          kill -9 $p
          sleep 2

          if kill -0 $p >/dev/null 2>&1 ; then
            @log "Exec: sudo kill -9 $p"
            sudo kill -9 $p
            sleep 2
          fi
        fi
      fi
    done

    if @serviceStatus ; then
      @app.error "Error stopping Service ${SERVICE_NAME}! Service is still running with PID $(cat "$PID_FILE_PATH")"
    fi

    rm -f "$PID_FILE_PATH" || @app.error "Can not delete $PID_FILE_PATH file"
    return 0
  else
    @log.warn "Service $SERVICE_NAME is not running"
  fi
}

@serviceRestart() {
  @serviceStop
  sleep 2
  @serviceStart
}

@serviceDebug() {
  @serviceStop
  @log "Debugging ${SERVICE_NAME}..."
  @execService
  exitCode=$?
  @log "Finish debugging ${SERVICE_NAME} (exit code ${exitCode})"
  return $exitCode
}

# Service menu
serviceMenu() {
  case "$1" in
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
        [ -z "$SERVICE_WORK_DIR" ] || cd "$SERVICE_WORK_DIR"
        "${SERVICE_CMD[@]}"
      )
      ;;
    debug)
      @serviceDebug
      ;;
    tail)
      set -ex
      tail -f -n 10 "${LOG_FILE_PATH}"
      ;;
    logs)
      set -ex
      cat "${LOG_FILE_PATH}"
      ;;
    *)
      @log "Usage: {start|stop|restart|status|run|debug|tail}"
      exit 1
      ;;
  esac
}

# vim: filetype=sh tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab