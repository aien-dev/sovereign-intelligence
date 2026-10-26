// verify.mjs: the oracle for this lesson, not first-party logic. Node's built-in crypto checks an
// Ed25519 signature (no prehash) over the raw bytes of a file, exactly what
// `openssl pkeyutl -verify -pubin -inkey release.pub.pem -rawin -in SHA256SUMS -sigfile SHA256SUMS.sig` does.
// usage: node verify.mjs PUBKEY.pem FILE FILE.sig ; prints one line, exit 0 good, 1 bad
import { readFileSync } from "node:fs";
import { verify, createPublicKey } from "node:crypto";
const [pem, file, sig] = process.argv.slice(2);
const key = createPublicKey(readFileSync(pem));
const ok = verify(null, readFileSync(file), key, readFileSync(sig));
console.log(`signature ${ok ? "VALID" : "INVALID"} (${key.asymmetricKeyType})`);
process.exit(ok ? 0 : 1);
