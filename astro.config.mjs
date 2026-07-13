// @ts-check
import { defineConfig } from "astro/config";
import mermaid from "astro-mermaid";

import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
    vite: {
        plugins: [tailwindcss()],
    },
    integrations: [
        mermaid({
            theme: "base",
            autoTheme: true,
            // mermaidConfig: {
            //     themeVariables: {
            //         primaryColor: "#111827",
            //         primaryTextColor: "#f9fafb",
            //         lineColor: "#6b7280",
            //         fontFamily: "Inter, ui-sans-serif, system-ui",
            //     },
            // },
        }),
    ],
});
