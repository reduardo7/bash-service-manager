# Bash Service Manager
Bash Script's for Service Manager

Create your custom service for development.

## Usage ##

1. Create your _service script_.
2. Define the configuration variables: `PID_FILE_PATH`, `LOG_FILE_PATH` and `LOG_ERROR_FILE_PATH`.
2. Copy `services.sh` content or import it.
3. Call `serviceMenu` function with next format: `serviceMenu ACTION SERVICE_NAME COMMAND [WORK_DIR]`
4. Make your new _service script_ executable: `chmod a+x my-service-script`
5. Use it!

## Configuration Variables ##

### PID_FILE_PATH ###

Configure the `PID_FILE_PATH` variable before import `service.sh` script, and define the **PID** file path.

### LOG_FILE_PATH ###

Configure the `LOG_FILE_PATH` variable before import `service.sh` script, and define the **LOG** file path.

### LOG_ERROR_FILE_PATH ###

Configure the `LOG_ERROR_FILE_PATH` variable before import `service.sh` script, and define the **ERROR** file path.


## servicesMenu function ##

Just call only this function to make everything work!

### Arguments ###

#### 1: ACTION ####

This is the action to execute. Please see _Actions_ section below for more information.

If it is an invalid action or emtpy action, you can see the _help_.

#### 2: SERVICE_NAME ####

This is the user friendly _Service Name_.

#### 3: COMMAND ####

This is the command (or commands) that you must execute to start _your service_.

#### 4: WORK_DIR ####

**This is optional**. The working directory is set, where it must be located to execute the _COMMAND_.

## Actions ##

If it is an invalid action or emtpy action, you can see the _help_.

* `start`: Start the _service_.
* `stop`: Stop the _service_.
* `restart`: Restart the _service_. If the _service_ is running, first call _stop_ then call _start_.
* `status`: Get _service_ status.
* `tail`: See all _service_ output.
* `tail-log`: See _service_ _std_ output.
* `tail-error`: See _service_ _err_ output.
* `run`: Execute _service command_ and exit (this action **does not** stop the _service_).
* `debug`: Stop _service_ (if running) and run _service command_ and exit.

## Examples ##

### MongoDB Service ###

**mongo** file:

```bash
#!/usr/bin/env bash

export PID_FILE_PATH="/tmp/my-service.pid"
export LOG_FILE_PATH="/tmp/my-service.log"
export LOG_ERROR_FILE_PATH="/tmp/my-service.error.log"

# Import or paste "services.sh"
. ./services.sh

run-mongo() {
  sudo rm -f /data/db/mongod.lock >/dev/null 2>&1
  sudo mongod
}

action="$1"
serviceName="mongodb"
command="run-mongo"

serviceMenu "$action" "$serviceName" "$command"
```

In console:

```bash
$ mongo status
$ mongo restart
```

### Custom Service ###

**my-service** file:

```bash
#!/usr/bin/env bash

export PID_FILE_PATH="/tmp/my-service.pid"
export LOG_FILE_PATH="/tmp/my-service.log"
export LOG_ERROR_FILE_PATH="/tmp/my-service.error.log"

# Import or paste "services.sh"
. ./services.sh

run-custom() {
  bash my-service-script.sh
}

action="$1"
serviceName="my-service"
command="run-custom"
workDir="/opt/my-service"

serviceMenu "$action" "$serviceName" "$command" "$workDir"
```

### Multiple Services ###

**my-services** file:

```bash
#!/usr/bin/env bash

export PID_FILE_PATH="/tmp/my-service.pid"
export LOG_FILE_PATH="/tmp/my-service.log"
export LOG_ERROR_FILE_PATH="/tmp/my-service.error.log"

# Import or paste "services.sh"
. ./services.sh

# Mong
run-mongo() {
  sudo rm -f /data/db/mongod.lock >/dev/null 2>&1
  sudo mongod
}

mongo() {
  serviceMenu "$1" "mongodb" "run-mongo"
}

run-custom() {
  bash my-script.sh
}

# Custom Service
custom() {
  serviceMenu "$1" "my-script" "run-custom" "/home/user/my-project"
}

$1 $2
```

In console:

```bash
$ my-services mongo status
$ my-services custom restart
```
