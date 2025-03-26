import json from "/usr/lib/node_modules/@eslint/json/dist/esm/index.js";

export default [
    {
        plugins: {
            json,
        },
    },

    // lint JSON files
    {
        files: [
            "**/*.json"
        ],
        ignores: [
            ".mypy_cache/*.json",
        ],
        language: "json/json",
        rules: {
            "json/no-duplicate-keys": "error",
        },
    },
];
