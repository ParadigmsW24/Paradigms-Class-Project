// Import dependencies
import "phoenix_html"

// Import local files
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Import your game modules
import channel from "./game_channel"
import GameRenderer from "./game_renderer"

// Set up CSRF token for LiveView
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Initialize LiveSocket
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken }
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Set up the game
// Listen for state updates and render the game
channel.on("state_update", state => {
  GameRenderer.render(state)
})

// Example: Handle user interactions (e.g., spawning units)
document.addEventListener("DOMContentLoaded", () => {
  // Ensure the DOM is fully loaded before adding event listeners

  // Example button for spawning a soldier unit
  const spawnSoldierButton = document.getElementById("spawn-soldier-button")
  if (spawnSoldierButton) {
    spawnSoldierButton.addEventListener("click", () => {
      channel.push("spawn_unit", { unit_type: "soldier" })
    })
  }

  // TODO: Add event listeners for other unit types and actions
})

document.addEventListener("DOMContentLoaded", () => {
  const spawnSoldierButton = document.getElementById("spawn-archer-button");
  if (spawnSoldierButton) {
    spawnSoldierButton.addEventListener("click", () => {
      channel.push("spawn_unit", { unit_type: "archer" });
    });
  }
});


// Handle sound effects for unit creation
channel.on("sound_effect", payload => {
  const { event, data } = payload;

  if (event === "unit_creation") {
    const soundMap = {
      archer: "/sounds/archer_spawn.mp3",
      soldier: "/sounds/soldier_spawn.mp3",
      cavalry: "/sounds/cavalry_spawn.wav"
    };

    const soundPath = soundMap[data.unit_type];
    if (soundPath) {
      const audio = new Audio(soundPath);
      audio.play();
    }
  }
});


// Export channel if needed elsewhere
export default channel
