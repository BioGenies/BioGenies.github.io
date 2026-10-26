import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const source = readFileSync(new URL('../assets/imputation-demo.js', import.meta.url), 'utf8');
const {DATA, METHODS, makeMask, estimate, meanAbsoluteError} = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
const original = JSON.stringify(DATA);
let cases = 0;
for (const pattern of ['random', 'low']) for (let rate = 10; rate <= 50; rate += 5) for (let seed = 0; seed < 10; seed++) {
  const mask = makeMask(DATA, rate, pattern, seed);
  assert.deepEqual(mask, makeMask(DATA, rate, pattern, seed), 'A seed must reproduce the hidden set');
  assert.equal(mask.flat().filter(Boolean).length, Math.round(48 * rate / 100));
  for (let c = 0; c < 4; c++) assert(mask.filter(row => !row[c]).length >= 2);
  for (const method of Object.keys(METHODS)) {
    const result = estimate(DATA, mask, method);
    DATA.forEach((row, r) => row.forEach((v, c) => { assert(Number.isFinite(result[r][c])); if (!mask[r][c]) assert.equal(result[r][c], v); }));
    assert(meanAbsoluteError(DATA, mask, result) >= 0);
    cases++;
  }
}
const values = [[1], [2], [100], [999]], mask = [[false], [false], [false], [true]];
assert.equal(estimate(values, mask, 'median')[3][0], 2);
assert.equal(estimate(values, mask, 'mean')[3][0], 103 / 3);
const neighbors = [[0, 0], [10, 10], [20, 20], [30, 30], [999, 1]];
const neighborMask = [[false, false], [false, false], [false, false], [false, false], [true, false]];
const result = estimate(neighbors, neighborMask, 'knn');
assert.equal(result[4][0], 10, 'Average of the three nearest donors');
assert.equal(result[0][0], 0, 'A measured zero remains a measurement');
assert.equal(meanAbsoluteError(neighbors, neighborMask, result), 989);
neighborMask[4][1] = true;
assert.deepEqual(estimate(neighbors, neighborMask, 'knn')[4], [15, 15], 'No shared feature falls back to observed means');
assert.notDeepEqual(makeMask(DATA, 25, 'random', 42), makeMask(DATA, 25, 'random', 43));
assert.notDeepEqual(makeMask(DATA, 25, 'low', 42), makeMask(DATA, 25, 'low', 43));
assert.equal(JSON.stringify(DATA), original, 'The complete reference data must not change');
assert.deepEqual(makeMask(DATA, 0).flat().filter(Boolean), []);
assert.equal(meanAbsoluteError(DATA, makeMask(DATA, 0), DATA), null);
assert.throws(() => estimate(DATA, makeMask(DATA, 25), 'invalid'));
console.log(`Imputation checks passed: ${cases} method/mask combinations, numeric fixtures, fallback, zero values and no mutation.`);
