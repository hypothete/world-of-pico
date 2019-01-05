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
  constructor(id, width, height, data) {
    this.id = id;
    this.width = width;
    this.height = height;
    this.data = data;
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
  16,
  16,
  [
    7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 7, 8,  
    9,10, 9,10, 9,10, 9,10, 9,10, 9,10, 9,10, 9,10, 
    7, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 8, 
    9,10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,10, 
    7, 8, 1, 1, 1, 3, 3, 3, 3, 3, 1, 1, 1, 1, 7, 8, 
    9,10, 1, 1, 1, 4, 4, 4, 4, 4, 1, 1, 1, 1, 9,10, 
    7, 8, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 7, 8, 
    9,10, 1, 1, 1, 2, 2, 2, 6, 2, 1, 1, 1, 1, 9,10, 
    7, 8, 1, 1, 1, 2, 5, 2, 2, 2, 1, 1, 1, 1, 1, 1, 
    9,10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,1 , 
    7, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 8, 
    9,10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,10, 
    7, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 7, 8, 
    9,10, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9,10, 
    7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 
    9,10, 9,10, 9,10, 9,10, 9,10, 9,10, 9,10, 9,10,
  ]
));

maps.push(new Map(
  1,
  12,
  8,
  [
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 
    2, 6, 6, 2, 2, 2, 2, 2, 2, 6, 6, 2, 
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    11,15,11,11,11,11,13,14,11,11,11,11,
    11,11,11,11,11,11,11,11,11,11,11,11,
    11,12,11,11,11,11,11,11,11,11,11,11,
    11,11,11,11,11,11,11,11,11,11,11,11,
    11,11,11,11,11,1, 1, 11,11,11,11,11,
  ]
));

maps.push(new Map(
  2,
  24,
  24,
  [
    7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 16,16,16,16,1, 1,1, 18,17,17,17,17, 
    9, 10,9, 10,9, 10,9, 10,9, 10,9, 10,16,16,16,16,1, 1,18,17,17,17,17,17,
    7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 16,16,16,16,1, 1,17,17,17,17,17,17, 
    9, 10,9, 10,9, 10,9, 10,9, 10,9, 10,16,16,16,16,1, 1,17,17,17,17,17,17,
    1, 1, 1, 1, 1, 1, 7, 8, 7, 8, 1, 1, 16,16,16,16,1, 1,17,17,17,17,17,17, 
    1, 1, 1, 1 ,1, 1 ,9, 10,9, 10,1, 1 ,16,16,16,16,1, 1,19,17,17,17,17,17,
    7, 8, 7, 8, 1, 1, 7, 8, 7, 8, 1, 1, 16,16,16,16,1, 1, 1,19,20,17,17,17, 
    9, 10,9, 10,1, 1 ,9, 10,9, 10,1, 1 ,16,16,16,16,1, 1, 1, 1, 1, 1, 1, 1,
    7, 8, 7, 8, 1, 1, 7, 8, 7, 8, 1, 1, 16,16,16,16,1, 1, 1, 1, 1, 1, 1, 1, 
    9, 10,9, 10,1, 1 ,9, 10,9, 10,1, 1 ,16,16,16,16,1, 1, 1, 1, 1, 1, 1, 1,
    7, 8, 7, 8, 1, 1, 7, 8, 7, 8, 1, 1, 16,16,16,16,1, 1, 1, 1, 1, 1, 1, 1, 
    9, 10,9, 10,1, 1 ,9, 10,9, 10,1, 1 ,16,16,16,16,1, 1, 1, 1, 1, 1, 1, 1,
    7, 8, 7, 8, 1, 1, 7, 8, 7, 8, 1, 1, 16,16,16,16,1, 1, 1, 1, 1, 1, 1, 1, 
    9, 10,9, 10,1, 1 ,9, 10,9, 10,1, 1 ,16,16,16,16,1, 1, 1, 1, 1, 1, 1, 1,
    7, 8, 7, 8, 1, 1, 1, 1, 1, 1, 1, 1, 16,16,16,16,1, 1, 1, 1, 1, 1, 7, 8, 
    9, 10,9, 10,1, 1 ,1, 1 ,1, 1 ,1, 1 ,16,16,16,16,1, 1 ,1, 1 ,1, 1 ,9, 10,
    7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 1, 1, 16,16,16,16,1, 1, 1, 1, 7, 8, 7, 8, 
    9, 10,9, 10,9, 10,9, 10,9, 10,1, 1 ,16,16,16,16,1, 1 ,1, 1 ,9, 10,9, 10,
    7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 1, 1, 16,16,16,16,1, 1, 7, 8, 7, 8, 7, 8, 
    9, 10,9, 10,9, 10,9, 10,9, 10,1, 1 ,16,16,16,16,1, 1 ,9, 10,9, 10,9, 10,
    7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 1, 1, 16,16,16,16,1, 1, 7, 8, 7, 8, 7, 8, 
    9, 10,9, 10,9, 10,9, 10,9, 10,1, 1 ,16,16,16,16,1, 1 ,9, 10,9, 10,9, 10,
    7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 7, 8, 16,16,16,16,1, 1, 7, 8, 7, 8, 7, 8, 
    9, 10,9, 10,9, 10,9, 10,9, 10,9, 10,16,16,16,16,1, 1 ,9, 10,9, 10,9, 10,
  ]
))

// to inside the house
maps[0].addWarp(6,8,1,5,6);

// east outside
maps[0].addWarp(15,8,2,1,4);
maps[0].addWarp(15,9,2,1,5);

// to outside the house
maps[1].addWarp(5,7,0,6,9);
maps[1].addWarp(6,7,0,6,9);

// to the starting map
maps[2].addWarp(0,4,0,14,8);
maps[2].addWarp(0,5,0,14,9);

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
      pico8_gpio.splice(1, 64, ...activeMap.data.slice(mapReadIndex, mapReadIndex+64));
      mapReadIndex += 64;
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

