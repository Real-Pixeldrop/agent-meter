#!/usr/bin/env python3
"""AgentMeter Remote Server - serves Clawdbot usage data over HTTP."""

import json
import os
import glob
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime, timezone
from pathlib import Path

AGENTS_DIR = os.path.expanduser("~/.clawdbot/agents")
PORT = 7890

def auto_agent_name(folder_name):
    """Auto-detect display name from folder name."""
    return folder_name.replace("-", " ").title()


def parse_sessions():
    """Parse all JSONL session files and return usage records."""
    records = []
    
    if not os.path.exists(AGENTS_DIR):
        return records

    now = datetime.now(timezone.utc)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    for agent_dir in os.listdir(AGENTS_DIR):
        sessions_path = os.path.join(AGENTS_DIR, agent_dir, "sessions")
        if not os.path.isdir(sessions_path):
            continue

        display_name = auto_agent_name(agent_dir)

        for session_file in glob.glob(os.path.join(sessions_path, "*.jsonl")):
            # Skip old files
            mtime = datetime.fromtimestamp(os.path.getmtime(session_file), tz=timezone.utc)
            if mtime < month_start:
                continue

            try:
                with open(session_file, "r") as f:
                    for line in f:
                        if '"usage"' not in line or '"cost"' not in line:
                            continue
                        try:
                            data = json.loads(line)
                            msg = data.get("message", {})
                            usage = msg.get("usage", {})
                            cost_obj = usage.get("cost", {})
                            total_cost = cost_obj.get("total", 0)
                            timestamp = data.get("timestamp", "")

                            if total_cost > 0:
                                records.append({
                                    "provider": "Anthropic",
                                    "agent": display_name,
                                    "model": msg.get("model", "unknown"),
                                    "inputTokens": usage.get("input", 0) + usage.get("cacheRead", 0) + usage.get("cacheWrite", 0),
                                    "outputTokens": usage.get("output", 0),
                                    "cost": total_cost,
                                    "timestamp": timestamp,
                                })
                        except (json.JSONDecodeError, KeyError):
                            continue
            except Exception:
                continue

    return records


CONTEXT_LIMITS = {
    "opus-4-6": 1_000_000,
    "opus": 200_000,
    "sonnet": 200_000,
    "haiku": 200_000,
    "gpt-4o": 128_000,
    "gpt-4": 128_000,
    "gemini": 1_000_000,
}


def get_context_limit(model):
    for key, limit in CONTEXT_LIMITS.items():
        if key in model:
            return limit
    return 200_000


def parse_active_sessions():
    """Parse active sessions and return context usage info."""
    sessions = []
    if not os.path.exists(AGENTS_DIR):
        return sessions

    cutoff = datetime.now(timezone.utc).timestamp() - 24 * 3600

    for agent_dir in os.listdir(AGENTS_DIR):
        sessions_path = os.path.join(AGENTS_DIR, agent_dir, "sessions")
        if not os.path.isdir(sessions_path):
            continue

        display_name = auto_agent_name(agent_dir)

        for session_file in glob.glob(os.path.join(sessions_path, "*.jsonl")):
            mtime = os.path.getmtime(session_file)
            if mtime < cutoff:
                continue

            try:
                last_context = 0
                last_model = "unknown"
                last_ts = ""
                msg_count = 0
                total_cost = 0.0

                with open(session_file, "r") as f:
                    lines = f.readlines()

                for line in reversed(lines):
                    if '"usage"' not in line or '"cost"' not in line:
                        continue
                    try:
                        data = json.loads(line)
                        msg = data.get("message", {})
                        usage = msg.get("usage", {})
                        cost_obj = usage.get("cost", {})
                        cost = cost_obj.get("total", 0)
                        total_cost += cost
                        msg_count += 1

                        if last_context == 0:
                            inp = usage.get("input", 0)
                            cr = usage.get("cacheRead", 0)
                            cw = usage.get("cacheWrite", 0)
                            last_context = inp + cr + cw
                            last_model = msg.get("model", "unknown")
                            last_ts = data.get("timestamp", "")
                    except (json.JSONDecodeError, KeyError):
                        continue

                if last_context > 0:
                    limit = get_context_limit(last_model)
                    session_id = os.path.basename(session_file).replace(".jsonl", "")
                    sessions.append({
                        "id": session_id,
                        "agent": display_name,
                        "model": last_model,
                        "contextTokens": last_context,
                        "contextLimit": limit,
                        "lastActivity": last_ts,
                        "messageCount": msg_count,
                        "sessionCost": total_cost,
                    })
            except Exception:
                continue

    sessions.sort(key=lambda s: s["contextTokens"] / max(s["contextLimit"], 1), reverse=True)
    return sessions[:8]


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/usage":
            records = parse_sessions()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps({"records": records, "hasClawdbot": True}).encode())
        elif self.path == "/api/sessions":
            sessions = parse_active_sessions()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps({"sessions": sessions}).encode())
        elif self.path == "/api/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok", "version": "0.3.0"}).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass  # Suppress logs


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"AgentMeter server running on port {PORT}")
    server.serve_forever()
