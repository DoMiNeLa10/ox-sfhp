;;; ox-sfhp.el - export from org-mode to a single file HTML presentation
;;; -*- coding: utf-8 -*-

;; Author: DoMiNeLa10 (https://github.com/DoMiNeLa10)

;;; license: GPLv3 or newer

;; This program is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <http://www.gnu.org/licenses/>.

;;; Dependencies:
(require 'ox)
;; this exporter can use web-mode if it's installed to indent documents

;;; Variables and constants:

;;; Constants with code
(defconst org-sfhp-style-common
  "<style type=\"text/css\">
 /* common style, no colors should go in here */
 body {
   margin: 0;
   font-family: sans, arial, helvetica;
 }
 #slides {
   width: 100%;
   height: 100%;
   top: 0;
 }
 #slides div {
   margin-top: 1em;
   margin-bottom: 5em;
   width: 100%;
   text-align: center;
   position: relative;
 }
 h1 {
   text-align: center;
   margin-top: 0;
 }
 dl, p, blockquote {
   text-align: left;
   text-indent: 1em;
   margin: 0.5em 2em;
 }
 .continuation {
   text-indent: 0;
 }
 blockquote:before {
   content: \"“\";
 }
 blockquote:after {
   content: \"”\";
 }
 pre, .monospace {
   padding: 0.4em;
   border-radius: 0.2em; /* CSS 3 */
   text-align: left;
 }
 .monospace {
   white-space: pre-line;
   font-family: monospace;
   line-height: 2;
 }
 hr {
   width: 95%;
   height: 2px;
   border: 0;
 }
 pre {
   margin: 0.5em 2em;
   word-wrap: break-word; /* CSS 3 and IE 5.5+ */
   white-space: pre-wrap;
 }
 dt {
   font-weight: bold;
 }
 dt:after { /* CSS 2.1 syntax should be more compatible */
   content: \":\";
 }
 table {
   margin: 1em auto;
 }
 td {
   padding: 0.3em 1em;
   border-width: 1px;
   border-style: solid;
   text-align: center;
 }
 tr:first-of-type td { /* CSS 3 */
   border-bottom-width: 3px;
   border-style: double;
 }
 ol, ul {
   text-align: left;
   margin: 0.5em 2em;
   padding-left: 2.5em;
 }
 ol *, ul * {
   margin: 0;
 }
 ol ol, ol ul, ul ol, ul ul {
   padding-left: 1.5em;
 }
 #buttons {
   position: fixed;
   height: 4em;
   width: 100%;
   bottom: 0;
   opacity: 0.5; /* CSS 3 */
   filter: alpha(opacity=50); /* old versions of IE */
   text-align: center;
 }
 #counter {
   position: absolute;
   margin-top: 0.25em;
   width: 30%;
   left: 35%;
   font-size: x-large;
 }
 button {
   outline: none; /* don't show that buttons are focused */
   height: 100%;
   width: 3em;
   margin: 0;
   border: none;
   font-size: xx-large;
 }
 #left {
   float: left;
 }
 #right{
   float: right;
 }
 img {
   max-width: 90%;
   margin: 1em;
 }
</style>\n"
  "Common style for ox-sfhp")

(defvar org-sfhp-color-themes
  '(("dark" . "<style type=\"text/css\">
/* dark style */
body {
  background-color: #222;
  color: #AAA;
}
pre, .monospace {
  background-color: #333;
  color: #BBB;
}
hr {
  background-color: #AAA;
}
td {
  border-color: #AAA;
}
button {
  background-color: #444;
  color: #AAA;
}
.disabled {
  background-color: #111;
}
#buttons {
  background-color: #333;
}
</style>\n")
    ("light" . "<style type=\"text/css\">
/* light style */
body {
  background-color: #EEE;
  color: #111;
}
pre, .monospace {
  color: #000;
  background-color: #FFF;
}
hr {
  background-color: #111;
}
td {
  border-color: #000;
}
#counter {
  color: #000;
}
button {
  background-color: #AAA;
  color: #000;
}
.disabled {
  background-color: #333;
}
#buttons {
  background-color: #BBB;
}
</style>\n"))
  "Color themes for ox-sfhp.")

(defconst org-sfhp-style-hack-oldie
  "<!--[if lt IE 7]>
  <style type=\"text/css\">
  #buttons {
    position: absolute !important;
  }
  div {
    posititon: absolute;
  }
  </style>
<![endif]-->\n"
  "A hack that fixes this presentation in old versions of
  Internet Explorer that don't support position: fixed;")

(defconst org-sfhp-style-hack-polish-quotes
  "<style type=\"text/css\">
 /* polish quotes */
 blockquote:before {
   content: \"„\" !important;
 }
 blockquote:after {
   content: \"”\" !important;
 }
</style>\n"
  "A hack that overrides quotes with polish quotation marks")

(defconst org-sfhp-script
  "<script type=\"text/javascript\">
 /* @licstart The following is the entire license notice for the JavaScript
    code in this page.

    Copyright (C) 2016 DoMiNeLa10

    The JavaScript code in this page is free software: you can redistribute
    it and/or modify it under the terms of the GNU General Public License
    (GNU GPL) as published by the Free Software Foundation, either version 3
    of the License, or (at your option) any later version. The code is
    distributed WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU GPL for
    more details.

    As additional permission under GNU GPL version 3 section 7, you may
    distribute non-source (e.g., minimized or compacted) forms of that code
    without the copy of the GNU GPL normally required by section 4, provided
    you include this license notice and a URL through which recipients can
    access the Corresponding Source.

    @licend The above is the entire license notice for the JavaScript code
    in this page. */
 var currentSlide = 1, totalSlides, left, right, counter;
 /* change value of currentSlide to open up the presentation on that slide */
 /* revert to 1 later */
 function init () { /* init function to be run onload */
   totalSlides = document.getElementById(\"slides\").children.length;
   for (i = 1; i <= totalSlides; i++) /* hide all slides */
     hideSlide(i);
   showSlide(currentSlide);
   /* add buttons (they won't work without JavaScript anyway) */
   document.body.innerHTML += '<div id=\"buttons\"><div id=\"counter\"></div><button id=\"left\" title=\"previous slide\" onclick=\"previousSlide();\">&lt;</button><button id=\"right\" title=\"next slide\" autofocus=\"autofocus\" onclick=\"nextSlide();\">&gt;</button></div>';
   left = document.getElementById(\"left\");
   right = document.getElementById(\"right\");
   counter = document.getElementById(\"counter\");
   update();
 }
 function getSlide (n) {
   return document.getElementById(\"slide\" + n);
 }
 function showSlide (n) {
   getSlide(n).style.display = \"block\";
 }
 function hideSlide (n) {
   getSlide(n).style.display = \"none\";
 }
 function previousSlide () {
   if (currentSlide > 1) {
     hideSlide(currentSlide);
     showSlide(--currentSlide);
     update();
   }
 }
 function nextSlide () {
   if (currentSlide < totalSlides) {
     hideSlide(currentSlide);
     showSlide(++currentSlide);
     update();
   }
 }
 function update () { /* update the counter and \"disable\" buttons */
   if (currentSlide <= 1)
     left.className = \"disabled\"; /* classList doesn't work in IE 5 */
   else
     left.className = \"\";
   if (currentSlide >= totalSlides)
     right.className = \"disabled\";
   else
     right.className = \"\";
   counter.innerHTML = currentSlide + \"/\" + totalSlides;
 }
 function getKey(event) { /* bind keys to changing slides */
   switch(event.which){
     case 80: /* p */
     case 66: /* b */
     case 72: /* h */
     case 75: /* k */
     case 37: /* left arrow */
       previousSlide();
       break;
     case 70: /* f */
     case 78: /* n */
     case 74: /* j */
     case 76: /* l */
     case 39: /* right arrow */
       nextSlide();
       break;
   }
 }
 document.onkeydown = getKey;
</script>\n"
  "JavaScript code for one at a time display in ox-sfhp output")

(defconst org-sfhp-meta
  "<meta charset=\"utf-8\" />
<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />
<meta name=\"generator\" content=\"Org-mode + ox-sfhp.el\" />\n"
  "Meta tags for ox-sfhp.")

;;; Other constants
(defconst org-sfhp-extension
  "-sfhp.html"
  "Extension for files from ox-sfhp.")

(defconst org-sfhp-protected-characters
  '(("&" . "&amp;")                  ;order here is important, & should be first
    ("<" . "&lt;")
    (">" . "&gt;"))
  "List of protected HTML characters and how they should be escaped.")

(defconst org-sfhp-tags
  '((bold . "b")
    (italic . "i")
    (underline . "u")
    (strike-through . "s")
    (superscript . "sup")
    (subscript . "sub")
    (quote-block . "blockquote"))
  "List of HTML tags. Used by ox-sfhp.")

(defconst org-sfhp-list-types
  '((ordered . "ol")
    (unordered . "ul")
    (descriptive . "dl"))
  "List of types of lists and tags that contain them. Used by ox-sfhp.")

(defconst org-sfhp-special-paragraphs
  '(item quote-block)
  "List of paragraph parent elements that should be treated differently.")

(defconst org-sfhp-mime-types
  '(("png" . "image/png")
    ("jpg" . "image/jpeg")
    ("jpeg" . "image/jpeg")
    ("webp" . "image/webp")
    ("bmp" . "image/bmp")
    ("gif" . "image/gif"))
  "List of image file types and their MIME types.")

;;; Variables
(defvar org-sfhp-color-theme "dark"     ;change this value later or something
  "Color theme for ox-sfhp export. Can be light, dark or CSS code
with a custom color theme.")

(defvar org-sfhp-indent-output (fboundp 'web-mode)
  "When non-nil, ox-sfhp's output is indented. Indenting
shouldn't be done when `web-mode' isn't installed, because it can
break source code blocks and other things.")

(defvar org-sfhp-include-oldie-hacks t
  "When non-nil, inlude a CSS hack for old versions of Internet
Explorer in ox-sfhp output.")

;; backend
(org-export-define-backend 'sfhp
  '((bold . org-sfhp-wrap-in-tag)
    (italic . org-sfhp-wrap-in-tag)
    (underline . org-sfhp-wrap-in-tag)
    (verbatim . org-sfhp-monospace)
    (strike-through . org-sfhp-wrap-in-tag)
    (subscript . org-sfhp-wrap-in-tag)
    (superscript . org-sfhp-wrap-in-tag)
    (code . org-sfhp-monospace)
    (example-block . org-sfhp-monospace-block)
    (headline . org-sfhp-headline)
    (horizontal-rule . org-sfhp-horizontal-rule)
    (line-break . org-sfhp-line-break)
    (link . org-sfhp-link)
    (paragraph . org-sfhp-paragraph)
    (src-block . org-sfhp-src-block)
    (plain-list . org-sfhp-plain-list)
    (item . org-sfhp-item)
    (quote-block . org-sfhp-wrap-in-tag)
    (section . org-sfhp-section)
    (table . org-sfhp-table)
    (table-cell . org-sfhp-table-cell)
    (table-row . org-sfhp-table-row)
    (template . org-sfhp-template)
    (plain-text . org-sfhp-escape-html-chars))
  :export-block "SFHP"
  :filters-alist '((:filter-final-output . org-sfhp-final-filter))
  :menu-entry
  '(?p "Export to a single file HTML presentation"
       ((?b "As a buffer" org-sfhp-export-to-buffer)
        (?f "As a file" org-sfhp-export-to-file)
        (?o "As a file and open" org-sfhp-export-to-file-and-open)))
  :options-alist
  '((:sfhp-theme "SFHP_THEME" nil org-sfhp-color-theme space)))

;;; wrapping functions (or whatever)
(defun org-sfhp-wrap-in-tag (type contents info)
  "Wraps contents in a HTML tag. Used by ox-sfhp."
  (let ((tag (cdr (assoc (car type) org-sfhp-tags))))
    (if tag
        (format "<%s>%s</%s>" tag contents tag)
      contents)))

(defun org-sfhp-monospace (type contents info)
  "Returns HTML with inline monospace text."
  (format "<span class=\"monospace\">%s</span>"
          (org-sfhp-escape-html-chars (org-element-property :value type))))

(defun org-sfhp-monospace-block (type contents info)
  "Returns HTML with monospace block."
  (let* ((escaped-contents (org-sfhp-escape-html-chars
                            (org-element-property :value type)))
         (trimmed-contents (substring escaped-contents 0
                                      (1- (length escaped-contents)))))
    (format "<pre>%s</pre>" trimmed-contents)))

;; horizontal rule and line break
(defun org-sfhp-horizontal-rule (type contents info)
  "Return a horizontal rule."
  "<hr/>\n")

(defun org-sfhp-line-break (type contents info)
  "Return a HTML line break."
  "<br/>\n")

;; paragraph
(defun org-sfhp-paragraph (type contents info)
  "Return a HTML paragraph."
  (if (member (org-element-type (org-export-get-parent type))
              org-sfhp-special-paragraphs)
      contents
    (format "<p>\n%s</p>" contents)))

;; section
(defun org-sfhp-section (type contents info)
  "Return a org-mode seciton."
  (when (org-export-get-parent-headline type) ;ignore sections ouside headlines
    contents))

;; lists
(defun org-sfhp-plain-list (type contents info)
  "Returns the outer tags of a HTML list."
  (let ((tag (or
              (cdr (assoc (org-element-property :type type)
                          org-sfhp-list-types))
              "ul")))
    (format "<%s>\n%s</%s>" tag contents tag)))

(defun org-sfhp-item (type contents info)
  "Returns item from a list in HTML tags within appropriate tags."
  (if (eq
       (org-element-property :type
                             (org-export-get-parent type))
       'descriptive)                    ;when a list is descriptive
      (format "<dt>%s</dt>\n<dd>\n%s</dd>"
              (car (org-element-property :tag type)) ;returns a list, so I car it
              contents)
    (format "<li>\n%s</li>" contents)))

;; table
(defun org-sfhp-table (type contents info)
  "Return contents as a HTML table."
  (format "<table>\n%s</table>" contents))

(defun org-sfhp-table-row (type contents info)
  "Return a HTML table row."
  (when (eq (org-element-property :type type) 'standard) ;ignore separators
    (format "<tr>%s\n</tr>" contents)))

(defun org-sfhp-table-cell (type contents info)
  "Return a HTML table cell."
  (format "\n<td>%s</td>" contents)) ;newlines at the end get removed for some reason

;; headline
(defun org-sfhp-headline (type contents info)
  "Return a headline."
  (let ((headline-number (car (org-export-get-headline-number type info)))
        (headline-level (org-export-get-relative-level type info))
        (headline-title (org-sfhp-escape-html-chars
                         (car (org-element-property :title type)))))
    (if (= headline-level 1)
        (format "<div id=\"slide%d\">\n<h1>%s</h1>\n%s</div>"
                headline-number headline-title contents)
      (when (> headline-level 6)
        (setq headline-level 6))
      (format "<h%d>%s</h%d>\n%s"
              headline-level headline-title headline-level contents))))

;; src block
(defun org-sfhp-src-block (type contents info)
  "Returns a source code block as HTML code."
  (let* ((code (org-sfhp-escape-html-chars
                (car (org-export-unravel-code type))))
         (trimmed-code (substring code 0 (1- (length code)))))
    (format "<pre>%s</pre>" trimmed-code)))

;; link
(defun org-sfhp-link (type contents info)
  "Returns an image encoded as base64, a link to a website or
just text from the link. Used by ox-sfhp. Alt text for image can
be supressed by using \"decoration\" as the link description."
  (let* ((linked-type (org-element-property :type type))
         (file-path (org-element-property :path type))
         (raw-link (org-element-property :raw-link type))
         (file-extension (file-name-extension file-path))
         (file-mime-type
          (when (stringp file-extension)
            (cdr (assoc
                  (downcase file-extension) ;sometimes file extension is upper case
                  org-sfhp-mime-types)))))
    (cond (file-mime-type               ;known image format
           (let ((in-paragraphp (eq 'paragraph (car (org-export-get-parent type)))))
             (format "%s<img src=\"data:%s;base64,%s\" alt=\"%s\" />%s"
                     (if in-paragraphp
                         "</p>\n"
                       "")
                     file-mime-type
                     (with-temp-buffer
                       (insert-file-contents-literally file-path)
                       (base64-encode-region (point-min) (point-max) t)
                       (buffer-string))
                     (cond ((not contents) "Undescribed picture")
                           ((string-equal contents "decoration") "")
                           (t contents))
                     (if in-paragraphp
                         "\n<p class=\"continuation\">"
                       ""))))
          ((member linked-type '("http" "https")) ;link to a website
           (format "<a href=\"%s\">%s</a>"
                   raw-link (if contents
                                contents
                              raw-link))) ;fall back when there's no link text
          (t contents))))          ;just insert link text otherwise


;; template

(defun org-sfhp-template (contents info)
  "Returns the outer template of the HTML document."
  (let ((language (plist-get info :language))
        (title (org-export-data (plist-get info :title) info))
        (theme (plist-get info :sfhp-theme)))
    (concat "<!DOCTYPE html>\n"
            (format "<html%s>\n"
                    (if language
                        (format " lang=\"%s\"" language)
                      ""))
            "<head>\n"

            ;; title
            (format "<title>%s</title>\n"
                    (if (eq title "") ; title of a HTML document shouldn't be empty
                        "Untitled presentation"
                      title))
            ;; common code
            org-sfhp-meta
            org-sfhp-script
            org-sfhp-style-common

            ;; color theme
            (or (cdr (assoc theme org-sfhp-color-themes))
                (format "<style type=\"text/css\">\n%s\n</style>\n"
                        theme))         ;include the custom color theme

            ;;; CSS hacks
            (if org-sfhp-include-oldie-hacks
                org-sfhp-style-hack-oldie
              "")
            ;; polish quotes
            (if (string-equal language "pl")
                org-sfhp-style-hack-polish-quotes
              "")

            "</head>\n"
            "<body onload=\"init();\">\n"
            "<div id=\"slides\">\n"
            contents
            "</div>\n</body>\n</html>")))

;; plain text
;; this function is pretty much like org-html-encode-plain-text in ox-html
(defun org-sfhp-escape-html-chars (text &optional info)
  "Escapes characters used by HTML. Used by ox-sfhp."
  (mapc (lambda (pair)
          (setq text (replace-regexp-in-string (car pair) (cdr pair) text t t)))
        org-sfhp-protected-characters)
  text)

;;; export functions

(defun org-sfhp-export-to-buffer
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a single file HTML presentation buffer."
  (interactive)
  (org-export-to-buffer 'sfhp "*Org SFHP Export*"
    async subtreep visible-only body-only ext-plist
    (lambda () (if (fboundp 'web-mode)
                   (web-mode)
                 (set-auto-mode t)))))

(defun org-sfhp-export-to-file
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a single file HTML presentation file."
  (interactive)
  (org-export-to-file 'sfhp (org-export-output-file-name org-sfhp-extension)
    async subtreep visible-only body-only ext-plist))

(defun org-sfhp-export-to-file-and-open
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a single file HTML presentation file
and open it."
  (interactive)
  (org-open-file (org-sfhp-export-to-file
                  async subtreep visible-only body-only ext-plist)))


;;; filters

(defun org-sfhp-final-filter (contents backend info)
  "A final filter for ox-sfhp."
  (setq contents                        ;remove empty paragraphs
        (replace-regexp-in-string
         "<p\\( class=\"continuation\"\\)?>[ \n]*</p>" "" contents))
  (if org-sfhp-indent-output
      (org-sfhp-indent-filter contents backend info)
    contents))

(defun org-sfhp-indent-filter (contents backend info)
  "Intent filter for ox-sfhp."
  (with-temp-buffer
    (insert contents)
    (if (fboundp 'web-mode) ;web-mode is better at indenting multi-language HTML files
        (web-mode)
      (set-auto-mode t))
    (indent-region (point-min) (point-max))
    (buffer-substring-no-properties (point-min) (point-max))))
