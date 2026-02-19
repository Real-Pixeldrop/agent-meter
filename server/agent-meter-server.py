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


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/usage":
            records = parse_sessions()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps({"records": records, "hasClawdbot": True}).encode())
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
