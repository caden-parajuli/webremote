(lang dune 3.20)
(using ctypes 0.3)

(name webremote)

(generate_opam_files true)

(source (github caden-parajuli/webremote))

(authors "Caden Parajuli <caden.parajuli@gmail.com>")
(maintainers "Caden Parajuli <caden.parajuli@gmail.com>")

(package
 (name webremote)
 (synopsis "A web-based remote for your HTPC")
 (depends
   (ocaml (= 5.3.0))

   (dream (= 1.0.0~alpha8))
   (tyxml (>= 4.6.0))
   (ctypes (>= 0.23.0))
   ctypes-foreign
   yojson-five
   directories

   utop
   ))
