import { spawn } from "node:child_process"

const port = process.env.PORT || "5173"
const listenTarget = `tcp://0.0.0.0:${port}`

const child = spawn("./node_modules/.bin/serve", ["-s", "dist", "-l", listenTarget], {
  stdio: "inherit",
})

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal)
    return
  }
  process.exit(code ?? 0)
})

child.on("error", (error) => {
  console.error("Failed to start static server:", error)
  process.exit(1)
})
