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
Usage: $(basename "$0") <start|stop|status|restart|logs> [service] [--follow]

Commands:
  start           Build all services and start them in the background
  stop            Stop all running services started by this script
  status          Show status of each service
  restart         Stop then start all services
  logs            Show logs of one service or all services

Logs command examples:
  $(basename "$0") logs                          # print all logs once
  $(basename "$0") logs --follow                 # follow all logs live
  $(basename "$0") logs first-name-service       # print one service log
  $(basename "$0") logs hello-orchestrator-service --follow
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

is_known_service() {
  local target="$1"
  for entry in "${SERVICES[@]}"; do
    IFS=":" read -r service _ <<<"$entry"
    if [[ "$service" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

print_missing_log_hint() {
  local service="$1"
  local log_file
  log_file="$(service_log_file "$service")"
  echo "[WARN] Keine Logdatei für $service gefunden: $log_file"
  echo "       Starte den Service zuerst mit ./scripts/services.sh start"
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

show_logs() {
  mkdir -p "$LOG_DIR"

  local service="all"
  local follow="false"

  if [[ "${1:-}" == "--follow" ]]; then
    follow="true"
    shift
  fi

  if [[ -n "${1:-}" ]]; then
    service="$1"
    shift
  fi

  if [[ "${1:-}" == "--follow" ]]; then
    follow="true"
    shift
  fi

  if [[ "$service" == "all" ]]; then
    local files=()
    for entry in "${SERVICES[@]}"; do
      IFS=":" read -r svc _ <<<"$entry"
      local log_file
      log_file="$(service_log_file "$svc")"
      if [[ -f "$log_file" ]]; then
        files+=("$log_file")
      else
        print_missing_log_hint "$svc"
      fi
    done

    if [[ ${#files[@]} -eq 0 ]]; then
      echo "[ERROR] Keine Logdateien gefunden."
      exit 1
    fi

    if [[ "$follow" == "true" ]]; then
      echo "[INFO] Folge Logs von allen Services (Ctrl+C zum Beenden)..."
      tail -n 100 -f "${files[@]}"
    else
      tail -n 200 "${files[@]}"
    fi
    return
  fi

  if ! is_known_service "$service"; then
    echo "[ERROR] Unbekannter Service: $service"
    echo "        Erlaubt: first-name-service | last-name-service | hello-orchestrator-service | all"
    exit 1
  fi

  local log_file
  log_file="$(service_log_file "$service")"
  if [[ ! -f "$log_file" ]]; then
    print_missing_log_hint "$service"
    exit 1
  fi

  if [[ "$follow" == "true" ]]; then
    echo "[INFO] Folge Logs von $service (Ctrl+C zum Beenden)..."
    tail -n 100 -f "$log_file"
  else
    tail -n 200 "$log_file"
  fi
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
    logs)
      shift || true
      show_logs "$@"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
