import { Socket } from "phoenix"

let socket = new Socket("/socket", { params: {} })

//Final

socket.connect()

export default socket
