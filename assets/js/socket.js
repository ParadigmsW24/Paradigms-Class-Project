import { Socket } from "phoenix"

let socket = new Socket("/socket", { params: {} })

socket.connect()

export default socket
