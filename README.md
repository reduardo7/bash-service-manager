# Bash Service Manager

Bash Script's for Service Manager

Create your custom service for development.

## Test

```bash
docker compose run --rm test
```

## Usage

1. Create your _service script_.
2. Define the configuration environment variables:
   * `PID_FILE_PATH`
   * `LOG_FILE_PATH`
3. Define the configuration variables:
   * Mandatory configuration variables:
     * `$SERVICE_NAME`
     * `$SERVICE_CMD` _(array)_
   * Optional configuration variables:
     * `$SERVICE_WORK_DIR`
     * `$SERVICE_ON_START` _(array)_
     * `$SERVICE_ON_FINISH` _(array)_
4. Copy `services.sh` content or import it.
5. Call `serviceMenu` function and pass the **action** as first parameter (ex: `serviceMenu "$1"`).
6. Make your new _service script_ executable: `chmod a+x my-service-script`.
7. Use it!

## Configuration Environment Variables

### PID_FILE_PATH

Configure the `PID_FILE_PATH` variable before import `service.sh` script, and define the **PID** file path.

### LOG_FILE_PATH

Configure the `LOG_FILE_PATH` variable before import `service.sh` script, and define the **LOG** file path.

## Configuration Variables

### Mandatory Configuration Variables

#### SERVICE_NAME

This is the user friendly _Service Name_.

#### SERVICE_CMD (array variable)

This is the _commands_ that you must execute to start _your service_.

### Optional Configuration Variables

#### SERVICE_WORK_DIR

The working directory is set, where it must be located to execute the _command_.

#### SERVICE_ON_START (array variable)

Commands to execute before _Service_ start.

If function exit code is not `0` (zero), the service will not started.

#### SERVICE_ON_FINISH (array variable)

Commands to execute after _Service_ finish/exit.

## servicesMenu function

Just call only this function to make everything work!

## Actions

If it is an invalid action or empty action, you can see the _help_.

* `start`: Start the _service_.
* `stop`: Stop the _service_.
* `restart`: Restart the _service_. If the _service_ is running, first call _stop_ then call _start_.
* `status`: Get _service_ status.
* `tail`: See all _service_ output.
* `run`: Execute _service command_ and exit (this action **does not** stop the _service_).
* `debug`: Stop _service_ (if running) and run _service command_ and exit.

## Examples

### Telegraf Service

**telegraf.sh** file:

```bash
#!/usr/bin/env bash

appDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd)

. "$appDir/services.sh"

# Friendly service name (mandatory)
SERVICE_NAME="telegraf"
# Command to run (mandatory, array variable)
SERVICE_CMD=(./telegraf --config telegraf.conf)
# Working Directory (optional)
SERVICE_WORK_DIR="$appDir"
# On start (optional, array variable)
#SERVICE_ON_START=()
# On finish (optional, array variable)
#SERVICE_ON_FINISH=()

export LOG_FILE_PATH="$SERVICE_NAME.log"
export PID_FILE_PATH="$SERVICE_NAME.pid"

serviceMenu "$1"
```

In console:

```bash
$ telegraf.sh status
$ telegraf.sh restart
```

### Custom Service

**my-service** file:

```bash
#!/usr/bin/env bash

export PID_FILE_PATH="my-service.pid"
export LOG_FILE_PATH="my-service.log"

. ./services.sh

# Friendly service name (mandatory)
SERVICE_NAME="Example Service"
# Command to run (mandatory, array variable)
SERVICE_CMD=(ping 1.1.1.1)
# Working Directory (optional)
#SERVICE_WORK_DIR=
# On start (optional, array variable)
#SERVICE_ON_START=()
# On finish (optional, array variable)
#SERVICE_ON_FINISH=()

serviceMenu "$1"
```
