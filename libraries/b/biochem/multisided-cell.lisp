;;;; This file is part of little b.

;;;; The MIT License

;;;; Copyright (c) 2003-2008 Aneil Mallavarapu

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


;;; File: b/biochem/multisided-cell

;;; Description: 
;;;
;;; $Id: multisided-cell.lisp,v 1.9 2008/09/06 00:23:08 amallavarapu Exp $
;;;
(in-package #I@FILE)
(include-declaration :use-packages (mallavar-utility))
(include @</dimensionalization :use)
(include (@>/util
          @>/biochem 
          @</membrane-apposition) :expose)

(defcon multisided-cell (location)
  ; basic lattice component
  (&optional
   (id := *name*)
   &property
   (inner compartment  :#= [COMPARTMENT])
   (membranes :#=  [DICTIONARY])
   (membrane-interfaces :#= [DICTIONARY])))

(defmethod location-class-dimensionality ((x (eql multisided-cell)))
  (1- *compartment-dimensionality*))

(defcon location-interface (:notrace location)
  "a relationship between two locations which can be used as a location in reactions which take place across their superlocation"
  ((loc1 location)
   (loc2 location)
   &property
   (size := [[reference-var] :value 1 ]))     ; cross-sectional size of the interface
  (b-assert (not (eq loc1 loc2)))
  (b-assert (typep .loc1 (type-of .loc2)) () "Interfaced locations are of different types (~S ~S)" .loc1 .loc2))


(defmethod location-class-dimensionality ((x (eql location-interface)))
  (1- (1- *compartment-dimensionality*)))

(defield multisided-cell.define-closed-membrane (&rest name-size-pairs)
  (warn "Using function (b/biochem/multisided-cell::multisided-cell.define-closed-membrane) which may not be fully debugged - use with caution - check your results.")
;  (let ((inner .inner))
    (loop for (name size) in name-size-pairs
;          for m-prev = nil then m
          for m = (.add-membrane name size)
          ;for li = nil then (.define-membrane-interface m-prev m)
          finally (.define-membrane-interface m .membranes.,(first (first name-size-pairs))))
    .membranes)
  

;;;; (defun not-nil-or-? (&rest args)
;;;;   (notany (lambda (x) (or (not x) (eq x ?))) args))

(defield multisided-cell.define-membrane-interface (m1i m2i &optional (interface-size 1)) ;; hash keys, not objects...
  (let ((o object) ) 
    {object.(membrane-interface m2i m1i) :#           
            {.membrane-interfaces.,(cons m2i m1i) :=
                  [[location-interface o.membranes.,m2i o.membranes.,m1i] :size interface-size]}}

    {object.(membrane-interface m1i m2i) :#           
            {.membrane-interfaces.,(cons m1i m2i) :=
                  [[location-interface (fld o.membranes m1i) (fld o.membranes m2i)] :size interface-size]}}))

(defield multisided-cell.membrane-interface (m1i m2i)
  .membrane-interfaces.,(cons m1i m2i))


(defield multisided-cell.contains (rt)
  object.inner.(contains rt))


;;;
;;; MEMBRANE functionality:
;;;
(defield multisided-cell.add-membrane (name length )
  (let ((cell object))
    {object.membranes.,name :#= [[membrane] :inner cell.inner {.size.value := length}]}))

(defield multisided-cell.in-all-apposed-membranes (stype &optional (X ?.moles))
  "Retrieves the total X of a species type in all the apposed membranes of a cell. Where X = .moles by default."
  (loop with total = (quantity 0 *molecular-amount-dimension*)
        for m being the hash-values of .membranes._hash-table
        for apposition = m.apposition
        for sp = (if apposition stype.(in apposition.m2))
        when sp
        do (setf total (s+ total (funcall x sp)))
        finally (return total)))

(defield multisided-cell.in-all-membranes (stype &optional (X ?.moles))
  "Retrieves the total X of stype in all the membranes of a cell. Where X = .moles by default."
  (loop with total = (quantity 0 *molecular-amount-dimension*)
        for m being the hash-values of .membranes._hash-table
        for sp = stype.(in m)
        when sp
        do (setf total (s+ total (funcall x sp)))
        finally (return total)))

(defield multisided-cell.all-membranes-size ()
  (apply #'s+ (do-dictionary (m .membranes t)
                m.size)))

(defield multisided-cell.all-apposed-membranes-size ()
  (apply #'s+ (do-dictionary (m .membranes t)
                m.size)))
