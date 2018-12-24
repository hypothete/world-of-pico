const pico8_gpio = new Array(128);

pico8_gpio.fill(0);

class Map {
  constructor(id, width, height, data, playerX, playerY) {
    this.id = id;
    this.width = width;
    this.height = height;
    this.data = data;
    this.playerX = playerX;
    this.playerY = playerY;
  }
}

const maps = [];
let activeMap;
let mapReadIndex = 0;

const map0 = new Map(
  0,
  16,
  16,
  [
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  ],
  3,
  3
);

maps.push(map0);

poll();

function poll() {
  /*
    pin0 modes
    0 idle
    1 map request (pin1 mapid)
    2 sending map dimensions (pin1 w pin2 h)
    3 map data request
    4 sending map data (pin1 - pin17)
    5 player position request
    6 sending player data (pin1 x pin2 y)
    7 error
  */
  requestAnimationFrame(poll);
  switch(pico8_gpio[0]) {
    case 1:
      // set active map
      const mapId = pico8_gpio[1];
      activeMap = maps[mapId];
      // reset map read position
      mapReadIndex = 0;
      // send dimensions
      pico8_gpio[1] = activeMap.width;
      pico8_gpio[2] = activeMap.height;
      pico8_gpio[0] = 2;
      console.log('sending map dimensions');
      break;
    case 3:
      // send map data
      pico8_gpio.splice(1, 16, ...activeMap.data.slice(mapReadIndex, mapReadIndex+16));
      mapReadIndex += 16;
      pico8_gpio[0] = 4;
      console.log('sending map data');
      break;
    case 5:
      // send player position
      pico8_gpio[1] = activeMap.playerX;
      pico8_gpio[2] = activeMap.playerY;
      pico8_gpio[0] = 6;
      console.log('sending player position');
  }
}

