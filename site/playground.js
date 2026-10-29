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

  const els = {
    geoid: document.getElementById("geoid-prefix"),
    state: document.getElementById("state"),
    county: document.getElementById("county"),
    indicator: document.getElementById("indicator"),
    run: document.getElementById("run"),
    status: document.getElementById("status"),
    empty: document.getElementById("empty"),
    table: document.getElementById("results"),
    thead: document.querySelector("#results thead"),
    tbody: document.querySelector("#results tbody"),
    presets: document.querySelectorAll(".preset"),
  };

  let rows = [];
  let activePreset = null;
  let sortDesc = null;
  let limit = null;

  function fillIndicatorSelect() {
    for (const item of INDICATORS) {
      const opt = document.createElement("option");
      opt.value = item.value;
      opt.textContent = item.label;
      els.indicator.appendChild(opt);
    }
  }

  function fillStateSelect(dataRows) {
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
      els.state.appendChild(opt);
    }
  }

  function setStatus(text) {
    els.status.textContent = text;
  }

  function columnsFor(indicator) {
    if (!indicator) {
      return BASE_COLS.concat(INDICATORS.map((i) => i.value));
    }
    return BASE_COLS.concat([indicator]);
  }

  function applyFilters() {
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
    return { rows: out, cols: columnsFor(indicator), indicator };
  }

  function formatCell(value) {
    if (value == null || value === "") return "";
    if (typeof value === "number" && !Number.isInteger(value)) {
      return String(Math.round(value * 1e6) / 1e6);
    }
    return String(value);
  }

  function render() {
    const { rows: matched, cols } = applyFilters();
    els.thead.replaceChildren();
    els.tbody.replaceChildren();

    if (!matched.length) {
      els.table.hidden = true;
      els.empty.hidden = false;
      els.empty.textContent = "No rows matched these filters in the sample.";
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
    setStatus(matched.length + " of " + rows.length + " sample rows");
  }

  function clearPresetHighlight() {
    activePreset = null;
    sortDesc = null;
    limit = null;
    els.presets.forEach((btn) => btn.setAttribute("aria-pressed", "false"));
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
    els.presets.forEach((btn) => {
      btn.setAttribute("aria-pressed", btn.dataset.preset === name ? "true" : "false");
    });
    render();
  }

  els.run.addEventListener("click", () => {
    clearPresetHighlight();
    render();
  });

  els.presets.forEach((btn) => {
    btn.addEventListener("click", () => applyPreset(btn.dataset.preset));
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
      fillStateSelect(rows);
      setStatus(rows.length + " sample block groups ready");
      applyPreset("ca-pm25");
    })
    .catch((err) => {
      setStatus(err.message || "Load failed");
      els.empty.textContent = "Sample extract failed to load.";
    });
})();
