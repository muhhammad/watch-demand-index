import { spawn } from "node:child_process"
import { writeFile } from "node:fs/promises"

const port = process.env.PORT || "5173"
const apiBaseUrl = process.env.VITE_API_BASE_URL || ""

await writeFile(
  "./dist/runtime-config.js",
  `window.__APP_CONFIG__ = ${JSON.stringify({ VITE_API_BASE_URL: apiBaseUrl })};\n`,
  "utf8",
)

const listenTarget = `tcp://0.0.0.0:${port}`

console.log(`Starting static server on ${listenTarget}`)

const child = spawn("node", ["./node_modules/serve/build/main.js", "-s", "dist", "-l", listenTarget], {
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
