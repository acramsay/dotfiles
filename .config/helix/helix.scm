(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/configuration.scm")
(require "helix/editor.scm")
(require "helix-file-watcher/file-watcher.scm")

(provide languages-open W)

;;@doc
;;Write without formatting (:w --no-format)
(define (W)
  (helix.write "--no-format"))

;;@doc
;;Open the languages.toml file
(define (languages-open)
  (helix.open "~/.config/helix/languages.toml"))

(spawn-watcher)
