(() => {
  const INDICATORS = [
    { value: "pm25", label: "PM25" },
    { value: "ozone", label: "OZONE" },
    { value: "dslpm", label: "DSLPM" },
    { value: "ptraf", label: "PTRAF" },
    { value: "pnpl", label: "PNPL" },
    { value: "ptsdf", label: "PTSDF" },
    { value: "ust", label: "UST" },
    { value: "no2", label: "NO2" },
    { value: "demogidx_2", label: "DEMOGIDX_2" },
    { value: "demogidx_5", label: "DEMOGIDX_5" },
    { value: "d2_pm25", label: "D2_PM25" },
    { value: "d5_pm25", label: "D5_PM25" },
    { value: "p_pm25", label: "P_PM25" },
    { value: "p_ozone", label: "P_OZONE" },
    { value: "p_dslpm", label: "P_DSLPM" },
    { value: "p_demogidx_2", label: "P_DEMOGIDX_2" },
    { value: "peopcolorpct", label: "PEOPCOLORPCT" },
    { value: "lowincpct", label: "LOWINCPCT" },
  ];

  const BASE_COLS = [
    "geoid",
    "state_fips",
    "county_fips",
    "st_abbrev",
    "county_name",
    "acstotpop",
  ];

  const JUSTICE_FILTERS = {
    traffic: {
      cols: ["ptraf"],
      match(row, cutoffs) {
        return aboveCutoff(row.ptraf, cutoffs.ptraf);
      },
    },
    superfund: {
      cols: ["pnpl", "ptsdf"],
      match(row, cutoffs) {
        return (
          aboveCutoff(row.pnpl, cutoffs.pnpl) ||
          aboveCutoff(row.ptsdf, cutoffs.ptsdf)
        );
      },
    },
    air: {
      cols: ["pm25", "ozone", "dslpm"],
      match(row, cutoffs) {
        return (
          aboveCutoff(row.pm25, cutoffs.pm25) ||
          aboveCutoff(row.ozone, cutoffs.ozone) ||
          aboveCutoff(row.dslpm, cutoffs.dslpm)
        );
      },
    },
    demographics: {
      cols: ["peopcolorpct", "lowincpct"],
      match(row, cutoffs) {
        return (
          aboveCutoff(row.peopcolorpct, cutoffs.peopcolorpct) ||
          aboveCutoff(row.lowincpct, cutoffs.lowincpct)
        );
      },
    },
    ejindex: {
      cols: ["d2_pm25", "d5_pm25"],
      match(row, cutoffs) {
        return (
          aboveCutoff(row.d2_pm25, cutoffs.d2_pm25) ||
          aboveCutoff(row.d5_pm25, cutoffs.d5_pm25)
        );
      },
    },
  };

  const STORIES = {
    "highways-lowinc": {
      filters: ["traffic", "demographics"],
      threshold: "p80",
      state: "",
      focus: ["ptraf", "lowincpct", "peopcolorpct"],
    },
    "ca-pm25": {
      filters: ["air"],
      threshold: "p80",
      state: "06",
      focus: ["pm25", "ozone", "dslpm"],
    },
    superfund: {
      filters: ["superfund"],
      threshold: "p80",
      state: "",
      focus: ["pnpl", "ptsdf"],
    },
  };

  const PRESETS = {
    "ca-pm25": {
      geoid: "06",
      state: "06",
      county: "",
      indicator: "pm25",
    },
    alameda: {
      geoid: "06001",
      state: "06",
      county: "06001",
      indicator: "d2_pm25",
    },
    "high-d2": {
      geoid: "",
      state: "",
      county: "",
      indicator: "d2_pm25",
      sortDesc: "d2_pm25",
      limit: 20,
    },
  };

  const CUTOFF_COLS = [
    "ptraf",
    "pnpl",
    "ptsdf",
    "pm25",
    "ozone",
    "dslpm",
    "peopcolorpct",
    "lowincpct",
    "d2_pm25",
    "d5_pm25",
  ];

  const els = {
    modeSimple: document.getElementById("mode-simple"),
    modeAdvanced: document.getElementById("mode-advanced"),
    panelSimple: document.getElementById("panel-simple"),
    panelAdvanced: document.getElementById("panel-advanced"),
    geoid: document.getElementById("geoid-prefix"),
    state: document.getElementById("state"),
    county: document.getElementById("county"),
    indicator: document.getElementById("indicator"),
    simpleState: document.getElementById("simple-state"),
    simpleThreshold: document.getElementById("simple-threshold"),
    justiceChecks: document.querySelectorAll('#justice-filters input[type="checkbox"]'),
    storyBtns: document.querySelectorAll("[data-story]"),
    presetBtns: document.querySelectorAll("[data-preset]"),
    run: document.getElementById("run"),
    status: document.getElementById("status"),
    empty: document.getElementById("empty"),
    table: document.getElementById("results"),
    thead: document.querySelector("#results thead"),
    tbody: document.querySelector("#results tbody"),
  };

  let rows = [];
  let mode = "simple";
  let activePreset = null;
  let activeStory = null;
  let sortDesc = null;
  let limit = null;
  let storyFocus = null;
  let cutoffsByLevel = { p75: {}, p80: {} };

  function aboveCutoff(value, cutoff) {
    if (value == null || cutoff == null || Number.isNaN(cutoff)) return false;
    return value >= cutoff;
  }

  function percentileCutoff(values, pct) {
    if (!values.length) return null;
    const sorted = values.slice().sort((a, b) => a - b);
    const rank = (pct / 100) * (sorted.length - 1);
    const lo = Math.floor(rank);
    const hi = Math.min(lo + 1, sorted.length - 1);
    const frac = rank - lo;
    return sorted[lo] * (1 - frac) + sorted[hi] * frac;
  }

  function buildCutoffs(dataRows) {
    const levels = { p75: {}, p80: {} };
    for (const col of CUTOFF_COLS) {
      const vals = [];
      for (const row of dataRows) {
        const v = row[col];
        if (v != null && typeof v === "number" && !Number.isNaN(v)) vals.push(v);
      }
      levels.p75[col] = percentileCutoff(vals, 75);
      levels.p80[col] = percentileCutoff(vals, 80);
    }
    return levels;
  }

  function fillIndicatorSelect() {
    for (const item of INDICATORS) {
      const opt = document.createElement("option");
      opt.value = item.value;
      opt.textContent = item.label;
      els.indicator.appendChild(opt);
    }
  }

  function fillStateSelect(selectEl, dataRows) {
    const seen = new Map();
    for (const r of dataRows) {
      if (!seen.has(r.state_fips)) {
        seen.set(r.state_fips, r.st_abbrev + " (" + r.state_fips + ")");
      }
    }
    const sorted = [...seen.entries()].sort((a, b) => a[0].localeCompare(b[0]));
    for (const [fips, label] of sorted) {
      const opt = document.createElement("option");
      opt.value = fips;
      opt.textContent = label;
      selectEl.appendChild(opt);
    }
  }

  function setStatus(text) {
    els.status.textContent = text;
  }

  function selectedJusticeKeys() {
    return [...els.justiceChecks]
      .filter((box) => box.checked)
      .map((box) => box.value);
  }

  function columnsForAdvanced(indicator) {
    if (!indicator) {
      return BASE_COLS.concat(INDICATORS.map((i) => i.value));
    }
    return BASE_COLS.concat([indicator]);
  }

  function columnsForSimple(keys) {
    const cols = BASE_COLS.slice();
    const seen = new Set(cols);
    const add = (col) => {
      if (!seen.has(col)) {
        seen.add(col);
        cols.push(col);
      }
    };
    if (storyFocus) {
      for (const col of storyFocus) add(col);
    }
    for (const key of keys) {
      const def = JUSTICE_FILTERS[key];
      if (!def) continue;
      for (const col of def.cols) add(col);
    }
    if (keys.length === 0 && !storyFocus) {
      for (const col of CUTOFF_COLS) add(col);
    }
    return cols;
  }

  function applyAdvancedFilters() {
    const geoid = (els.geoid.value || "").trim();
    const state = els.state.value;
    const county = (els.county.value || "").trim();
    const indicator = els.indicator.value;

    let out = rows.slice();
    if (geoid) {
      out = out.filter((r) => String(r.geoid).startsWith(geoid));
    }
    if (state) {
      out = out.filter((r) => r.state_fips === state);
    }
    if (county) {
      out = out.filter((r) => String(r.county_fips).startsWith(county));
    }
    if (sortDesc) {
      out.sort((a, b) => {
        const av = a[sortDesc];
        const bv = b[sortDesc];
        if (av == null && bv == null) return 0;
        if (av == null) return 1;
        if (bv == null) return -1;
        return bv - av;
      });
    }
    if (limit != null) {
      out = out.slice(0, limit);
    }
    return { rows: out, cols: columnsForAdvanced(indicator) };
  }

  function applySimpleFilters() {
    const keys = selectedJusticeKeys();
    const state = els.simpleState.value;
    const level = els.simpleThreshold.value || "p80";
    const cutoffs = cutoffsByLevel[level] || cutoffsByLevel.p80;

    let out = rows.slice();
    if (state) {
      out = out.filter((r) => r.state_fips === state);
    }
    if (keys.length) {
      out = out.filter((row) =>
        keys.every((key) => {
          const def = JUSTICE_FILTERS[key];
          return def ? def.match(row, cutoffs) : true;
        })
      );
    }
    return { rows: out, cols: columnsForSimple(keys), keys };
  }

  function formatCell(value) {
    if (value == null || value === "") return "";
    if (typeof value === "number" && !Number.isInteger(value)) {
      return String(Math.round(value * 1e6) / 1e6);
    }
    return String(value);
  }

  function renderTable(matched, cols) {
    els.thead.replaceChildren();
    els.tbody.replaceChildren();

    if (!matched.length) {
      els.table.hidden = true;
      els.empty.hidden = false;
      els.empty.textContent =
        mode === "simple"
          ? "No places in this sample matched those filters. Try fewer topics or a lower threshold."
          : "No rows matched these filters in the sample.";
      setStatus("0 rows");
      return;
    }

    els.empty.hidden = true;
    els.table.hidden = false;

    const trHead = document.createElement("tr");
    for (const col of cols) {
      const th = document.createElement("th");
      th.scope = "col";
      th.textContent = col.toUpperCase();
      trHead.appendChild(th);
    }
    els.thead.appendChild(trHead);

    const frag = document.createDocumentFragment();
    for (const row of matched) {
      const tr = document.createElement("tr");
      for (const col of cols) {
        const td = document.createElement("td");
        const val = row[col];
        if (typeof val === "number") td.className = "num";
        td.textContent = formatCell(val);
        tr.appendChild(td);
      }
      frag.appendChild(tr);
    }
    els.tbody.appendChild(frag);

    if (mode === "simple") {
      const keys = selectedJusticeKeys();
      const label =
        keys.length === 0
          ? matched.length + " of " + rows.length + " sample places (no topic filter)"
          : matched.length + " of " + rows.length + " sample places";
      setStatus(label);
    } else {
      setStatus(matched.length + " of " + rows.length + " sample rows");
    }
  }

  function render() {
    if (mode === "simple") {
      const { rows: matched, cols } = applySimpleFilters();
      renderTable(matched, cols);
    } else {
      const { rows: matched, cols } = applyAdvancedFilters();
      renderTable(matched, cols);
    }
  }

  function clearPresetHighlight() {
    activePreset = null;
    sortDesc = null;
    limit = null;
    els.presetBtns.forEach((btn) => btn.setAttribute("aria-pressed", "false"));
  }

  function clearStoryHighlight() {
    activeStory = null;
    storyFocus = null;
    els.storyBtns.forEach((btn) => btn.setAttribute("aria-pressed", "false"));
  }

  function setMode(next) {
    mode = next;
    const isSimple = mode === "simple";
    els.modeSimple.setAttribute("aria-pressed", isSimple ? "true" : "false");
    els.modeAdvanced.setAttribute("aria-pressed", isSimple ? "false" : "true");
    els.panelSimple.hidden = !isSimple;
    els.panelAdvanced.hidden = isSimple;
    els.run.textContent = isSimple ? "Show matching places" : "Run";
    if (isSimple) {
      clearPresetHighlight();
    } else {
      clearStoryHighlight();
    }
    render();
  }

  function applyPreset(name) {
    const preset = PRESETS[name];
    if (!preset) return;
    els.geoid.value = preset.geoid;
    els.state.value = preset.state;
    els.county.value = preset.county;
    els.indicator.value = preset.indicator;
    sortDesc = preset.sortDesc || null;
    limit = preset.limit || null;
    activePreset = name;
    els.presetBtns.forEach((btn) => {
      btn.setAttribute("aria-pressed", btn.dataset.preset === name ? "true" : "false");
    });
    render();
  }

  function applyStory(name) {
    const story = STORIES[name];
    if (!story) return;
    els.justiceChecks.forEach((box) => {
      box.checked = story.filters.includes(box.value);
    });
    els.simpleThreshold.value = story.threshold;
    els.simpleState.value = story.state;
    storyFocus = story.focus || null;
    activeStory = name;
    els.storyBtns.forEach((btn) => {
      btn.setAttribute("aria-pressed", btn.dataset.story === name ? "true" : "false");
    });
    render();
  }

  els.modeSimple.addEventListener("click", () => setMode("simple"));
  els.modeAdvanced.addEventListener("click", () => setMode("advanced"));

  els.run.addEventListener("click", () => {
    if (mode === "simple") clearStoryHighlight();
    else clearPresetHighlight();
    render();
  });

  els.storyBtns.forEach((btn) => {
    btn.addEventListener("click", () => applyStory(btn.dataset.story));
  });

  els.presetBtns.forEach((btn) => {
    btn.addEventListener("click", () => applyPreset(btn.dataset.preset));
  });

  els.justiceChecks.forEach((box) => {
    box.addEventListener("change", () => {
      if (activeStory) clearStoryHighlight();
    });
  });

  els.simpleState.addEventListener("change", () => {
    if (activeStory) clearStoryHighlight();
  });
  els.simpleThreshold.addEventListener("change", () => {
    if (activeStory) clearStoryHighlight();
  });

  ["geoid", "state", "county", "indicator"].forEach((key) => {
    els[key].addEventListener("change", () => {
      if (activePreset) clearPresetHighlight();
    });
  });

  document.getElementById("query-form").addEventListener("submit", (event) => {
    event.preventDefault();
    clearPresetHighlight();
    render();
  });

  fillIndicatorSelect();
  setStatus("Loading sample…");

  fetch("data/sample-block-groups.json")
    .then((res) => {
      if (!res.ok) throw new Error("Could not load sample extract");
      return res.json();
    })
    .then((payload) => {
      rows = payload.rows || [];
      cutoffsByLevel = buildCutoffs(rows);
      fillStateSelect(els.state, rows);
      fillStateSelect(els.simpleState, rows);
      setStatus(rows.length + " sample block groups ready");
      setMode("simple");
      applyStory("highways-lowinc");
    })
    .catch((err) => {
      setStatus(err.message || "Load failed");
      els.empty.textContent = "Sample extract failed to load.";
    });
})();
