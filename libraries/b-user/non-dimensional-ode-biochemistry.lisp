(in-package #I@FILE)

(include @folder/ode-biochem :expose)

(include-documentation
  :description "Loads definitions for modelling biochemical systems as ODEs of unitless variables.")

(b-warn "B-USER/NON-DIMENSIONAL-ODE-BIOCHEMISTRY is deprecated; use B-USER/ODE-BIOCHEM instead.")
