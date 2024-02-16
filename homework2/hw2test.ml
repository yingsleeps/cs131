let accept_nothing = function
   | _::_ -> None
   | x -> Some x
   
type td_nonterminals =
  | Comp | Traits | Two_td | Four_td | Sentinel | Executioner | Rapidfire | Guardian

let true_damage_grammar = (Comp,
  function 
    | Comp -> [ [N Two_td]; [N Four_td] ]
    | Two_td -> [ [N Traits; N Traits] ]
    | Four_td -> [ [N Traits; N Traits; N Traits; N Traits] ]
    | Traits -> [ [N Sentinel]; [N Executioner]; [N Rapidfire]; [N Guardian] ]
    | Sentinel -> [[T "ekko"]]
    | Executioner -> [[T "akali"]]
    | Rapidfire -> [[T "senna"]]
    | Guardian -> [[T "kennen"]]
)

let make_matcher_test =
  ((make_matcher true_damage_grammar accept_nothing ["akali"; "ekko"; "senna";]) = None )



let make_parser_test =
  match make_parser true_damage_grammar ["akali"; "ekko"; "senna"; "kennen"] with
    | Some tree -> parse_tree_leaves tree = ["akali"; "ekko"; "senna"; "kennen"]
    | _ -> false


