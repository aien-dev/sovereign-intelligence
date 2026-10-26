// call.js: read-only oracle. Loads the module irwasm wrote and calls its exports; generates nothing.
'use strict';
const fs = require('node:fs');
const bytes = fs.readFileSync(process.argv[2]);
console.log('valid wasm:', WebAssembly.validate(bytes));
const m = new WebAssembly.Module(bytes);
console.log('imports:', WebAssembly.Module.imports(m).length);
console.log('exports:', WebAssembly.Module.exports(m).map(e => e.name).join(' '));
const x = new WebAssembly.Instance(m).exports;
console.log(x.gcd(1071, 462) >>> 0);
console.log(x.lcm(21, 6) >>> 0);
console.log(x.tri(10) >>> 0);
console.log(x.addi(2, 3));
try {
  x.addi(2147483647, 1);
  console.log('addi(2147483647, 1): no trap');
} catch (e) {
  console.log('addi(2147483647, 1) trapped:', e instanceof WebAssembly.RuntimeError);
}
