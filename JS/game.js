const gameConfig = {
  type: Phaser.AUTO,
  parent: 'game',
  width: 800,
  height: 640,
  scale: {
    mode: Phaser.Scale.RESIZE,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  scene: {
    preload: preloadScene,
    create: createScene,
    update: updateScene,
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { y: 500 },
    },
  },
};

const myGame = new Phaser.Game(gameConfig);

function preloadScene() {
  this.load.image('bg', 'assets/images/background.png');
  this.load.image('tile', 'assets/tilesets/platformPack_tilesheet.png');
  this.load.image('hazard', 'assets/images/spike.png');
  this.load.image('goal', 'assets/images/winCircle.png');
  this.load.image('collectible', 'assets/images/point.png');
  this.load.image('foe', 'assets/images/enemy.png');
  this.load.tilemapTiledJSON('level1', 'assets/tilemaps/level1.json');
  this.load.atlas('char', 'assets/images/kenney_player.png', 'assets/images/kenney_player_atlas.json');
}

function createScene() {
  const map = this.make.tilemap({ key: 'level1' });
  const tiles = map.addTilesetImage('kenney_simple_platformer', 'tile');
  const bgImage = this.add.image(0, 0, 'bg').setOrigin(0, 0);
  bgImage.setScale(5, 4);

  const groundLayer = map.createStaticLayer('Platforms', tiles, 0, 200);
  groundLayer.setCollisionByExclusion(-1, true);

  this.hero = this.physics.add.sprite(50, 300, 'char');
  this.hero.body.setSize(this.hero.body.width - 20, this.hero.body.height - 20).setOffset(10, 20);
  this.hero.setBounce(0.1);
  this.hero.setCollideWorldBounds(true);
  this.physics.add.collider(this.hero, groundLayer);

  this.scoreText = this.add.text(16, 16, 'Score: 0', { fontSize: '32px', fill: '#000' });
  this.score = 0;
  this.hero.lives = 3;
  this.livesText = this.add.text(16, 40, 'Lives: ' + this.hero.lives, { fontSize: '32px', fill: '#000' });

  this.enemy = this.physics.add.sprite(500, 500, 'foe');
  this.enemy.setScale(0.4);
  this.enemy.setCollideWorldBounds(true);
  this.physics.add.collider(this.enemy, groundLayer);

  this.anims.create({
    key: 'run',
    frames: this.anims.generateFrameNames('char', {
      prefix: 'robo_player_',
      start: 2,
      end: 3,
    }),
    frameRate: 10,
    repeat: -1,
  });

  this.anims.create({
    key: 'stand',
    frames: [{ key: 'char', frame: 'robo_player_0' }],
    frameRate: 10,
  });

  this.anims.create({
    key: 'leap',
    frames: [{ key: 'char', frame: 'robo_player_1' }],
    frameRate: 10,
  });

  this.controls = this.input.keyboard.createCursorKeys();

  this.traps = this.physics.add.group({
    allowGravity: false,
    immovable: true,
  });

  this.goals = this.physics.add.group({
    allowGravity: false,
    immovable: true,
  });

  this.collectibles = this.physics.add.group({
    allowGravity: false,
    immovable: true,
  });

  map.getObjectLayer('Spikes').objects.forEach((trap) => {
    const trapSprite = this.traps.create(trap.x, trap.y + 200 - trap.height, 'hazard').setOrigin(0);
    trapSprite.body.setSize(trap.width, trap.height - 20).setOffset(0, 20);
  });

  map.getObjectLayer('WinCircle').objects.forEach((goal) => {
    const goalSprite = this.goals.create(goal.x, goal.y + 200 - goal.height, 'goal').setOrigin(0);
    goalSprite.setScale(0.2);
  });

  map.getObjectLayer('Points').objects.forEach((item) => {
    const itemSprite = this.collectibles.create(item.x, item.y + 100, 'collectible').setOrigin(0);
    itemSprite.setScale(0.4);
  });

  this.physics.add.collider(this.hero, this.traps, handlePlayerHit, null, this);
  this.physics.add.collider(this.hero, this.goals, handlePlayerWin, null, this);
  this.physics.add.collider(this.hero, this.collectibles, handleCollectPoint, null, this);
  this.physics.add.collider(this.hero, this.enemy, handleEnemyCollision, null, this);
}

function updateScene() {
  if (this.controls.left.isDown) {
    this.hero.setVelocityX(-200);
    if (this.hero.body.onFloor()) {
      this.hero.play('run', true);
    }
  } else if (this.controls.right.isDown) {
    this.hero.setVelocityX(200);
    if (this.hero.body.onFloor()) {
      this.hero.play('run', true);
    }
  } else {
    this.hero.setVelocityX(0);
    if (this.hero.body.onFloor()) {
      this.hero.play('stand', true);
    }
  }

  if ((this.controls.space.isDown || this.controls.up.isDown) && this.hero.body.onFloor()) {
    this.hero.setVelocityY(-350);
    this.hero.play('leap', true);
  }

  if (this.hero.body.velocity.x > 0) {
    this.hero.setFlipX(false);
  } else if (this.hero.body.velocity.x < 0) {
    this.hero.setFlipX(true);
  }

  if (this.hero.body.position.y > 563) {
    this.hero.setVelocity(0, 0);
    this.hero.setX(50);
    this.hero.setY(300);
    this.hero.lives -= 1;
    this.livesText.setText('Lives: ' + this.hero.lives);
  }

  if (this.enemy.body.blocked.right) {
    this.enemy.direction = 'LEFT';
  }

  if (this.enemy.body.blocked.left) {
    this.enemy.direction = 'RIGHT';
  }

  if (this.enemy.direction === 'RIGHT') {
    this.enemy.setVelocityX(100);
  } else {
    this.enemy.setVelocityX(-100);
  }

  if (this.hero.lives === 0) {
    this.hero.disableBody(true, true);
    this.add.text(400, 100, 'Game Over', { fontSize: '64px', fill: '#000' }).setOrigin(0.5);
    this.game.destroy(false, false);
  }
}

function handlePlayerHit(player, spike) {
  player.setVelocity(0, 0);
  player.setX(50);
  player.setY(300);
  player.play('stand', true);
  player.setAlpha(0);
  this.tweens.add({
    targets: player,
    alpha: 1,
    duration: 100,
    ease: 'Linear',
    repeat: 5,
  });
  player.lives -= 1;
  this.livesText.setText('Lives: ' + player.lives);
}

function handlePlayerWin(player, goal) {
  this.add.text(400, 100, 'Level Passed', { fontSize: '64px', fill: '#000' }).setOrigin(0.5);
  this.game.destroy(false, false);
}

function handleCollectPoint(player, point) {
  point.disableBody(true, true);
  this.score += 10;
  this.scoreText.setText('Score: ' + this.score);
}

function handleEnemyCollision(player, enemy) {
  if (player.body.touching.down || enemy.body.blocked.up) {
    enemy.disableBody(true, true);
    return;
  }

  player.setVelocity(0, 0);
  player.setX(50);
  player.setY(300);
  player.play('stand', true);
  player.lives -= 1;
  this.livesText.setText('Lives: ' + player.lives);
}
