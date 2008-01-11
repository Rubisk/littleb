;;;; This file is part of little b.

;;;; The MIT License

;;;; Copyright (c) 2007 Aneil Mallavarapu

;;;; Permission is hereby granted, free of charge, to any person obtaining a copy
;;;; of this software and associated documentation files (the "Software"), to deal
;;;; in the Software without restriction, including without limitation the rights
;;;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;;;; copies of the Software, and to permit persons to whom the Software is
;;;; furnished to do so, subject to the following conditions:

;;;; The above copyright notice and this permission notice shall be included in
;;;; all copies or substantial portions of the Software.

;;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;;;; THE SOFTWARE.


(in-package :portable)


#+:clisp
(progn
(ffi:default-foreign-language :stdc )

(ffi:def-call-out sh-get-special-folder-location
    (:arguments (hwnd ffi:long)
		(nfolder ffi:long)
		(ppidl (ffi:c-ptr ffi:c-pointer) :out))
  (:return-type ffi:long)
  (:name "SHGetSpecialFolderLocation")
  (:library "Shell32.dll"))

(ffi:def-call-out sh-get-path-from-id-list
    (:arguments (pidl ffi:c-pointer)
                ;; we'll pre-allocate a 2048 buffer -
                ;; FFI will return the truncated results:
		(str (ffi:c-ptr (ffi:c-array ffi:character 2048)) :out :alloca)) 
  (:return-type ffi:long)
  (:name "SHGetPathFromIDList")
  (:library "Shell32"))

(defun get-win32-special-folder-location (n)
  (multiple-value-bind (x ptr) 
      (sh-get-special-folder-location 0 n) 
    (declare (ignorable x))
    (multiple-value-bind (retval str) 
	(sh-get-path-from-id-list ptr)
      (declare (ignorable retval))
      (prog1 str
        (ffi:foreign-free ptr)))))
)

(defvar *win32-folder-ids*
  '((:desktop 0)
    (:start-menu-programs 2)
    (:my-documents 5)
    (:favorites 6)
    (:start-menu-programs-startup 7)
    (:recent 8)
    (:sendto 9)
    (:start-menu 11)
    (:my-music 13)
    (:my-videos 14)
    (:desktop 16)
    (:nethood 19)
    (:fonts 20)
    (:templates 21)
    (:all-users-start-menu 22)
    (:all-users-start-menu-programs 23)
    (:all-users-start-menu-startup 24)
    (:all-users-desktop 25)
    (:appdata 26)
    (:printhood 27)
    (:local-settings-application data 28)
    (:all-users-favorites 31)
    (:local-settings-temporary-internet-files 32)
    (:cookies 33)
    (:local-settings-history 34)
    (:all-users-application-data 35)
    (:windows 36)
    (:system32 37)
    (:program-files 38)
    (:my-pictures 39)
    (:user 40)
    (:system32 41)
    (:program-files-common-files 43)
    (:all-users-templates 45)
    (:all-users-documents 46)
    (:all-users-start-menu-administrative tools 47)
    (:start-menu-administrative tools 48)
    (:all-users-my-music 53)
    (:all-users-my-pictures 54)
    (:all-users-my-videos 55)
    (:resources 56)
    (:cd-burning 59)))


(defun get-windows-pathname (folder-id &optional str args)
  (let ((num   (second (assoc folder-id *win32-folder-ids*))))
    (assert num (folder-id)
      "Invalid argument to ~S: ~S is not one of ~S"
      'get-windows-named-folder 
      folder-id
      (mapcar #'car *win32-folder-ids*))
    
    (let ((path #+:lispworks (second (multiple-value-list 
                                      (win32::sh-get-folder-path 0 num 0 0)))
                #+:clisp     (get-win32-special-folder-location num)
                #-(or :clisp :lispworks)
                              (substitute #\\  #\/ 
                                          (format nil "~AMy Documents/"
                                                  (user-homedir-pathname)))))
    (pathname (format nil "~A\\~?"
                      (string-right-trim '#.(list (code-char 0) #\/ #\\)
                                         path)
                      str args)))))