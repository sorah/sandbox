// melon
const fs = require("fs");
const Canvas = require("canvas");

class Randomizer {
  constructor(seed) {
    this.PARAM_A = 1103515245;
    this.PARAM_B = 12345;
    this.RAND_MAX = 32767;

    this.seed = seed;
    this.state = ((s) => {
      const chars = s.split('').map((c) => c.charCodeAt(0));
      let r = 0;
      while (chars.length > 0) {
        const a = chars.shift();
        const b = chars.shift() || 0;
        r += a << 8 | b;
      }
      return r;
    })(seed);
  }

  nextState() {
    const lastState = this.state;
    this.state = (this.state * this.PARAM_A + this.PARAM_B) % (this.RAND_MAX + 1);
    //console.log([this.seed, lastState, this.state]);
    return this.state;
  }

  rand(m) {
    const state = this.nextState();
    if (!m) return state;
    return Math.floor(state / (Math.floor(this.RAND_MAX / (m + 1)) + 1));
  }

  shuffle(sourceArray) {
    const ary = [].concat(sourceArray);
    for (let i = 0; i < ary.length; i++) {
      const n = this.rand(ary.length - 1);
      const elem = ary[n];
      ary[n] = ary[i];
      ary[i] = elem;
    }
    return ary;
  }
}

async function perform(keys_path, source_path, destination_path) {
  if (!keys_path || !source_path || !destination_path) {
    console.log("keys_path, source_path, destination_path");
    return;
  }
  const keys = JSON.parse(await fs.promises.readFile(keys_path));
  pageOps = keys.map((key, i) => performPage(keys[i], `${source_path}/${i+1}.jpg`, `${destination_path}/${i+1}.png`));
  await Promise.all(pageOps);
}

async function performPage(seed, source_path, destination_path) {
  const sourceImageData = await fs.promises.readFile(source_path);
  const sourceImage = new Canvas.Image();
  sourceImage.src = sourceImageData;

  const canvas = Canvas.createCanvas(sourceImage.width, sourceImage.height);

  const unitWidth = 96;
  const unitHeight = 128;
  const unitCountX = Math.floor(canvas.width / unitWidth);
  const unitCountY = Math.floor(canvas.height / unitHeight);
  //console.log({unitCountX, unitCountY, canvasWidth: canvas.width, canvasHeight: canvas.height});

  const ops = calculateDrawOperations(seed, unitCountX * unitCountY);

  const ctx = canvas.getContext('2d');
  ctx.drawImage(sourceImage, 0, 0);

  //console.log([source_path, ops.length, ops]);

  for(let i = 0; i < ops.length; i++) {
    const op = ops[i];
    const sx = Math.floor(i % unitCountX) * unitWidth;
    const sy = Math.floor(i / unitCountX) * unitHeight;
    const sw = unitWidth;
    const sh = unitHeight;
    const dx = Math.round(Math.floor(op % unitCountX) * unitWidth);
    const dy = Math.round(Math.floor(op / unitCountX) * unitHeight);
    const dw = unitWidth;
    const dh = unitHeight;
    //console.log([op, sx, sy, sw, sh, dx, dy, dw, dh]);
    ctx.drawImage(sourceImage, sx, sy, sw, sh, dx, dy, dw, dh);
  }

  return writePng(canvas, destination_path);
}

function calculateDrawOperations(seed, unitCounts) {
  const ary = Array.from(new Array(unitCounts).keys());
  //const r = (new Randomizer(seed));
  //console.log([seed, r.rand(), r.rand(), r.rand()]);
  return (new Randomizer(seed)).shuffle(ary);
}

function writePng(canvas, destination_path) {
  return new Promise((resolve,reject) => {
    const out = fs.createWriteStream(destination_path);
    const stream = canvas.createPNGStream();
    stream.pipe(out);
    out.on('finish', () => {
      console.log(destination_path);
      resolve(destination_path);
    });
  });
}

perform(process.argv[2], process.argv[3], process.argv[4]).catch((e) => console.log(e));
