#!/usr/bin/env node
/**
 * One-off: read MCP SQL output file, extract html from json_block, then extract
 * window.__INITIAL__DATA__ = { "vhr": ... } and write vhr to JSON file.
 */
const fs = require("fs");
const path = require("path");

const inputPath = process.argv[2] || "/Users/kevoo/.cursor/projects/Users-kevoo-Cursor/agent-tools/591f2d17-ffb3-4c3b-8349-2eecc5aafb71.txt";
const outputPath = process.argv[3] || path.join(__dirname, "..", "deep-check-klaronda-vhr.json");

let raw = fs.readFileSync(inputPath, "utf8");

// File may be wrapped as a JSON string (starts with ")
if (raw.startsWith('"')) {
  try {
    raw = JSON.parse(raw);
  } catch (e) {
    console.error("Failed to parse outer JSON string:", e.message);
    process.exit(1);
  }
}

// Find the JSON array in the content (after boundary tag)
const arrayStart = raw.indexOf('[{"');
if (arrayStart === -1) {
  console.error("Could not find JSON array in file");
  process.exit(1);
}
// Find matching ] (respect strings)
let depth = 0;
let inString = false;
let escape = false;
let quoteChar = "";
let arrayEnd = -1;
for (let i = arrayStart; i < raw.length; i++) {
  const c = raw[i];
  if (escape) {
    escape = false;
    continue;
  }
  if (c === "\\" && inString) {
    escape = true;
    continue;
  }
  if ((c === '"' || c === "'") && (!inString || c === quoteChar)) {
    inString = !inString;
    if (inString) quoteChar = c;
    continue;
  }
  if (!inString) {
    if (c === "[" || c === "{") depth++;
    else if (c === "]" || c === "}") {
      depth--;
      if (depth === 0 && c === "]") {
        arrayEnd = i;
        break;
      }
    }
  }
}
if (arrayEnd === -1) {
  console.error("Could not find end of array");
  process.exit(1);
}
let arr;
try {
  arr = JSON.parse(raw.slice(arrayStart, arrayEnd + 1));
} catch (e) {
  console.error("Failed to parse array:", e.message);
  process.exit(1);
}
const jsonBlock = arr[0]?.json_block;
if (!jsonBlock) {
  console.error("No json_block in result");
  process.exit(1);
}
// Extract window.__INITIAL__DATA__ = { ... };
const marker = "window.__INITIAL__DATA__";
const idx = jsonBlock.indexOf(marker);
if (idx === -1) {
  console.error("Marker not found in html");
  process.exit(1);
}
const after = jsonBlock.slice(idx + marker.length);
const eqMatch = after.match(/^\s*=\s*/);
if (!eqMatch) {
  console.error("No = after marker");
  process.exit(1);
}
const jsonStart = after.indexOf("{", eqMatch.length);
if (jsonStart === -1) {
  console.error("No { after =");
  process.exit(1);
}
let objDepth = 0;
let objInString = false;
let objEscape = false;
let jsonEnd = -1;
for (let i = jsonStart; i < after.length; i++) {
  const c = after[i];
  if (objEscape) {
    objEscape = false;
    continue;
  }
  if (c === "\\" && objInString) {
    objEscape = true;
    continue;
  }
  if (c === '"') {
    objInString = !objInString;
    continue;
  }
  if (!objInString) {
    if (c === "{") objDepth++;
    else if (c === "}") {
      objDepth--;
      if (objDepth === 0) {
        jsonEnd = i;
        break;
      }
    }
  }
}
if (jsonEnd === -1) {
  console.error("Could not find end of JSON object");
  process.exit(1);
}
const jsonStr = after.slice(jsonStart, jsonEnd + 1);
const data = JSON.parse(jsonStr);
const vhr = data.vhr != null ? data.vhr : data;
fs.writeFileSync(outputPath, JSON.stringify(vhr, null, 2), "utf8");
console.log("Wrote", outputPath);
console.log("Top-level keys:", Object.keys(vhr).slice(0, 25));
process.exit(0);
