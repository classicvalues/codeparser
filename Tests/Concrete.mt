
Needs["AST`"]


(*
PatternColon and OptionalColon
*)
Test[
	ConcreteParseString["a:b"]
	,
	ContainerNode[String, {
		BinaryNode[Pattern, {
			LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>], 
  			LeafNode[Token`Colon, ":", <|Source -> {{1, 2}, {1, 3}}|>], 
  			LeafNode[Symbol, "b", <|Source -> {{1, 3}, {1, 4}}|>]}, <|Source -> {{1, 1}, {1, 4}}|>] }, <||>]
	,
	TestID->"Concrete-20190521-U1K7U2"
]

Test[
	ConcreteParseString["a_:b"]
	,
	ContainerNode[String, {
		BinaryNode[Optional, {
			PatternBlankNode[PatternBlank, {
				LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
				LeafNode[Blank, "_", <|Source -> {{1, 2}, {1, 3}}|>]}, <|Source -> {{1, 1}, {1, 3}}|>],
			LeafNode[Token`Colon, ":", <|Source -> {{1, 3}, {1, 4}}|>],
			LeafNode[Symbol, "b", <|Source -> {{1, 4}, {1, 5}}|>]}, <|Source -> {{1, 1}, {1, 5}}|>] }, <||>]
	,
	TestID->"Concrete-20190521-V6P9B0"
]









(*
make sure that both InternalNullNodes have correct Sources (and not the same ones)
*)
Test[
	ConcreteParseString["a; ;"]
	,
	ContainerNode[String, {
		InfixNode[CompoundExpression, {
			LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`Semi, ";", <|Source -> {{1, 2}, {1, 3}}|>],
			LeafNode[Token`Fake`ImplicitNull, "", <|Source -> {{1, 3}, {1, 3}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 3}, {1, 4}}|>],
			LeafNode[Token`Semi, ";", <|Source -> {{1, 4}, {1, 5}}|>],
			LeafNode[Token`Fake`ImplicitNull, "", <|Source -> {{1, 5}, {1, 5}}|>]}, <|Source -> {{1, 1}, {1, 5}}|>] }, <||>]
	,
	TestID->"Concrete-20190117-C3R5P5"
]












Test[
	ConcreteParseString["?a"]
	,
	(*
	StringNode[String, {
		StartOfLineNode[Information, {
			LeafNode[Token`Question, "?", <|Source -> {{1, 1}, {1, 1}}|>],
			LeafNode[String, "a", <|Source -> {{1, 2}, {1, 2}}|>]}, <|Source -> {{1, 1}, {1, 2}}|>] }, <||>]
	*)
	ContainerNode[String, {
		BinaryNode[PatternTest, {
			LeafNode[Token`Error`ExpectedOperand, "", <|Source -> {{1, 1}, {1, 1}}|>],
			LeafNode[Token`Question, "?", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Symbol, "a", <|Source -> {{1, 2}, {1, 3}}|>]}, <|Source -> {{1, 1}, {1, 3}}|>]}, <||>]
	,
	TestID->"Concrete-20190601-B0Y1X6"
]



Test[
	ConcreteParseString["{\n?a}"]
	,
	ContainerNode[String, {
		GroupNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`Newline, "\n", <|Source -> {{2, 0}, {2, 1}}|>],
			BinaryNode[PatternTest, {
				LeafNode[Token`Error`ExpectedOperand, "", <|Source -> {{2, 1}, {2, 1}}|>],
				LeafNode[Token`Question, "?", <|Source -> {{2, 1}, {2, 2}}|>],
				LeafNode[Symbol, "a", <|Source -> {{2, 2}, {2, 3}}|>]}, <|Source -> {{2, 1}, {2, 3}}|>],
			LeafNode[Token`CloseCurly, "}", <|Source -> {{2, 3}, {2, 4}}|>]}, <|Source -> {{1, 1}, {2, 4}}|>] }, <||>]
	,
	TestID->"Concrete-20190601-H6L1N7"
]






(*
line continuations and newlines
*)
Test[
	ConcreteParseString["\"abc\\\r\ndef\""]
	,
	ContainerNode[String, {
		LeafNode[String, "\"abc\\\r\ndef\"", <|Source -> {{1, 1}, {2, 5}}|>] }, <||>]
	,
	TestID->"Concrete-20190606-U7J9I3"
]







Test[
	ConcreteParseString[""]
	,
	ContainerNode[String, {}, <||>]
	,
	TestID->"Concrete-20190227-H6C1K7"
]






(* Syntax Errors *)

Test[
	ConcreteParseString["a ~f x", f]
	,
	f[{{
		InfixNode[Times, {
			SyntaxErrorNode[SyntaxError`ExpectedTilde, {
				LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
				LeafNode[Whitespace, " ", <|Source -> {{1, 2}, {1, 3}}|>],
				LeafNode[Token`Tilde, "~", <|Source -> {{1, 3}, {1, 4}}|>],
				LeafNode[Symbol, "f", <|Source -> {{1, 4}, {1, 5}}|>] }, <|Source -> {{1, 1}, {1, 5}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 5}, {1, 6}}|>],
			LeafNode[Token`Fake`ImplicitTimes, "", <|Source -> {{1, 6}, {1, 6}}|>],
			LeafNode[Symbol, "x", <|Source -> {{1, 6}, {1, 7}}|>]}, <|Source -> {{1, 1}, {1, 7}}|>]}, {}}]
	,
	TestID->"Concrete-20190521-L2C2Y8"
]










TestMatch[
	ConcreteParseString["f[1,\\[InvisibleComma]2]"]
	,
	ContainerNode[String, {
		CallNode[{ LeafNode[Symbol, "f", <|Source->{{1, 1}, {1, 2}}|>] }, {
			GroupNode[GroupSquare, {
				LeafNode[Token`OpenSquare, "[", <|Source->{{1, 2}, {1, 3}}|>],
				InfixNode[Comma, {
					LeafNode[Integer, "1", <|Source->{{1, 3}, {1, 4}}|>],
					LeafNode[Token`Comma, ",", <|Source->{{1, 4}, {1, 5}}|>],
					LeafNode[Token`Fake`ImplicitNull, "", <|Source->{{1, 5}, {1, 5}}|>],
					LeafNode[Token`LongName`InvisibleComma, "\\[InvisibleComma]", <|Source->{{1, 5}, {1, 22}}|>],
					LeafNode[Integer, "2", <|Source->{{1, 22}, {1, 23}}|>]}, <|Source->{{1, 3}, {1, 23}}|>],
				LeafNode[Token`CloseSquare, "]", <|Source -> {{1, 23}, {1, 24}}|>] }, <|Source -> {{1, 2}, {1, 24}}|>] }, <|Source -> {{1, 1}, {1, 24}}|>] }, _]
	,
	TestID->"Concrete-20190704-F8G9M5"
]





Test[
	ConcreteParseString["f[b : c]"]
	,
	ContainerNode[String, {
			CallNode[{LeafNode[Symbol, "f", <|Source -> {{1, 1}, {1, 2}}|>]}, {
			GroupNode[GroupSquare, {
				LeafNode[Token`OpenSquare, "[", <|Source -> {{1, 2}, {1, 3}}|>],
				BinaryNode[Pattern, {
					LeafNode[Symbol, "b", <|Source -> {{1, 3}, {1, 4}}|>],
					LeafNode[Whitespace, " ", <|Source -> {{1, 4}, {1, 5}}|>],
					LeafNode[Token`Colon, ":", <|Source -> {{1, 5}, {1, 6}}|>],
					LeafNode[Whitespace, " ", <|Source -> {{1, 6}, {1, 7}}|>],
					LeafNode[Symbol, "c", <|Source -> {{1, 7}, {1, 8}}|>]}, <|Source -> {{1, 3}, {1, 8}}|>],
				LeafNode[Token`CloseSquare, "]", <|Source -> {{1, 8}, {1, 9}}|>]}, <|Source -> {{1, 2}, {1, 9}}|>]}, <|Source -> {{1, 1}, {1, 9}}|>] }, <||>]
	,
	TestID->"Concrete-20190709-P9A0T8"
]







Test[
	ConcreteParseString["{ ( a }"]
	,
	ContainerNode[String, {
		GroupNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 2}, {1, 3}}|>],
			GroupMissingCloserNode[GroupParen, {
				LeafNode[Token`OpenParen, "(", <|Source -> {{1, 3}, {1, 4}}|>],
				LeafNode[Whitespace, " ", <|Source -> {{1, 4}, {1, 5}}|>],
				LeafNode[Symbol, "a", <|Source -> {{1, 5}, {1, 6}}|>]}, <|Source -> {{1, 3}, {1, 6}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 6}, {1, 7}}|>],
			LeafNode[Token`CloseCurly, "}", <|Source -> {{1, 7}, {1, 8}}|>]}, <|Source -> {{1, 1}, {1, 8}}|>] }, <||>]
	,
	TestID->"Concrete-20190717-L0P2V0"
]

Test[
	ConcreteParseString["{ a ) }"]
	,
	ContainerNode[String, {
		GroupMissingCloserNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 2}, {1, 3}}|>],
			LeafNode[Symbol, "a", <|Source -> {{1, 3}, {1, 4}}|>]}, <|Source -> {{1, 1}, {1, 4}}|>],
		LeafNode[Whitespace, " ", <|Source -> {{1, 4}, {1, 5}}|>],
		SyntaxErrorNode[SyntaxError`UnexpectedCloser, {
			LeafNode[Token`CloseParen, ")", <|Source -> {{1, 5}, {1, 6}}|>]}, <|Source -> {{1, 5}, {1, 6}}|>],
		LeafNode[Whitespace, " ", <|Source -> {{1, 6}, {1, 7}}|>],
		SyntaxErrorNode[SyntaxError`UnexpectedCloser, {
			LeafNode[Token`CloseCurly, "}", <|Source -> {{1, 7}, {1, 8}}|>]}, <|Source -> {{1, 7}, {1, 8}}|>]}, <||>]
	,
	TestID->"Concrete-20190717-N8D4U4"
]






TestMatch[
	ConcreteParseString[";;(**);;"]
	,
	ContainerNode[String, {
		InfixNode[Times, {
			BinaryNode[Span, {
				LeafNode[Token`Fake`ImplicitOne, "", <|Source -> {{1, 1}, {1, 1}}|>],
				LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 1}, {1, 3}}|>],
				LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 3}, {1, 3}}|>]}, <|Source -> {{1, 1}, {1, 3}}|>],
			LeafNode[Token`Comment, "(**)", <|Source -> {{1, 3}, {1, 7}}|>],
			LeafNode[Token`Fake`ImplicitTimes, "", <|Source -> {{1, 7}, {1, 7}}|>],
			BinaryNode[Span, {
				LeafNode[Token`Fake`ImplicitOne, "", <|Source -> {{1, 7}, {1, 7}}|>],
				LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 7}, {1, 9}}|>],
				LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 9}, {1, 9}}|>]}, <|Source -> {{1, 7}, {1, 9}}|>]}, <|Source -> {{1, 1}, {1, 9}}|>] }, _]
	,
	TestID->"Concrete-20190914-Z5W3U0"
]

TestMatch[
	ConcreteParseString["a;;b;;(**)&"]
	,
	ContainerNode[String, {
		PostfixNode[Function, {
			InfixNode[Times, {
				BinaryNode[Span, {
					LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>], 
			     	LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 2}, {1, 4}}|>], 
			     	LeafNode[Symbol, "b", <|Source -> {{1, 4}, {1, 5}}|>]}, <|Source -> {{1, 1}, {1, 5}}|>],
	      		LeafNode[Token`Fake`ImplicitTimes, "", <|Source -> {{1, 5}, {1, 5}}|>], 
	      		BinaryNode[Span, {LeafNode[Token`Fake`ImplicitOne, "", <|Source -> {{1, 5}, {1, 5}}|>], 
	      			LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 5}, {1, 7}}|>], 
	      			LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 7}, {1, 7}}|>]}, <|Source -> {{1, 5}, {1, 7}}|>]}, <|Source -> {{1, 1}, {1, 7}}|>], 
	  		LeafNode[Token`Comment, "(**)", <|Source -> {{1, 7}, {1, 11}}|>],
	  		LeafNode[Token`Amp, "&", <|Source -> {{1, 11}, {1, 12}}|>]}, <|Source -> {{1, 1}, {1, 12}}|>] }, _]
	,
	TestID->"Concrete-20190914-U5A2R0"
]

Test[
	ConcreteParseString["a;(**)&"]
	,
	ContainerNode[String, {
		PostfixNode[Function, {
			InfixNode[CompoundExpression, {
				LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
				LeafNode[Token`Semi, ";", <|Source -> {{1, 2}, {1, 3}}|>],
				LeafNode[Token`Fake`ImplicitNull, "", <|Source -> {{1, 3}, {1, 3}}|>]}, <|Source -> {{1, 1}, {1, 3}}|>],
			LeafNode[Token`Comment, "(**)", <|Source -> {{1, 3}, {1, 7}}|>],
			LeafNode[Token`Amp, "&", <|Source -> {{1, 7}, {1, 8}}|>]}, <|Source -> {{1, 1}, {1, 8}}|>] }, <||>]
	,
	TestID->"Concrete-20190914-L1P0K2"
]

Test[
	ConcreteParseString["a;(**);"]
	,
	ContainerNode[String, {
		InfixNode[CompoundExpression, {
			LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`Semi, ";", <|Source -> {{1, 2}, {1, 3}}|>],
			LeafNode[Token`Fake`ImplicitNull, "", <|Source -> {{1, 3}, {1, 3}}|>],
			LeafNode[Token`Comment, "(**)", <|Source -> {{1, 3}, {1, 7}}|>],
			LeafNode[Token`Semi, ";", <|Source -> {{1, 7}, {1, 8}}|>],
			LeafNode[Token`Fake`ImplicitNull, "", <|Source -> {{1, 8}, {1, 8}}|>]}, <|Source -> {{1, 1}, {1, 8}}|>] }, <||>]
	,
	TestID->"Concrete-20190914-E0H4C5"
]

Test[
	ConcreteParseString["{a;\n}"]
	,
	ContainerNode[String, {
		GroupNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			InfixNode[CompoundExpression, {
				LeafNode[Symbol, "a", <|Source -> {{1, 2}, {1, 3}}|>],
				LeafNode[Token`Semi, ";", <|Source -> {{1, 3}, {1, 4}}|>],
				LeafNode[Token`Fake`ImplicitNull, "", <|Source -> {{1, 4}, {1, 4}}|>]}, <|Source -> {{1, 2}, {1, 4}}|>],
			LeafNode[Token`Newline, "\n", <|Source -> {{2, 0}, {2, 1}}|>],
			LeafNode[Token`CloseCurly, "}", <|Source -> {{2, 1}, {2, 2}}|>]}, <|Source -> {{1, 1}, {2, 2}}|>] }, <||>]
	,
	TestID->"Concrete-20190914-X0P1Q6"
]



TestMatch[
	ConcreteParseString["a;;;;;;"]
	,
	ContainerNode[String, {
		InfixNode[Times, {
			BinaryNode[Span, {
				LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
	    		LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 2}, {1, 4}}|>], 
	    		LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 4}, {1, 4}}|>]}, <|Source -> {{1, 1}, {1, 4}}|>],
	    	LeafNode[Token`Fake`ImplicitTimes, "", <|Source -> {{1, 4}, {1, 4}}|>],
	    	BinaryNode[Span, {
	    		LeafNode[Token`Fake`ImplicitOne, "", <|Source -> {{1, 4}, {1, 4}}|>],
	    		LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 4}, {1, 6}}|>],
	    		LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 6}, {1, 6}}|>]}, <|Source -> {{1, 4}, {1, 6}}|>],
	    	LeafNode[Token`Fake`ImplicitTimes, "", <|Source -> {{1, 6}, {1, 6}}|>],
	    	BinaryNode[Span, {
	    		LeafNode[Token`Fake`ImplicitOne, "", <|Source -> {{1, 6}, {1, 6}}|>],
	    		LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 6}, {1, 8}}|>],
	    		LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 8}, {1, 8}}|>]}, <|Source -> {{1, 6}, {1, 8}}|>]}, <|Source -> {{1, 1}, {1, 8}}|>] }, _]
	,
	TestID->"Concrete-20190928-L8N1U0"
]

TestMatch[
	ConcreteParseString["a;;;;(**);;"]
	,
	ContainerNode[String, {
		InfixNode[Times, {
			BinaryNode[Span, {
				LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
	    		LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 2}, {1, 4}}|>], 
	    		LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 4}, {1, 4}}|>]}, <|Source -> {{1, 1}, {1, 4}}|>],
	    	LeafNode[Token`Fake`ImplicitTimes, "", <|Source -> {{1, 4}, {1, 4}}|>], 
	    	BinaryNode[Span, {
	    		LeafNode[Token`Fake`ImplicitOne, "", <|Source -> {{1, 4}, {1, 4}}|>],
	    		LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 4}, {1, 6}}|>],
	    		LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 6}, {1, 6}}|>]}, <|Source -> {{1, 4}, {1, 6}}|>],
	    	LeafNode[Token`Comment, "(**)", <|Source -> {{1, 6}, {1, 10}}|>],
	    	LeafNode[Token`Fake`ImplicitTimes, "", <|Source -> {{1, 10}, {1, 10}}|>],
	    	BinaryNode[Span, {
	    		LeafNode[Token`Fake`ImplicitOne, "", <|Source -> {{1, 10}, {1, 10}}|>],
	    		LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 10}, {1, 12}}|>],
	    		LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 12}, {1, 12}}|>]}, <|Source -> {{1, 10}, {1, 12}}|>]}, <|Source -> {{1, 1}, {1, 12}}|>] }, _]
	,
	TestID->"Concrete-20190914-K2Z7E2"
]

Test[
	ConcreteParseString["a(**):b"]
	,
	ContainerNode[String, {
		BinaryNode[Pattern, {
			LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`Comment, "(**)", <|Source -> {{1, 2}, {1, 6}}|>],
			LeafNode[Token`Colon, ":", <|Source -> {{1, 6}, {1, 7}}|>],
			LeafNode[Symbol, "b", <|Source -> {{1, 7}, {1, 8}}|>]}, <|Source -> {{1, 1}, {1, 8}}|>] }, <||>]
	,
	TestID->"Concrete-20190915-S7T5K8"
]

Test[
	ConcreteParseString["a:(**)b"]
	,
	ContainerNode[String, {
		BinaryNode[Pattern, {
			LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`Colon, ":", <|Source -> {{1, 2}, {1, 3}}|>],
			LeafNode[Token`Comment, "(**)", <|Source -> {{1, 3}, {1, 7}}|>],
			LeafNode[Symbol, "b", <|Source -> {{1, 7}, {1, 8}}|>]}, <|Source -> {{1, 1}, {1, 8}}|>] }, <||>]
	,
	TestID->"Concrete-20190915-E7Q5J3"
]

Test[
	ConcreteParseString[";;(**)*2"]
	,
	ContainerNode[String, {
		InfixNode[Times, {
			BinaryNode[Span, {
				LeafNode[Token`Fake`ImplicitOne, "", <|Source -> {{1, 1}, {1, 1}}|>],
				LeafNode[Token`SemiSemi, ";;", <|Source -> {{1, 1}, {1, 3}}|>],
				LeafNode[Token`Fake`ImplicitAll, "", <|Source -> {{1, 3}, {1, 3}}|>]}, <|Source -> {{1, 1}, {1, 3}}|>],
			LeafNode[Token`Comment, "(**)", <|Source -> {{1, 3}, {1, 7}}|>],
			LeafNode[Token`Star, "*", <|Source -> {{1, 7}, {1, 8}}|>],
			LeafNode[Integer, "2", <|Source -> {{1, 8}, {1, 9}}|>]}, <|Source -> {{1, 1}, {1, 9}}|>] }, <||>]
	,
	TestID->"Concrete-20190915-Y4E3E1"
]

Test[
	ConcreteParseString["{ headIn__ }"]
	,
	ContainerNode[String, {
		GroupNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 2}, {1, 3}}|>],
			PatternBlankSequenceNode[PatternBlankSequence, {
				LeafNode[Symbol, "headIn", <|Source -> {{1, 3}, {1, 9}}|>],
				LeafNode[BlankSequence, "__", <|Source -> {{1, 9}, {1, 11}}|>]}, <|Source -> {{1, 3}, {1, 11}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 11}, {1, 12}}|>],
			LeafNode[Token`CloseCurly, "}", <|Source -> {{1, 12}, {1, 13}}|>]}, <|Source -> {{1, 1}, {1, 13}}|>] }, <||>]
	,
	TestID->"Concrete-20190916-X5M4H9"
]

Test[
	ConcreteParseString["a(*1*)+(*2*)b(*3*);"]
	,
	ContainerNode[String, {
		InfixNode[CompoundExpression, {
			InfixNode[Plus, {
				LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
				LeafNode[Token`Comment, "(*1*)", <|Source -> {{1, 2}, {1, 7}}|>],
				LeafNode[Token`Plus, "+", <|Source -> {{1, 7}, {1, 8}}|>],
				LeafNode[Token`Comment, "(*2*)", <|Source -> {{1, 8}, {1, 13}}|>],
				LeafNode[Symbol, "b", <|Source -> {{1, 13}, {1, 14}}|>]}, <|Source -> {{1, 1}, {1, 14}}|>],
			LeafNode[Token`Comment, "(*3*)", <|Source -> {{1, 14}, {1, 19}}|>],
			LeafNode[Token`Semi, ";", <|Source -> {{1, 19}, {1, 20}}|>],
			LeafNode[Token`Fake`ImplicitNull, "", <|Source -> {{1, 20}, {1, 20}}|>]}, <|Source -> {{1, 1}, {1, 20}}|>] }, <||>]
	,
	TestID->"Concrete-20190916-L9G1L8"
]

Test[
	ConcreteParseString["{(*1*)[(*2*)](*3*)}"]
	,
	ContainerNode[String, {
		GroupNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`Comment, "(*1*)", <|Source -> {{1, 2}, {1, 7}}|>],
			GroupNode[GroupSquare, {
				LeafNode[Token`OpenSquare, "[", <|Source -> {{1, 7}, {1, 8}}|>],
				LeafNode[Token`Comment, "(*2*)", <|Source -> {{1, 8}, {1, 13}}|>],
				LeafNode[Token`CloseSquare, "]", <|Source -> {{1, 13}, {1, 14}}|>]}, <|Source -> {{1, 7}, {1, 14}}|>],
			LeafNode[Token`Comment, "(*3*)", <|Source -> {{1, 14}, {1, 19}}|>],
			LeafNode[Token`CloseCurly, "}", <|Source -> {{1, 19}, {1, 20}}|>]}, <|Source -> {{1, 1}, {1, 20}}|>] }, <||>]
	,
	TestID->"Concrete-20190916-U0Q1K6"
]

TestMatch[
	ConcreteParseString["{(*0*)a(*1*),(*2*)b(*3*)}"]
	,
	ContainerNode[String, {
		GroupNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`Comment, "(*0*)", <|Source -> {{1, 2}, {1, 7}}|>],
			InfixNode[Comma, {
				LeafNode[Symbol, "a", <|Source -> {{1, 7}, {1, 8}}|>],
				LeafNode[Token`Comment, "(*1*)", <|Source -> {{1, 8}, {1, 13}}|>],
				LeafNode[Token`Comma, ",", <|Source -> {{1, 13}, {1, 14}}|>],
				LeafNode[Token`Comment, "(*2*)", <|Source -> {{1, 14}, {1, 19}}|>],
				LeafNode[Symbol, "b", <|Source -> {{1, 19}, {1, 20}}|>]}, <|Source -> {{1, 7}, {1, 20}}|>],
			LeafNode[Token`Comment, "(*3*)", <|Source -> {{1, 20}, {1, 25}}|>],
			LeafNode[Token`CloseCurly, "}", <|Source -> {{1, 25}, {1, 26}}|>]}, <|Source -> {{1, 1}, {1, 26}}|>] }, _]
	,
	TestID->"Concrete-20190916-C5C7M2"
]

Test[
	ConcreteParseString["a=..", f]
	,
	f[{{LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
		LeafNode[Token`Error`UnhandledDot, "=..", <|Source -> {{1, 2}, {1, 5}}|>]}, {}}]
	,
	TestID->"Concrete-20190916-N2A8O1"
]

Test[
	ConcreteParseString["a~f~b"]
	,
	ContainerNode[String, {
		TernaryNode[TernaryTilde, {
			LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`Tilde, "~", <|Source -> {{1, 2}, {1, 3}}|>],
			LeafNode[Symbol, "f", <|Source -> {{1, 3}, {1, 4}}|>],
			LeafNode[Token`Tilde, "~", <|Source -> {{1, 4}, {1, 5}}|>],
			LeafNode[Symbol, "b", <|Source -> {{1, 5}, {1, 6}}|>]}, <|Source -> {{1, 1}, {1, 6}}|>] }, <||>]
	,
	TestID->"Concrete-20190928-H3B3V1"
]

Test[
	ConcreteParseString["a /: b = (c = d)"]
	,
	ContainerNode[String, {
		TernaryNode[TagSet, {
			LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 2}, {1, 3}}|>],
			LeafNode[Token`SlashColon, "/:", <|Source -> {{1, 3}, {1, 5}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 5}, {1, 6}}|>],
			LeafNode[Symbol, "b", <|Source -> {{1, 6}, {1, 7}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 7}, {1, 8}}|>],
			LeafNode[Token`Equal, "=", <|Source -> {{1, 8}, {1, 9}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 9}, {1, 10}}|>],
			GroupNode[GroupParen, {
				LeafNode[Token`OpenParen, "(", <|Source -> {{1, 10}, {1, 11}}|>],
				BinaryNode[Set, {
					LeafNode[Symbol, "c", <|Source -> {{1, 11}, {1, 12}}|>],
					LeafNode[Whitespace, " ", <|Source -> {{1, 12}, {1, 13}}|>],
					LeafNode[Token`Equal, "=", <|Source -> {{1, 13}, {1, 14}}|>],
					LeafNode[Whitespace, " ", <|Source -> {{1, 14}, {1, 15}}|>],
					LeafNode[Symbol, "d", <|Source -> {{1, 15}, {1, 16}}|>]}, <|Source -> {{1, 11}, {1, 16}}|>],
				LeafNode[Token`CloseParen, ")", <|Source -> {{1, 16}, {1, 17}}|>]}, <|Source -> {{1, 10}, {1, 17}}|>]}, <|Source -> {{1, 1}, {1, 17}}|>] }, <||>]
	,
	TestID->"Concrete-20190929-V7J8D5"
]
			
TestMatch[
	ConcreteParseString["{12,\\\n3}"]
	,
	ContainerNode[String, {
		GroupNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			InfixNode[Comma, {
				LeafNode[Integer, "12", <|Source -> {{1, 2}, {1, 4}}|>],
				LeafNode[Token`Comma, ",", <|Source -> {{1, 4}, {1, 5}}|>],
				LeafNode[Token`LineContinuation, "\\\n", <|Source -> {{1, 5}, {2, 1}}|>],
				LeafNode[Integer, "3", <|Source -> {{2, 1}, {2, 2}}|>]}, <|Source -> {{1, 2}, {2, 2}}|>],
			LeafNode[Token`CloseCurly, "}", <|Source -> {{2, 2}, {2, 3}}|>]}, <|Source -> {{1, 1}, {2, 3}}|>] }, _]
	,
	TestID->"Concrete-20190930-B8P9Y9"
]

Test[
	ConcreteParseString["{ @@ }"]
	,
	ContainerNode[String, {
		GroupNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 2}, {1, 3}}|>],
			BinaryNode[Apply, {
				LeafNode[Token`Error`ExpectedOperand, "", <|Source -> {{1, 3}, {1, 3}}|>], 
	    		LeafNode[Token`AtAt, "@@", <|Source -> {{1, 3}, {1, 5}}|>], 
	    		LeafNode[Token`Error`ExpectedOperand, "", <|Source -> {{1, 5}, {1, 5}}|>]}, <|Source -> {{1, 3}, {1, 5}}|>],
	    	LeafNode[Whitespace, " ", <|Source -> {{1, 5}, {1, 6}}|>], 
	    	LeafNode[Token`CloseCurly, "}", <|Source -> {{1, 6}, {1, 7}}|>]}, <|Source -> {{1, 1}, {1, 7}}|>] }, <||>]
	,
	TestID->"Concrete-20191012-S7X3B0"
]

Test[
	ConcreteParseString["\"a\\\\\r\nb\""]
	,
	ContainerNode[String, {
		LeafNode[String, "\"a\\\\\r\nb\"", <|Source -> {{1, 1}, {2, 3}}|>] }, <||>]
	,
	TestID->"Concrete-20191024-X1D5H3"
]

Test[
	ConcreteParseString["^ "]
	,
	ContainerNode[String, {
		BinaryNode[Power, {
			LeafNode[Token`Error`ExpectedOperand, "", <|Source -> {{1, 1}, {1, 1}}|>],
			LeafNode[Token`Caret, "^", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`Error`ExpectedOperand, "", <|Source -> {{1, 2}, {1, 2}}|>]}, <|Source -> {{1, 1}, {1, 2}}|>],
		LeafNode[Whitespace, " ", <|Source -> {{1, 2}, {1, 3}}|>]}, <||>]
	,
	TestID->"Concrete-20191117-M2R5P9"
]

TestMatch[
	ConcreteParseString["0.."]
	,
	ContainerNode[String, {
		PostfixNode[Repeated, {
			LeafNode[Integer, "0", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Token`DotDot, "..", <|Source -> {{1, 2}, {1, 4}}|>]}, <|Source -> {{1, 1}, {1, 4}}|>]}, _]
	,
	TestID -> "Concrete-20191119-J0T1L1"
]

Test[
	ConcreteParseString["(*)a"]
	,
	ContainerNode[String, {
		LeafNode[Token`Error`UnterminatedComment, "(*)a", <|Source -> {{1, 1}, {1, 5}}|>]}, <||>]
	,
	TestID->"Concrete-20191209-I8G4F9"
]

Test[
	ConcreteParseString["12^^a.a"]
	,
	ContainerNode[String, {
		LeafNode[Real, "12^^a.a", <|Source -> {{1, 1}, {1, 8}}|>]}, <||>]
	,
	TestID->"Concrete-20191209-A4X1E9"
]

Test[
	ConcreteParseString["(*\\a*)"]
	,
	ContainerNode[String, {
		LeafNode[Token`Comment, "(*\\a*)", <|Source -> {{1, 1}, {1, 7}}|>]}, <||>]
	,
	TestID->"Concrete-20191210-U8V1Y3"
]

Test[
	(* yes, actual \[Alpha] character on purpose *)
	ConcreteParseString["{\[Alpha],b}"]
	,
	ContainerNode[String, {
		GroupNode[List, {
			LeafNode[Token`OpenCurly, "{", <|Source -> {{1, 1}, {1, 2}}|>],
			InfixNode[Comma, {
				LeafNode[Symbol, "\[Alpha]", <|Source -> {{1, 2}, {1, 3}}|>],
				LeafNode[Token`Comma, ",", <|Source -> {{1, 3}, {1, 4}}|>],
				LeafNode[Symbol, "b", <|Source -> {{1, 4}, {1, 5}}|>]}, <|Source -> {{1, 2}, {1, 5}}|>],
			LeafNode[Token`CloseCurly, "}", <|Source -> {{1, 5}, {1, 6}}|>]}, <|Source -> {{1, 1}, {1, 6}}|>]}
			,
			<|SyntaxIssues -> {SyntaxIssue["UnexpectedCharacter", "Unexpected letterlike character: ``\\[Alpha]``.", "Warning", <|Source -> {{1, 2}, {1, 3}}, ConfidenceLevel -> 0.9|>]}|>]
	,
	TestID->"Concrete-20191212-V5Q2Y2"
]



Test[
	ConcreteParseString["\\[Alpa]"]
	,
	ContainerNode[String, {
		LeafNode[Token`Error`UnhandledCharacter, "\\[Alpa]", <|Source -> {{1, 1}, {1, 8}}|>]},
		<|SyntaxIssues -> {
			SyntaxIssue["UnrecognizedCharacter", "Unrecognized character: ``\\[Alpa]``.", "Error", <|
				Source -> {{1, 1}, {1, 8}},
				ConfidenceLevel -> 1., 
		     	CodeActions -> {
		     		CodeAction["Replace with \\[Alpha]", ReplaceText, <|Source -> {{1, 1}, {1, 8}}, "ReplacementText" -> "\\[Alpha]"|>]}|>]}|>]
	,
	TestID->"Concrete-20200105-L1E1C8"
]


TestMatch[
	ConcreteParseString["a \\[Minus] b"]
	,
	ContainerNode[String, {
		InfixNode[Plus, {
			LeafNode[Symbol, "a", <|Source -> {{1, 1}, {1, 2}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 2}, {1, 3}}|>],
			LeafNode[Token`LongName`Minus, "\\[Minus]", <|Source -> {{1, 3}, {1, 11}}|>],
			LeafNode[Whitespace, " ", <|Source -> {{1, 11}, {1, 12}}|>],
			LeafNode[Symbol, "b", <|Source -> {{1, 12}, {1, 13}}|>]}, <|Source -> {{1, 1}, {1, 13}}|>]}, _]
	,
	TestID->"Concrete-20200107-T6O6O1"
]



