import { readFileSync } from "node:fs";
import { WebSocketServer } from "ws";

const { port } = JSON.parse(
  readFileSync(new URL("./relay.config.json", import.meta.url), "utf8"),
);
const wss = new WebSocketServer({ host: "127.0.0.1", port: port });
const ahkClients = new Set();

wss.on("connection", (ws, req) => {
  if (req.url === "/ahk") {
    ahkClients.add(ws);
    ws.on("close", () => ahkClients.delete(ws));
    return;
  }

  ws.on("message", (data) => {
    const cmd = data.toString().trim();
    console.log("cmd:", cmd);
    for (const c of ahkClients) {
      if (c.readyState === 1) c.send(cmd);
    }
  });
});

console.log(`relay listening on ws://127.0.0.1:${port}`);
