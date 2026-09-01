// Thin shim: the loader globs `plugins/*.ts` at the top level, while the
// shield-bash implementation lives in ./shield-bash/ as a self-contained unit.
export { ShieldBash } from "./shield-bash/plugin"
