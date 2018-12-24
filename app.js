const pico8_gpio = new Array(128);

pico8_gpio.fill(0);

class Warp {
  constructor(x, y, to, tx, ty) {
    this.x = x;
    this.y = y;
    this.to = to;
    this.tx = tx;
    this.ty = ty;
  }
}

class Map {
  constructor(id, width, height, data, playerX, playerY) {
    this.id = id;
    this.width = width;
    this.height = height;
    this.data = data;
    this.playerX = playerX;
    this.playerY = playerY;
    this.warps = [];
  }
  addWarp(x, y, to, tx, ty) {
    this.warps.push(new Warp(x, y, to, tx, ty));
  }
}

const maps = [];
let activeMap;
let mapReadIndex = 0;
let warpReadIndex = 0;

maps.push(new Map(
  0,
  8,
  24,
  [
    3, 3, 3, 3, 3, 3, 3, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 6, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 3,
    3, 3, 3, 3, 3, 3, 3, 3,
  ],
  3,
  3
));

maps.push(new Map(
  1,
  12,
  8,
  [
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
  ],
  3,
  3
));

maps[0].addWarp(6,2,1,1,1);
maps[1].addWarp(1,5,0,1,1);

poll();

function poll() {
  /*
    pin0 modes
    0 idle
    1 map request (pin1 mapid)
    2 sending map dimensions (pin1 w pin2 h)
    3 map data request
    4 sending map data (pin1 - pin17)
    5 warp request
    6 sending warp (pin1 x pin2 y pin3 id pin4 tx pin5 ty)
    7 done
  */
  requestAnimationFrame(poll);
  switch(pico8_gpio[0]) {
    case 1:
      // set active map
      const mapId = pico8_gpio[1];
      activeMap = maps[mapId];
      // reset map read position
      mapReadIndex = 0;
      // reset warp read position
      warpReadIndex = 0;
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
      if (warpReadIndex >= activeMap.warps.length) {
        pico8_gpio[0] = 7;
        console.log('done sending warps');
        break;
      }
      // send warp
      let warp = activeMap.warps[warpReadIndex];
      pico8_gpio[1] = warp.x;
      pico8_gpio[2] = warp.y;
      pico8_gpio[3] = warp.to;
      pico8_gpio[4] = warp.tx;
      pico8_gpio[5] = warp.ty;
      pico8_gpio[0] = 6;
      warpReadIndex++;
      console.log('sending warp');
      break;
  }
}

