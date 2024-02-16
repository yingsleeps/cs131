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

(* problem 4 -- flatten the list list with concat *)
let set_all_union a =
  List.concat a
;;

(* problem 5 
   It is not possible to write the `self_member s` function in ocaml, with the way types work in ocaml. In order
   to implement the function, we need to check if set s contains itself. For set s, which has type 'a list (since
   we are representing sets with lists), to be a member of itself, s would also need to be of type 'a list list (to be
   able to conatin an 'a list), which is a contradiction.
*)

(* problem 6 *)
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
  if eq x (computed_period f p x) then x
  else computed_periodic_point eq f p (f x)
;;

(* problem 8 *)
let rec whileseq s p x = 
  let condition = p x in
  match condition with
    | false -> []
    | true -> x::(whileseq s p (s x))
;;

(* problem 9 *)
type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal
;;

(* create + maintain a list of symbols that are eventually terminable
   -> either is all terminal symbols or will reach all terminable symbols *)

(* `all_terminable` holds the eventually terminable symbols we've found so far *)

(* check if the symbol is terminal or eventually terminable *)
let is_terminable symbol all_terminable =
  match symbol with
    | N _ -> List.mem symbol all_terminable 
    | T _ -> true
;;

(* check if the rule is eventually terminable *)
let rec is_rule_terminable rule all_terminable =
  match rule with
    | [] -> true
    | h::t -> (is_terminable h all_terminable) && (is_rule_terminable t all_terminable)
;;

(* build the list of eventually terminable symbols 
   -> returns all_terminable list *)
let rec find_terminable_symbols rules all_terminable =
  match rules with
    | [] -> all_terminable
    | h::t -> 
        if is_rule_terminable (snd h) all_terminable then find_terminable_symbols t ((N (fst h))::all_terminable)
        else find_terminable_symbols t all_terminable
;;

(* wrapper, in order to make the result of `find_terminable_symbols` a tuple *)
let wrapper (rules, all_terminable) =
  (rules, find_terminable_symbols rules all_terminable)
;;

(* equality predicate for terminable symbols list + rules tuple *)
let equal (r, a) (r, b) = 
  if equal_sets a b then true
  else false
;;

(* keep checking rules until no more rules to check 
   -- use fixed points to keep checking rules until all terminable symbols are found 
   -- returns (rules, all_terminable) tuple *)
let rec build_all_terminable rules all_terminable =
  computed_fixed_point (equal) (wrapper) (rules, all_terminable) 
;;

(* remove all the non-terminating rules 
   -- returns list of rules with the blind alley rules removed *)
let rec removal rules all_terminable =
  match rules with
    | [] -> rules 
    | h::t -> 
        if is_rule_terminable (snd h) all_terminable then h::(removal t all_terminable)
        else removal t all_terminable
;;

(* filter the blind alleys by building the list of all terminable rules + then removing the non-terminable ones *)
let filter_blind_alleys g =
  match g with
    | (start, []) -> g
    | (start, rules) -> (start, (removal rules (snd (build_all_terminable rules []))))
;;