// ==========================
//  avatar-changer-isaac API
// ==========================

const express = require("express");
const bodyParser = require("body-parser");
const fs = require("fs");
const path = require("path");

const app = express();
app.use(bodyParser.json());

// ==========================
//  CONFIG
// ==========================

const DB_PATH = path.join(__dirname, "db.json");

// API KEY dari user
const API_KEY = process.env.API_KEY || "gopalasuFreeAva";

// ==========================
//  LOAD DATABASE
// ==========================

let db = { mappings: {} };

if (fs.existsSync(DB_PATH)) {
    try {
        db = JSON.parse(fs.readFileSync(DB_PATH, "utf8"));
        console.log("DB loaded");
    } catch (e) {
        console.error("DB load error:", e);
    }
}

function saveDb() {
    fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2));
}

// ==========================
//  AUTH
// ==========================

function auth(req, res, next) {
    const key = req.header("x-api-key") || req.query.key;
    if (key !== API_KEY) {
        return res.status(401).json({ error: "invalid_api_key" });
    }
    next();
}

// ==========================
//  SUBMIT MAPPING
// ==========================

app.post("/submit", auth, (req, res) => {
    const { code, data } = req.body;

    if (!code || !data) {
        return res.status(400).json({ error: "missing code or data" });
    }

    const upperCode = String(code).toUpperCase();
    db.mappings[upperCode] = data;

    saveDb();

    return res.json({ ok: true, saved: upperCode });
});

// ==========================
//  RESOLVE MAPPING
// ==========================

app.get("/resolve/:code", (req, res) => {
    const code = String(req.params.code).toUpperCase();

    if (!db.mappings[code]) {
        return res.status(404).json({ error: "not_found" });
    }

    return res.json({
        ok: true,
        code,
        mapping: db.mappings[code]
    });
});

// ==========================
//  LIST
// ==========================

app.get("/list", (req, res) => {
    return res.json({
        ok: true,
        codes: Object.keys(db.mappings)
    });
});

// ==========================
//  START
// ==========================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log("avatar-changer-isaac API running on port " + PORT);
});
