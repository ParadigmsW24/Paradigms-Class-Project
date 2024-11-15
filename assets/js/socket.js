import { Socket } from "phoenix"

let socket = new Socket("/socket", { params: {} })

// Test commit

socket.connect()

export default socket
