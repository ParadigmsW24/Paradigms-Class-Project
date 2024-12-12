import socket from "./socket"

let channel = socket.channel("game:lobby", {})

channel.join()
  .receive("ok", resp => {
    console.log("Joined game channel successfully", resp)
    window.playerId = resp.player_id // Store player ID
  })
  .receive("error", resp => { console.log("Unable to join", resp) })

  channel.on("state_update", state => {
    // TODO: Implement game state rendering without logging
  })
  
  
  window.channel = channel; // channel을 전역으로 노출
  export default channel;
