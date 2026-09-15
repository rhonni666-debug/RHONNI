import { defineConfig } from "vite";
import { tanstackStart } from "@tanstack/react-start/plugin/vite";
import viteReact from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import tsconfigPaths from "vite-tsconfig-paths";

const staticPreview = process.env.STATIC_PREVIEW === "true";

export default defineConfig({
  base: staticPreview ? "/RHONNI/" : "/",
  plugins: [
    tsconfigPaths(),
    tailwindcss(),
    tanstackStart({
      spa: { enabled: staticPreview },
    }),
    viteReact(),
  ],
});
