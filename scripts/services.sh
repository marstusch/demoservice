#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/.run"
LOG_DIR="${ROOT_DIR}/logs"

SERVICES=(
  "first-name-service:8081"
  "last-name-service:8082"
  "hello-orchestrator-service:8080"
)

usage() {
  cat <<USAGE
Usage: $(basename "$0") <start|stop|status|restart>

Commands:
  start    Build all services and start them in the background
  stop     Stop all running services started by this script
  status   Show status of each service
  restart  Stop then start all services
USAGE
}

service_pid_file() {
  local service="$1"
  echo "${RUN_DIR}/${service}.pid"
}

service_log_file() {
  local service="$1"
  echo "${LOG_DIR}/${service}.log"
}

is_running() {
  local pid="$1"
  kill -0 "$pid" >/dev/null 2>&1
}

start_services() {
  mkdir -p "$RUN_DIR" "$LOG_DIR"

  echo "[INFO] Building services..."
  (cd "$ROOT_DIR" && mvn -q -DskipTests package)

  for entry in "${SERVICES[@]}"; do
    IFS=":" read -r service port <<<"$entry"
    local pid_file
    pid_file="$(service_pid_file "$service")"

    if [[ -f "$pid_file" ]]; then
      local existing_pid
      existing_pid="$(cat "$pid_file")"
      if is_running "$existing_pid"; then
        echo "[INFO] $service already running (PID $existing_pid)."
        continue
      fi
      rm -f "$pid_file"
    fi

    local jar_path="${ROOT_DIR}/${service}/target/quarkus-app/quarkus-run.jar"
    if [[ ! -f "$jar_path" ]]; then
      echo "[ERROR] Artifact not found: $jar_path"
      exit 1
    fi

    local log_file
    log_file="$(service_log_file "$service")"

    echo "[INFO] Starting $service on port $port ..."
    nohup java -jar "$jar_path" >"$log_file" 2>&1 &
    local pid=$!
    echo "$pid" >"$pid_file"
    echo "[INFO] $service started (PID $pid, log: $log_file)"
  done
}

stop_services() {
  mkdir -p "$RUN_DIR"

  for entry in "${SERVICES[@]}"; do
    IFS=":" read -r service _ <<<"$entry"
    local pid_file
    pid_file="$(service_pid_file "$service")"

    if [[ ! -f "$pid_file" ]]; then
      echo "[INFO] $service is not running (no PID file)."
      continue
    fi

    local pid
    pid="$(cat "$pid_file")"

    if ! is_running "$pid"; then
      echo "[INFO] $service already stopped (stale PID file: $pid)."
      rm -f "$pid_file"
      continue
    fi

    echo "[INFO] Stopping $service (PID $pid) ..."
    kill "$pid"

    for _ in {1..20}; do
      if ! is_running "$pid"; then
        break
      fi
      sleep 0.5
    done

    if is_running "$pid"; then
      echo "[WARN] Force killing $service (PID $pid) ..."
      kill -9 "$pid"
    fi

    rm -f "$pid_file"
    echo "[INFO] $service stopped."
  done
}

status_services() {
  mkdir -p "$RUN_DIR"

  for entry in "${SERVICES[@]}"; do
    IFS=":" read -r service port <<<"$entry"
    local pid_file
    pid_file="$(service_pid_file "$service")"

    if [[ ! -f "$pid_file" ]]; then
      echo "[STATUS] $service (port $port): STOPPED"
      continue
    fi

    local pid
    pid="$(cat "$pid_file")"
    if is_running "$pid"; then
      echo "[STATUS] $service (port $port): RUNNING (PID $pid)"
    else
      echo "[STATUS] $service (port $port): STOPPED (stale PID $pid)"
    fi
  done
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    start)
      start_services
      ;;
    stop)
      stop_services
      ;;
    status)
      status_services
      ;;
    restart)
      stop_services
      start_services
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
