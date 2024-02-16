(* type for symbol and parse tree *)
type ('nonterminal, 'terminal) symbol = 
  | N of 'nonterminal 
  | T of 'terminal
;;

type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal
;; 

(* problem 1 -- convert grammar *)

(* helper function for convert_grammar 
    - this returns a function that still needs a symbol arg
    - call the function with a nonterminal + it will return
      the list of rules associated with that nonterminal *)
let rec make_rules rules symbol =
  match rules with
    | [] -> []
    | (nt, r)::t -> 
        if (nt = symbol) then (r::(make_rules t symbol))
        else make_rules t symbol
;;

(* keep the start symbol + convert rules list to a function
    - second part of the tuple is a function bc we only give 1/2 args *)
let convert_grammar gram1 = 
  match gram1 with
    | (start, rules) -> (start, make_rules rules)
;;

(* problem 2 -- parse tree leaves *)

(* helper for parse_tree_leaves 
    - recurse on each of the sub tress + add leaves as we see them *)
let rec find_leaves tree leaves = 
  match tree with 
    | Node (nt, tree)::t -> (find_leaves tree leaves)@(find_leaves t leaves)
    | Leaf h::t -> h::(find_leaves t leaves)
    | [] -> leaves
;;

(* if first node is a leaf, then just return that singleton list 
   otherwise, run the helper function on the subtrees of the top node *)
let parse_tree_leaves tree = 
  match tree with
    | Node (nt, tree) -> find_leaves tree []
    | Leaf l -> [l]
;;

(* problem 3 -- make matcher *)

(* 
   - mutual recursion - two helper fxns that call each other
      - expand: 
          - expand non terminals to their associated rules
          - keeps track of where in the grammar we are (allows backtracking if a rule doesn't work)
          - parses through the list of rules + checks each one with find match
      - find_match:
          - checks ths current rule against the frag
          - if a nt is found, expand is called
          - calls acceptor when the current rule is exhausted
              - this return value signals to expand whether we found a match or if we need to 
                try the next rule
*)

let rec expand rule_fxn rules accept frag  = 
  match rules with 
    | [] -> None (* finished gram and unable to find a match *)
    | h::t -> 
        let return_val = (find_match rule_fxn h accept frag) in
        (* acceptor returns None on current rule -> try next rule *)
        if return_val = None then (expand rule_fxn t accept frag) 
        (* acceptor returns Some -> just return Some x *)
        else return_val

and find_match rule_fxn rule accept frag = 
  match rule with
    | [] -> accept frag (* finished rule -> call acceptor to check suffix *)
    | rule_h::rule_t -> match rule_h with
      (* if nt symbol -> expand the symbol and accept only if the rest of the rule matches as well *)
      | N symbol -> expand rule_fxn (rule_fxn symbol) (find_match rule_fxn rule_t accept) frag
      | T symbol -> match frag with
        | [] -> None (* frag is exhausted, but rule still contains symbols -> backtrack *)
        | frag_h::frag_t -> 
            if (frag_h = symbol) then (find_match rule_fxn rule_t accept frag_t)
            else None (* symbol does not match -> backtrack *)
;;

(* make matcher returns a FUNCTION -- using currying *)
let make_matcher gram = 
  match gram with
    | (start, rule_fxn) -> expand rule_fxn (rule_fxn start)
;;  

(* problem 4 -- make parser *)

(* 
  parsing through the grammar + frag is the same process as above
  but there are two changes:
    - acceptor needs to accept only [] 
    - need to keep track of the rules that are accepted
  
  generating the parse tree
    - nodes get added to the subtree list when a nt symbol is parsed in find_match
    - leaves get added to the subtree list when a t symbol is matched to frag
    - when the fragment is empty, pass in the full parse tree to the acceptor
      - trees look like: (Node (start, subtree list))
      - if accept, the acceptor returns the tree
  
  need to pass in subtree list to helper functions + update the current parse tree

*)

(* this acceptor also returns an optional tree *)
let parse_acceptor frag parse_tree =
  match frag with
    | [] -> Some parse_tree
    | _ -> None
;;

(* almost exactly the same as the make_matcher function 
   except we need to pass in the tree as an arg so that it can get updated as we parse *)
let rec parse_expand start rule_fxn rules accept subtree frag = 
  match rules with 
    | [] -> None
    | h::t -> 
        let return_val = (parse_find_match start rule_fxn h accept frag subtree) in
        if return_val = None then (parse_expand start rule_fxn t accept subtree frag)
        else return_val

(* again, almost exactly the same, but needed to change some parts to update the parse tree
    - keep track the the rules that are picked *)
and parse_find_match start rule_fxn rule accept frag subtree = 
  match rule with
    | [] -> accept frag (Node (start, subtree)) (* pass in the generated parse tree to acceptor *)
    | rule_h::rule_t -> match rule_h with
      (* if nt -> build the parse tree for the nt's subtree + append it to the tree we have so far *)
      | N symbol -> 
        let accept_tail frag_arg tree_arg = parse_find_match start rule_fxn rule_t accept frag_arg (subtree @ [tree_arg]) in
        parse_expand symbol rule_fxn (rule_fxn symbol) (accept_tail) [] frag 
      | T symbol -> match frag with
        | [] -> None 
        | frag_h::frag_t -> 
            (* append the leaf to the tree we have so far *)
            if (frag_h = symbol) then (parse_find_match start rule_fxn rule_t accept frag_t (subtree @ [Leaf symbol]))
            else None
;;

(* this returns a function waiting for a frag argument *)
let make_parser gram = 
  match gram with
    | (start, rule_fxn) -> parse_expand start rule_fxn (rule_fxn start) parse_acceptor []
;;