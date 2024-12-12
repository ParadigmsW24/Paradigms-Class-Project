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
    this.load.spritesheet("soldier", "assets/images/knightspritelist115-95.png", { frameWidth: 115, frameHeight: 95 });
    this.load.spritesheet("archer", "assets/images/ArcherSpritelist115-126.png", { frameWidth: 115, frameHeight: 126 });
    this.load.spritesheet("cavalry", "assets/images/horse95-80.png", { frameWidth: 95, frameHeight: 80 });
  },

  create() {
    // Add the background
    this.add.image(400, 300, "background"); // Centered background
    this.units = this.add.group(); // Group for all units

    // Create animations
    this.anims.create({
      key: "soldier_walk",
      frames: this.anims.generateFrameNumbers("soldier", { start: 0, end: 3 }),
      frameRate: 10,
      repeat: -1,
    });

    this.anims.create({
      key: "soldier_attack",
      frames: this.anims.generateFrameNumbers("soldier", { start: 4, end: 7 }),
      frameRate: 10,
      repeat: -1,
    });

    this.anims.create({
      key: "soldier_death",
      frames: this.anims.generateFrameNumbers("soldier", { start: 8, end: 11 }),
      frameRate: 10,
      repeat: 0,
    });

    this.anims.create({
      key: "archer_walk",
      frames: this.anims.generateFrameNumbers("archer", { start: 0, end: 3 }),
      frameRate: 10,
      repeat: -1,
    });

    this.anims.create({
      key: "archer_attack",
      frames: this.anims.generateFrameNumbers("archer", { start: 4, end: 7 }),
      frameRate: 10,
      repeat: -1,
    });

    this.anims.create({
      key: "archer_death",
      frames: this.anims.generateFrameNumbers("archer", { start: 8, end: 11 }),
      frameRate: 10,
      repeat: 0,
    });

    this.anims.create({
      key: "cavalry_walk",
      frames: this.anims.generateFrameNumbers("cavalry", { start: 0, end: 3 }),
      frameRate: 10,
      repeat: -1,
    });

    this.anims.create({
      key: "cavalry_attack",
      frames: this.anims.generateFrameNumbers("cavalry", { start: 4, end: 7 }),
      frameRate: 10,
      repeat: -1,
    });

    this.anims.create({
      key: "cavalry_death",
      frames: this.anims.generateFrameNumbers("cavalry", { start: 8, end: 11 }),
      frameRate: 10,
      repeat: 0,
    });
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
      }

      const sprite = this.units.create(unit.x, unit.y, spriteKey);
      sprite.play(`${unit.type}_${unit.action}`);
    });
  },
};

export default GameRenderer;