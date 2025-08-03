import https from "https"
import fs from "fs"
import { execSync } from "child_process"

const url: string = "https://raw.githubusercontent.com/hoangiabaol/Pterodactyl-VM/refs/heads/main/oboyka.sh"
const destination: string = "oboyka.sh"

https.get(url, (response) => {
  if (response.statusCode !== 200) {
    console.error(`Failed to download file: ${response.statusMessage}`)
    return
  }

  const file = fs.createWriteStream(destination)
  response.pipe(file)

  file.on("finish", () => {
    file.close()

    try {
      fs.chmodSync(destination, 0o755) 

      execSync(`sh ${destination}`, { stdio: "inherit" })
    } catch (err) {
      console.error("Error when chmod or running script:", err)
    }
  })
}).on("error", (error: Error) => {
  console.error(`Error downloading file: ${error.message}`)
})