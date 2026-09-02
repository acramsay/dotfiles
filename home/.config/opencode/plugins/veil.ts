// Thin shim: the loader globs `plugins/*.ts` at the top level, while the
// veil implementation lives in ./veil/ as a self-contained unit.
export { Veil } from "./veil/plugin"
