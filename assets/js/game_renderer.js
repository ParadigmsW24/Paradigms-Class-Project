import Phaser from "phaser";

const GameRenderer = {
  init() {
    // Phaser Game Configuration
    const config = {
      type: Phaser.AUTO,
      width: 800, // Game width
      height: 600, // Game height
      parent: "game-container", // Attach Phaser to a specific container
      scene: {
        preload: this.preload,
        create: this.create,
        update: this.update
      }
    };

    // Initialize the Phaser game instance
    this.game = new Phaser.Game(config);
  },

  preload() {
    // Load assets
    this.load.image("background", "path/to/background.png");
    this.load.image("soldier", "path/to/soldier.png");
  },

  create() {
    // Add the background
    this.add.image(400, 300, "background"); // Centered background
    this.soldiers = this.add.group(); // Group for soldier units
  },

  update() {
    // Add game loop logic if needed
  },

  render(state) {
    // Clear existing soldiers
    this.soldiers.clear(true, true);

    // Render soldiers based on game state
    state.units.forEach(unit => {
      if (unit.type === "soldier") {
        const soldier = this.soldiers.create(unit.x, unit.y, "soldier");
        soldier.setOrigin(0.5, 0.5);
      }
    });
  }
};

// Initialize Phaser when the module loads
GameRenderer.init();

export default GameRenderer;
