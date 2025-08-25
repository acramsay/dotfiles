(require (prefix-in helix. "helix/commands.scm"))
(require (prefix-in helix.static. "helix/static.scm"))
(require "helix/configuration.scm")
(require "helix/editor.scm")

(provide languages-open themes)

;;@doc
;;Open the languages.toml file
(define (languages-open)
  (helix.open "~/.config/helix/languages.toml"))

(define (themes)
  (themes->list))
