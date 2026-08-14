// @ts-check
import { defineConfig } from "astro/config";
import mermaid from "astro-mermaid";

import tailwindcss from "@tailwindcss/vite";

import icon from "astro-icon";

// https://astro.build/config
export default defineConfig({
    vite: {
        plugins: [tailwindcss()],
    },
    integrations: [mermaid({
        theme: "base",
        autoTheme: true,
    }), icon()],
});