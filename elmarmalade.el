;;; elmarmalade.el --- the marmalade repository in emacs-lisp

;; Copyright (C) 2012  Nic Ferrier

;; Author: Nic Ferrier <nferrier@ferrier.me.uk>
;; Package-Requires: ((dotassoc "0.0.1")(mongo-elnode "0.0.3"))
;; Keywords: hypermedia, lisp, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; marmalade-repo.org is an Emacs package repository originally by
;; Nathan Wiezenbaum in node.js.

;; This is a rewrite of marmalade-repo in Emacs-Lisp using Elnode.

;;; Code:

(require 'cl)
(require 'elnode)
(require 'mongo-elnode)
(require 'dotassoc)

(defvar elmarmalade--packages-db
  (elnode-db-make
   '(mongo
     :host "localhost"
     :collection "marmalade.packages"))
  "The Mongo packages database.")

(defun elmarmalade--package-record (data)
  "Produce a package record from a marmalade db record.

DATA is a marmalade db record.  An example is in
`testrecord.json'."
  (let ((name (dotassoc "_name" data))
        ;; this could be _latestVersion.version but that's a vector?
        (version (coerce (dotassoc "_latestVersion.version" data) 'list))
        (type (dotassoc "_latestVersion.type" data))
        (desc (dotassoc "_latestVersion.description" data)))
    (when (and name version type desc)
      (cons (intern name) `[,version nil ,desc ,(intern type)]))))

(defun elmarmalade--package-list ()
  "Make a list of everything in the package list."
  (let ((package-list
         (elnode-db-map
          'elmarmalade--package-record
          elmarmalade--packages-db)))
    package-list))

(defun elmarmalade-package-archives (httpcon)
  "Produce the archive for Emacs package.el."
  (let ((package-list
         (elmarmalade--package-list)))
    (elnode-http-start httpcon 200)
    (elnode-http-return httpcon (format "%S" package-list))))

(defun elmarmalade-package (httpcon)
  "Show a single package from marmalade."
  ;; FIXME
  ;;
  ;; elnode-docroot-for needs adapting to do mongo querys
  ;;
  ;; but also the asynchrony needs managing in this instance so the
  ;; whole thing runs async?
  (elnode-docroot-for "mongo-db-query"
      with package-name
      on httpcon
      do
      (display-package)))

(defun elmarmalade-handler (httpcon)
  "The top level handler for marmalade."
  (elnode-hostpath-dispatcher
   httpcon
   '(("^.*//packages/archive-contents" . elmarmalade-package-archives)
     ("^.*//package/\\(.*\\)" . elmarmalade-package))))

(provide 'elmarmalade)

;;; elmarmalade.el ends here
