; formatting
(setq-default
 gnus-summary-line-format "%U%R%z %(%&user-date;  %-15,15f  %B%s%)\n"
 gnus-user-date-format-alist '((t . "%Y-%m-%d %H:%M"))
 gnus-summary-thread-gathering-function 'gnus-gather-threads-by-references
 gnus-thread-sort-functions '(gnus-thread-sort-by-date)
 gnus-sum-thread-tree-false-root ""
 gnus-sum-thread-tree-indent " "
 gnus-sum-thread-tree-leaf-with-other "├► "
 gnus-sum-thread-tree-root ""
 gnus-sum-thread-tree-single-leaf "╰► "
 gnus-sum-thread-tree-vertical "│"
)

(setq gnus-topic-line-format "%i[ %u&topic-line; ] %v\n")
    
; this corresponds to a topic line format of "%n %A"
(defun gnus-user-format-function-topic-line (dummy)
  (let ((topic-face (if (zerop total-number-of-articles)
                        'my-gnus-topic-empty-face
                        'my-gnus-topic-face)))
    (propertize
     (format "%s %d" name total-number-of-articles)
     'face topic-face)))

; hashcash !!!
(require 'hashcash)
(setq message-generate-hashcash t)
(setq hashcash-default-payment 26)

; gpg stuff
;(load-library "mailcrypt")
;(mc-setversion "gpg")
;(autoload 'mc-install-write-mode "mailcrypt" nil t)
;(autoload 'mc-install-read-mode "mailcrypt" nil t)
;(add-hook 'gnus-summary-mode-hook 'mc-install-read-mode)
;(add-hook 'message-mode-hook 'mc-install-write-mode)
;;(add-hook 'mail-mode-hook 'mc-install-write-mode)
;(add-hook 'news-reply-mode-hook 'mc-install-write-mode)
;; If you have more than one key, specify the one to use
;(setq mc-gpg-user-id "Aaron Toponce <aaron.toponce@gmail.com>") ; where `address' is preferentially put between < and >
;; Always sign encrypted messages
;(setq mc-pgp-always-sign t)
;; How long should mailcrypt remember your passphrase
;(setq mc-passwd-timeout 600)
;; Automagically sign all messages
;(add-hook 'message-send-hook 'will-you-sign)
;(defun will-you-sign ()
;        (load-library "mc-toplev")
;       (interactive)
;        (if (y-or-n-p "Do you want to sign this message? ")
;                (mc-sign-message)))
;(add-hook 'gnus-summary-mode-hook 'mc-install-read-mode)
;(add-hook 'message-mode-hook 'mc-install-write-mode)
;(add-hook 'news-reply-mode-hook 'mc-install-write-mode)

; encrypted .authinfo
(require 'epa-file)
;(epa-file-enable)
(setq epa-file-cache-passphrase-for-symmetric-encryption t)

(require 'auth-source)
(setq auth-sources '((:source "~/.authinfo.gpg" :host t :port t)))

(setq user-mail-address "aaron.toponce@gmail.com"
      user-full-name "Aaron Toponce"
;      smtpmail-smtp-server "smtp.gmail.com"
;      smtpmail-auth-credentials (expand-file-name "~/.authinfo.gpg")
)

; default imap account
(setq gnus-select-method
      '(nnimap "gmail"
	   ;(nnimap-authinfo-file "~/.authinfo.gpg")
           (nnimap-address "imap.gmail.com")
           (nnimap-server-port 993)
           (nnimap-stream ssl)))

; additional imap accounts
(setq gnus-secondary-select-methods
      '((nnimap "xmission"
                ;(nnimap-authinfo-file "~/.authinfo.gpg")
                (nnimap-address "zimbra.xmission.com")
                (nnimap-server-port 993)
                (nnimap-stream ssl))
        (nnimap "utah"
                ;(nnimap-authinfo-file "~/.authinfo.gpg")
                (nnimap-address "imap.umail.utah.edu")
                (nnimap-server-port 993)
                (nnimap-stream ssl))))

; let gnus change the "From:" based on the current group we're in
(setq gnus-posting-styles
      '(("*"
	 (header "OpenPGP" "id=8086060F; url=http://ae7.st/s/pgp; preference=signencrypt")
	 (header "Crypto-Challenge" "iVBORw0KGgoAAAANSUhEUgAAAFwAAABcAQMAAADZIUAbAAAABlBMVEX///8AAABVwtN+AAAAS0lEQVQ4jbXSUQoAIAhEwYXuf2NhS1O6QM+EnH4qUfoaK2bBcJysnUUVWYlGput3JGxPD1H00byAQ17r20YW8QaChXr2UHgiUHyNDSRgxkgDsThDAAAAAElFTkSuQmCC")
	 (header "Crypto-Hint" "image/png")
	 )
	("gmail"
	 (address "aaron.toponce@gmail.com")
	 (signature-file "~/src/dotfiles/.signature.gmail"))
	("xmission"
	 (address "atoponce@xmission.com")
	 (signature-file "~/src/dotfiles/.signature.xmission"))
	("utah"
	 (address "aaron.toponce@utah.edu")
	 (signature-file "~/src/dotfiles/.signature.utah"))))

; available smtp accounts
(defvar smtp-accounts
  '(
    (ssl "aaron.toponce@gmail.com" "smtp.gmail.com" 25 "aaron.toponce@gmail.com" nil)
    (ssl "atoponce@xmission.com" "zimbra.xmission.com" 25 "atoponce@xmission.com" nil)
    (ssl "aaron.toponce@utah.edu" "smtp.utah.edu" 25 "u0708330@smtp.utah.edu" nil)))

; Default smtpmail.el configurations.
(require 'cl)
(require 'smtpmail)
(setq send-mail-function 'smtpmail-send-it
      message-send-mail-function 'smtpmail-send-it
      mail-from-style nil
      user-full-name "Aaron Toponce"
      smtpmail-debug-info t
      smtpmail-debug-verb t)

(defun set-smtp (mech server port user password)
  "Set related SMTP variables for supplied parameters."
  (setq smtpmail-smtp-server server
        smtpmail-smtp-service port
        smtpmail-auth-credentials (list (list server port user password))
        smtpmail-auth-supported (list mech)
        smtpmail-starttls-credentials nil)
  (message "Setting SMTP server to `%s:%s' for user `%s'."
           server port user))

(defun set-smtp-ssl (server port user password  &optional key cert)
  "Set related SMTP and SSL variables for supplied parameters."
  (setq starttls-use-gnutls t
        starttls-gnutls-program "gnutls-cli"
        starttls-extra-arguments nil
        smtpmail-smtp-server server
        smtpmail-smtp-service port
        smtpmail-auth-credentials (list (list server port user password))
        smtpmail-starttls-credentials (list (list server port key cert)))
  (message
   "Setting SMTP server to `%s:%s' for user `%s'. (SSL enabled.)"
   server port user))

(defun change-smtp ()
  "Change the SMTP server according to the current from line."
  (save-excursion
    (loop with from = (save-restriction
                        (message-narrow-to-headers)
                        (message-fetch-field "from"))
          for (auth-mech address . auth-spec) in smtp-accounts
          when (string-match address from)
          do (cond
              ((memq auth-mech '(cram-md5 plain login))
               (return (apply 'set-smtp (cons auth-mech auth-spec))))
              ((eql auth-mech 'ssl)
               (return (apply 'set-smtp-ssl auth-spec)))
              (t (error "Unrecognized SMTP auth. mechanism: `%s'." auth-mech)))
          finally (error "Cannot infer SMTP information."))))

(defadvice smtpmail-via-smtp
  (before change-smtp-by-message-from-field (recipient buffer &optional ask) activate)
  (with-current-buffer buffer (change-smtp)))

(ad-activate 'smtpmail-via-smtp)

; choose plain text when possible
(setq mm-discouraged-alternatives '("text/html" "text/richtext"))
(setq gnus-ignored-newsgroups "^to\\.\\|^[0-9. ]+\\( \\|$\\)\\|^[\"]\"[#'()]")
