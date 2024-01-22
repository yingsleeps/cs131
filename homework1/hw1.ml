(* problem 1 -- using List.mem to check if elem is in the list *)
let rec subset a b = match a with
  | [] -> true
  | h::t -> List.mem h b && subset t b
;;

(* problem 2 -- two sets are eq iff they are subsets of each other *)
let equal_sets a b = 
  subset a b && subset b a
;;

(* problem 3 -- can ignore duplicates *)
let set_union a b =
  a @ b
;;

(* problem 4 *)
let set_all_union a =
  List.concat a
;;

(* problem 5 *)

(* problem 6 *)
(* let rec computed_fixed_point eq f x =
  let value = f x in 
  if eq x value then x
  else computed_fixed_point eq f value
;; *)

let rec computed_fixed_point eq f x = 
  let value = f x in
  match eq x value with
    | true -> x
    | false -> computed_fixed_point eq f value
;;

(* problem 7 *)
(* helper to compute f^p(x) for initial value x + period p *)
let rec computed_period f p x = 
  match p with
    | 0 -> x
    | 1 -> f x
    | _ -> f (computed_period f (p - 1) x)
;;

let rec computed_periodic_point eq f p x = 
  match 
;;

(* problem 8 *)
let rec whileseq s p x = 
  let condition = p x in
  match condition with
    | false -> []
    | true -> x::(whileseq s p (s x))
;;

(* problem 9 *)
