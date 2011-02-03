:- module(rdf_test,
	  [ (+)/1,			% Assert
	    (-)/1,			% Retract
	    v/1,			% Visible
	    u/1,			% InVisible
	    l/0,			% List
	    r/0,			% reset
	    {}/1,			% transaction
	    a/0				% Run all tests
	  ]).
:- use_module(rdf_db).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Create a test-language.  Actions:

    + A:{S,P,O},		Add named triple
    - A:{S,P,O},		Remove named triple
    v A,
    {...}
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

:- meta_predicate
	true(0),
	false(0),
	{}(0).

:- thread_local
	triple/2.

+ Name^{S,P,O} :- !,
	mk_spo(S,P,O),
	rdf_assert(S,P,O),
	(   var(Name)
	->  Name = rdf(S,P,O)
	;   assert(triple(Name, rdf(S,P,O)))
	).
+ {S,P,O} :-
	mk_spo(S,P,O),
	rdf_assert(S,P,O).

mk_spo(S,P,O) :-
	mk(s, S),
	mk(p, P),
	mk(o, O).

mk(_, R) :- atom(R), !.
mk(Prefix, R) :-
	gensym(Prefix, R).

- Name^{S,P,O} :- !,
	rdf_retractall(S,P,O),
	(   var(Name)
	->  Name = rdf(S,P,O)
	;   assert(triple(Name, rdf(S,P,O)))
	).
- {S,P,O} :- !,
	rdf_retractall(S,P,O).
- rdf(S,P,O) :- !,
	rdf_retractall(S,P,O).
- Name :-
	ground(Name),
	triple(Name, Triple),
	v(Triple).

v(rdf(S,P,O)) :- !,
	true((rdf(S,P,O))),
	true((rdf(S,P,O2), O == O2)),
	true((rdf(S,P2,O), P == P2)),
	true((rdf(S,P2,O2), P == P2, O == O2)),
	true((rdf(S2,P,O), S2 == S)),
	true((rdf(S2,P,O2), S2 == S, O == O2)),
	true((rdf(S2,P2,O), S2 == S, P == P2)),
	true((rdf(S2,P2,O2), S2 == S, P == P2, O == O2)).
v(Name) :-
	ground(Name),
	triple(Name, Triple),
	v(Triple).

u(rdf(S,P,O)) :- !,
	false((rdf(S,P,O))).
u(Name) :-
	ground(Name),
	triple(Name, Triple),
	u(Triple).


true(G) :-
	G, !.
true(G) :-
	format(user_error, 'FALSE: ~q~n', [G]),
	backtrace(5),
	throw(test_failed).

false(G) :-
	G, !,
	format(user_error, 'TRUE: ~q~n', [G]),
	backtrace(5),
	throw(test_failed).
false(_).

{}(G) :-
	rdf_transaction(G).


r :-
	retractall(triple(_,_)),
	rdf_reset_db.

l :-
	forall(rdf(S,P,O),
	       format('{~q, ~q, ~q}~n', [S,P,O])).


db(RDF) :-
	findall(rdf(S,P,O), rdf(S,P,O), RDF0),
	sort(RDF0, RDF).

		 /*******************************
		 *	       TESTS		*
		 *******************************/

:- op(1000, fx, test).

:- discontiguous (test)/1.

term_expansion((test Head :- Body),
	       [ test(Head),
		 (Head :- Body)
	       ]).

test t1 :-
	r,
	(  { + a^{_},
	     fail
	   }
	;  true
	),
	u(a).
test t2 :-
	r,
	{ + a^{_},
	  u(a),
	  { v(a)
	  }
	},
	v(a).
test t3 :-
	r,
	{ + a^{_},
	  u(a),
	  { v(a),
	    + b^{_},
	    u(b),
	    { v(b)
	    }
	  }
	},
	v(a).
test t4 :-
	r,
	+ a^{_},
	{ v(a)
	}.
test t5 :-
	r,
	+ a^{_},
	{ - a,
	  v(a)
	}.
test t6 :-
	r,
	+ a^{_},
	{ - a,
	  v(a),
	  { u(a)
	  }
	}.
test t7 :-
	r,
	+ a^{_},
	(   { - a,
	      v(a),
	      { u(a)
	      },
	      fail
	    }
	;   true
	),
	v(a).


:- dynamic
	passed/1.

a :-
	retractall(passed(_)),
	forall(test(Head),
	       run(Head)),
	aggregate_all(count, passed(_), Count),
	format('~D tests passed~n', [Count]).


run(Head) :-
	catch(Head, E, true), !,
	(   var(E)
	->  assert(passed(Head))
	;   format(user_error, 'TEST FAILED: ~q~n', [Head])
	).
run(Head) :-
	format(user_error, 'TEST FAILED: ~q~n', [Head]).
