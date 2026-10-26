// Small, deterministic learning example. No data or settings leave the browser.
export const DATA = Object.freeze([
  [12, 27, 76, 81], [16, 31, 70, 77], [19, 29, 73, 72],
  [25, 38, 65, 70], [29, 43, 59, 63], [34, 40, 62, 60],
  [40, 54, 53, 52], [43, 59, 48, 49], [48, 56, 45, 43],
  [54, 68, 39, 40], [57, 72, 35, 34], [63, 69, 31, 29]
].map(row => Object.freeze(row)));
export const METHODS = Object.freeze({mean: 'Feature mean', median: 'Feature median', knn: 'Three nearest samples'});

function random(seed) {
  let state = seed >>> 0;
  return () => { state += 0x6D2B79F5; let t = state; t = Math.imul(t ^ t >>> 15, t | 1); t ^= t + Math.imul(t ^ t >>> 7, t | 61); return ((t ^ t >>> 14) >>> 0) / 4294967296; };
}
const average = xs => xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null;
const median = xs => { const sorted = [...xs].sort((a, b) => a - b); const i = Math.floor(sorted.length / 2); return sorted.length ? sorted.length % 2 ? sorted[i] : (sorted[i - 1] + sorted[i]) / 2 : null; };

export function makeMask(data, percent, pattern = 'random', seed = 42) {
  if (!data.length || !data[0].length) return [];
  const n = data.length, columns = data[0].length, rng = random(seed);
  const ranges = Array.from({length: columns}, (_, c) => { const values = data.map(row => row[c]); return [Math.min(...values), Math.max(...values) - Math.min(...values) || 1]; });
  const ranked = data.flatMap((row, r) => row.map((value, c) => ({r, c, rank: pattern === 'low' ? (value - ranges[c][0]) / ranges[c][1] + rng() * 0.4 : rng()}))).sort((a, b) => a.rank - b.rank);
  const mask = data.map(row => row.map(() => false)), counts = Array(columns).fill(0);
  const target = Math.round(n * columns * Math.max(0, Math.min(100, percent)) / 100);
  let hidden = 0;
  for (const {r, c} of ranked) {
    // Keep at least two measurements per feature for the teaching methods.
    if (counts[c] >= n - 2 || hidden >= target) continue;
    mask[r][c] = true; counts[c]++; hidden++;
  }
  return mask;
}

export function estimate(data, mask, method) {
  if (!Object.hasOwn(METHODS, method)) throw new Error('Unknown imputation method');
  if (!data.length) return [];
  const columns = data[0].length;
  const observed = Array.from({length: columns}, (_, c) => data.filter((_, r) => !mask[r][c]).map(row => row[c]));
  const means = observed.map(average), medians = observed.map(median);
  const scales = observed.map(xs => xs.length ? Math.max(...xs) - Math.min(...xs) || 1 : 1);
  return data.map((row, r) => row.map((value, c) => {
    if (!mask[r][c]) return value;
    if (method === 'mean') return means[c];
    if (method === 'median') return medians[c];
    const donors = [];
    for (let donor = 0; donor < data.length; donor++) {
      if (donor === r || mask[donor][c]) continue;
      const shared = [];
      for (let feature = 0; feature < columns; feature++) {
        if (feature !== c && !mask[r][feature] && !mask[donor][feature]) shared.push(((row[feature] - data[donor][feature]) / scales[feature]) ** 2);
      }
      if (shared.length) donors.push({value: data[donor][c], distance: average(shared)});
    }
    donors.sort((a, b) => a.distance - b.distance);
    return donors.length ? average(donors.slice(0, 3).map(d => d.value)) : means[c];
  }));
}

export function meanAbsoluteError(data, mask, predictions) {
  const errors = [];
  data.forEach((row, r) => row.forEach((value, c) => { if (mask[r][c] && Number.isFinite(predictions[r][c])) errors.push(Math.abs(value - predictions[r][c])); }));
  return average(errors);
}

export function mountDemo(root) {
  if (!root) return;
  const find = id => root.querySelector('#' + id);
  const rate = find('missing-rate'), pattern = find('missing-pattern'), method = find('imputation-method'), reveal = find('reveal-original');
  let seed = 42, filled = false;
  const format = value => Number.isInteger(value) ? String(value) : value.toFixed(1);
  function render() {
    const mask = makeMask(DATA, Number(rate.value), pattern.value, seed);
    const hidden = mask.flat().filter(Boolean).length;
    const predictions = Object.fromEntries(Object.keys(METHODS).map(key => [key, estimate(DATA, mask, key)]));
    find('missing-rate-value').textContent = rate.value + '%';
    find('fill-gaps').textContent = filled ? 'Show gaps' : 'Fill the gaps';
    find('demo-status').textContent = `${hidden} of ${DATA.length * DATA[0].length} measurements hidden. ${filled ? METHODS[method.value] + ' estimates are shown in the dashed cells.' : 'Choose “Fill the gaps” to add estimates.'}`;
    const body = find('demo-data').querySelector('tbody'); body.replaceChildren();
    DATA.forEach((row, r) => {
      const tr = document.createElement('tr'), th = document.createElement('th'); th.scope = 'row'; th.textContent = 'S' + String(r + 1).padStart(2, '0'); tr.append(th);
      row.forEach((original, c) => {
        const td = document.createElement('td'), isHidden = mask[r][c], value = isHidden ? filled ? predictions[method.value][r][c] : null : original;
        if (isHidden) td.classList.add('demo-estimate');
        if (value !== null) td.style.setProperty('--cell-shade', String(0.06 + value / 100 * 0.25));
        const number = document.createElement('span'); number.textContent = value === null ? '?' : format(value); td.append(number);
        td.setAttribute('aria-label', `${isHidden ? filled ? 'Estimated' : 'Missing' : 'Observed'} ${value === null ? 'value' : format(value)}${isHidden && reveal.checked ? ', original ' + original : ''}`);
        if (isHidden && reveal.checked) { const answer = document.createElement('small'); answer.textContent = 'original ' + original; td.append(answer); }
        tr.append(td);
      }); body.append(tr);
    });
    const scores = Object.entries(METHODS).map(([key, label]) => ({key, label, error: meanAbsoluteError(DATA, mask, predictions[key])}));
    const maxError = Math.max(...scores.map(s => s.error), 1), holder = find('demo-scores'); holder.replaceChildren();
    scores.forEach(score => {
      const card = document.createElement('div'); card.className = 'demo-score' + (score.key === method.value ? ' is-selected' : '');
      const line = document.createElement('div'), label = document.createElement('span'), value = document.createElement('strong'); label.textContent = score.label + (score.key === method.value ? ' · selected' : ''); value.textContent = filled ? score.error.toFixed(2) : '—'; line.append(label, value);
      const track = document.createElement('div'); track.className = 'demo-score-track'; track.setAttribute('aria-hidden', 'true'); const bar = document.createElement('span'); bar.style.width = filled ? 100 * score.error / maxError + '%' : '0%'; track.append(bar); card.append(line, track); holder.append(card);
    });
    const best = [...scores].sort((a, b) => a.error - b.error)[0];
    find('demo-insight').textContent = filled ? `${best.label} has the smallest average error on this hidden set (${best.error.toFixed(2)} a.u.). Change the missingness or try another set to explore the comparison. This ranking applies to this toy example.` : 'Fill the gaps to compare the three methods on exactly the same hidden values.';
  }
  rate.addEventListener('input', render); pattern.addEventListener('change', render); method.addEventListener('change', render); reveal.addEventListener('change', render);
  find('fill-gaps').addEventListener('click', () => { filled = !filled; render(); });
  find('new-missing-set').addEventListener('click', () => { seed++; render(); });
  find('reset-demo').addEventListener('click', () => { seed = 42; filled = false; rate.value = '25'; pattern.value = 'random'; method.value = 'mean'; reveal.checked = false; render(); });
  root.querySelector('fieldset').disabled = false; render();
}
if (typeof document !== 'undefined') mountDemo(document.querySelector('#imputation-demo'));
