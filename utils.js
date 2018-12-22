'use strict';

const canvas = document.getElementById("canvas");
canvas.addEventListener('oncontextmenu', event => {
  event.preventDefault();
});

// show Emscripten environment where the canvas is
// arguments are passed to PICO-8

var Module = {};
Module.canvas = canvas;

/*
  // When pico8_buttons is defined, PICO-8 takes each int to be a live bitfield
  // representing the state of each player's buttons
  
  var pico8_buttons = [0, 0, 0, 0, 0, 0, 0, 0]; // max 8 players
  pico8_buttons[0] = 2 | 16; // example: player 0, RIGHT and Z held down
  
  // when pico8_gpio is defined, reading and writing to gpio pins will
  // read and write to these values
  var pico8_gpio = new Array(128);
*/

// key blocker. prevent cursor keys from scrolling page while playing cart.
		
function onKeyDown_blocker(event) {
  const o = document.activeElement;
  if (!o || o == document.body || o.tagName == "canvas")
  {
    if ([32, 37, 38, 39, 40].indexOf(event.keyCode) > -1)
    {
      event.preventDefault();
    }
  }
}

document.addEventListener('keydown', onKeyDown_blocker, false);
