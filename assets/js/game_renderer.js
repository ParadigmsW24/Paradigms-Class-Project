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
        update: this.update,
      },
    };

    // Initialize the Phaser game instance
    this.game = new Phaser.Game(config);
  },

  preload() {
    // Load assets
    this.load.image("background", "path/to/background.png");
    this.load.image("soldier", "path/to/soldier.png");
    this.load.image("archer", "path/to/archer.png");
    this.load.image("cavalry", "path/to/cavalry.png");
  },

  create() {
    // Add the background
    this.add.image(400, 300, "background"); // Centered background
    this.units = this.add.group(); // Group for all units
  },

  update() {
    // Add game loop logic if needed
  },

  render(state) {
    // Clear existing units
    this.units.clear(true, true);

    // Render units based on game state
    state.units.forEach((unit) => {
      let spriteKey;
      switch (unit.type) {
        case "soldier":
          spriteKey = "soldier";
          break;
        case "archer":
          spriteKey = "archer";
          break;
        case "cavalry":
          spriteKey = "cavalry";
          break;
        default:
          console.warn(`Unknown unit type: ${unit.type}`);
          return;
      }

      const renderedUnit = this.units.create(unit.x, unit.y, spriteKey);
      renderedUnit.setOrigin(0.5, 0.5);
    });
  },
};

// Initialize Phaser when the module loads
GameRenderer.init();

export default GameRenderer;
