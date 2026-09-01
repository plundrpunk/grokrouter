#!/usr/bin/env node
import { readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createPrivateKey, createPublicKey, sign, verify } from "node:crypto";

const projectRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const registryPath = process.argv[2] || join(projectRoot, "compatibility", "0.30.0-hosts.json");
const signaturePath = process.argv[3] || `${registryPath}.sig`;
const privateKeyPath = process.env.GROKROUTER_HOST_REGISTRY_PRIVATE_KEY
  || join(homedir(), ".config", "grokrouter", "release", "host-registry-private.pem");
const publicKeyPath = join(projectRoot, "compatibility", "registry-public-key.pem");

const [registry, privateKeyPem, publicKeyPem] = await Promise.all([
  readFile(registryPath),
  readFile(privateKeyPath),
  readFile(publicKeyPath),
]);
const privateKey = createPrivateKey(privateKeyPem);
const publicKey = createPublicKey(publicKeyPem);
if (!createPublicKey(privateKey).equals(publicKey)) {
  throw new Error("The private signing key does not match compatibility/registry-public-key.pem");
}
const signature = sign(null, registry, privateKey);
if (!verify(null, registry, publicKey, signature)) {
  throw new Error("Generated host-registry signature did not verify");
}
await writeFile(signaturePath, `${signature.toString("base64")}\n`, { mode: 0o644 });
process.stdout.write(`${signaturePath}\n`);
