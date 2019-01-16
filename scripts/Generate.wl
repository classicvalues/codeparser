
(*

Calling this script like this:

wolfram -script scripts/Generate.wl -buildDir /path/to/build/dir

will generate additional required files in these directories:

/path/to/build/dir/generated/cpp
/path/to/build/dir/generated/wl
/path/to/build/dir/paclet/AST

*)


Print["Generating additional required C++ and WL files"]

If[!($VersionNumber >= 11.0),
  Print["Expected $VersionNumber of at least 11.0"];
  Print["Actual $VersionNumber is: ", $VersionNumber];
  Quit[1]
]



packageDir = Directory[]

If[FileNameSplit[packageDir][[-1]] =!= "ast",
  Print["Cannot proceed; Not inside ast directory: ", packageDir];
  Quit[1]
]



buildDirFlagPosition = FirstPosition[$CommandLine, "-buildDir"]

If[MissingQ[buildDirFlagPosition],
  Print["Cannot proceed; Unsupported build directory"];
  Quit[1]
]

buildDir = $CommandLine[[buildDirFlagPosition[[1]] + 1]]

If[FileType[buildDir] =!= Directory,
  Print["Cannot proceed; Unsupported build directory"];
  Quit[1]
]



generatedCPPDir = FileNameJoin[{buildDir, "generated", "cpp"}]
generatedCPPIncludeDir = FileNameJoin[{generatedCPPDir, "include"}]
generatedCPPSrcDir = FileNameJoin[{generatedCPPDir, "src"}]

generatedWLDir = FileNameJoin[{buildDir, "generated", "wl"}]

pacletASTDir = FileNameJoin[{buildDir, "paclet", "AST"}]

tablesDir = FileNameJoin[{packageDir, "AST", "tables"}]

(* setup *)
Print["Setup"]

If[!($VersionNumber >= 12.0),
PrependTo[$Path, pacletASTDir];
]

res = PacletDirectoryAdd[pacletASTDir];
Print["PacletDirectoryAdd returned: ", res]

If[FailureQ[FindFile["AST`"]],
  Print["AST could not be found."];
  Quit[1]
]

If[FindFile["AST`"] =!= FileNameJoin[{pacletASTDir, "AST.wl"}],
  Print["Conflicting location for AST was found."];
  Print["Expected to find AST here: ", FileNameJoin[{pacletASTDir, "AST.wl"}]];
  Print["Actually found AST here: ", FindFile["AST`"]];
  If[FindFile["AST`"] === FileNameJoin[{packageDir, "AST", "AST.wl"}],
    Print["It looks like the AST source is being used. This is not supported."];
    Print["There may be a problem with the version of Wolfram Engine that is being used."];
    ,
    Print["Consider running:\nPacletUninstall[\"AST\"]"];
  ];
  Quit[1]
]




res = Needs["AST`"]

If[FailureQ[res],
  Print["Needs[\"AST`\"] failed: ", res];
  Quit[1];
]

res = Needs["AST`Utils`"]

If[FailureQ[res],
  Print["Needs[\"AST`Utils`\"] failed: ", res];
  Quit[1];
]




(*
uppercases and replaces ` with _
*)
toGlobal[n_] := 
 StringReplace[ToUpperCase[ToString[n]], "`" -> "_"]


(*
longNameToHexDigits["Alpha"] is "03b1"
*)
longNameToHexDigits[longName_String] :=
  IntegerString[ToCharacterCode[ToExpression["\"\\[" <> longName <> "]\""]], 16, 4]





(* clean *)
Print["Clean"]

Quiet[DeleteDirectory[generatedCPPDir, DeleteContents -> True], DeleteDirectory::nodir]

Quiet[CreateDirectory[generatedCPPDir], CreateDirectory::filex]

Quiet[CreateDirectory[generatedCPPIncludeDir], CreateDirectory::filex]

Quiet[CreateDirectory[generatedCPPSrcDir], CreateDirectory::filex]

Quiet[CreateDirectory[generatedWLDir], CreateDirectory::filex]


(* LongNameDefines *)
Print["generating LongNameDefines"]

importedLongNames = Get[FileNameJoin[{tablesDir, "LongNames.wl"}]]

If[FailureQ[importedLongNames],
  Print[importedLongNames];
  Quit[1]
]

If[!DuplicateFreeQ[importedLongNames],
  Print["LongNames.wl has duplicates"];
  Quit[1]
]

Check[
defines = ("#define " <> toGlobal["WLCharacter`LongName`" <> #] <> " " <> "0x" <> longNameToHexDigits[#])& /@ importedLongNames
,
Print["Message while generating LongNameDefines"];
Quit[1]
]


longNameDefinesCPPHeader = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//
"} ~Join~ defines ~Join~ {""}

Print["exporting LongNameDefines.h"]
res = Export[FileNameJoin[{generatedCPPIncludeDir, "LongNameDefines.h"}], Column[longNameDefinesCPPHeader], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]

(*

LongNameDefines.wl is not used right now

Check[
sets = ("WLCharacter`LongName`"<># <> " = " <> "16^^" <> longNameToHexDigits[#])& /@ importedLongNames
,
Print["Message while generating LongNameDefines"];
Quit[1]
]

longNameDefinesWL = {
"
(*
AUTO GENERATED FILE
DO NOT MODIFY
*)
"} ~Join~ sets ~Join~ {
"
Null
"}

Print["exporting LongNameDefines.wl"]
res = Export[FileNameJoin[{pacletASTDir, "LongNameDefines.wl"}], longNameDefinesWL, "Text"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]
*)



(* LongNameMap *)
Print["generating LongNameMap"]

longNameToCodePointMap = {
"std::map <std::string, int> LongNameToCodePointMap {"} ~Join~ (Row[{"{", escapeString[#], ",", " ", toGlobal["WLCharacter`LongName`"<>#], "}", ","}]& /@ importedLongNames) ~Join~ {"};", ""}

codePointToLongNameMap = {
"std::map <int, std::string> CodePointToLongNameMap {"} ~Join~ (Row[{"{", toGlobal["WLCharacter`LongName`"<>#], ",", " ", escapeString[#], "}", ","}] & /@ importedLongNames)~Join~{"};", ""}

longNameMapCPPSource = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#include \"LongNameMap.h\"
#include \"LongNameDefines.h\"
#include <map>
#include <string>
"} ~Join~ longNameToCodePointMap ~Join~ codePointToLongNameMap

Print["exporting LongNameMap.cpp"]
res = Export[FileNameJoin[{generatedCPPSrcDir, "LongNameMap.cpp"}], Column[longNameMapCPPSource], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]


longNameMapCPPHeader = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#include <map>
#include <string>

extern std::map<std::string, int>LongNameToCodePointMap;
extern std::map<int, std::string>CodePointToLongNameMap;
"}

Print["exporting LongNameMap.h"]
res = Export[FileNameJoin[{generatedCPPIncludeDir, "LongNameMap.h"}], Column[longNameMapCPPHeader], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]


longNameToCodePointAssociation = {
"LongNameToCodePointAssociation = <|"} ~Join~ (Row[{escapeString[#], " -> ", "WLCharacter`LongName`" <> #, ","}]& /@ 
     importedLongNames) ~Join~ {"Nothing"} ~Join~ {"|>"}

codePointToLongNameAssociation = {
"CodePointToLongNameAssociation = <|"} ~Join~ (Row[{"WLCharacter`LongName`" <> #, " -> ", escapeString[#], ","}]& /@ 
     importedLongNames) ~Join~ {"Nothing"} ~Join~ {"|>"}




longNameMapWL = {
"
(*
AUTO GENERATED FILE
DO NOT MODIFY
*)
"} ~Join~ longNameToCodePointAssociation ~Join~ {""} ~Join~ codePointToLongNameAssociation ~Join~ {
"
Null
"}

Print["exporting LongNameMap.wl"]
res = Export[FileNameJoin[{generatedWLDir, "LongNameMap.wl"}], Column[longNameMapWL], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]







(* CodePoint *)
Print["generating CodePoint"]

importedLetterlikeLongNames = Get[FileNameJoin[{tablesDir, "LetterlikeLongNames.wl"}]]

If[FailureQ[importedLetterlikeLongNames],
  Print[importedLetterlikeLongNames];
  Quit[1]
]

If[!DuplicateFreeQ[importedLetterlikeLongNames],
  Print["LetterlikeLongNames.wl has duplicates"];
  Quit[1]
]

importedOperatorLongNames = Get[FileNameJoin[{tablesDir, "OperatorLongNames.wl"}]]

If[FailureQ[importedOperatorLongNames],
  Print[importedOperatorLongNames];
  Quit[1]
]

If[!DuplicateFreeQ[importedOperatorLongNames],
  Print["OperatorLongNames.wl has duplicates"];
  Quit[1]
]

importedCommaLongNames = Get[FileNameJoin[{tablesDir, "CommaLongNames.wl"}]]

If[FailureQ[importedCommaLongNames],
  Print[importedCommaLongNames];
  Quit[1]
]

If[!DuplicateFreeQ[importedCommaLongNames],
  Print["CommaLongNames.wl has duplicates"];
  Quit[1]
]

importedNewlineLongNames = Get[FileNameJoin[{tablesDir, "NewlineLongNames.wl"}]]

If[FailureQ[importedNewlineLongNames],
  Print[importedNewlineLongNames];
  Quit[1]
]

If[!DuplicateFreeQ[importedNewlineLongNames],
  Print["NewlineLongNames.wl has duplicates"];
  Quit[1]
]

importedSpaceLongNames = Get[FileNameJoin[{tablesDir, "SpaceLongNames.wl"}]]

If[FailureQ[importedSpaceLongNames],
  Print[importedSpaceLongNames];
  Quit[1]
]

If[!DuplicateFreeQ[importedSpaceLongNames],
  Print["SpaceLongNames.wl has duplicates"];
  Quit[1]
]

importedStrangeLetterlikeCodePoints = Get[FileNameJoin[{tablesDir, "StrangeLetterlikeCodePoints.wl"}]]

If[FailureQ[importedStrangeLetterlikeCodePoints],
  Print[importedStrangeLetterlikeCodePoints];
  Quit[1]
]

If[!DuplicateFreeQ[importedStrangeLetterlikeCodePoints],
  Print["StrangeLetterlikeCodePoints.wl has duplicates"];
  Quit[1]
]



codePointCPPHeader = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#include \"Token.h\"

#include <string>

bool isLetterlikeCodePoint(int i);
bool isStrangeLetterlikeCodePoint(int i);
bool isOperatorCodePoint(int i);
bool isSpaceCodePoint(int i);
bool isNewlineCodePoint(int i);
bool isCommaCodePoint(int i);

Token LongNameCodePointToOperator(int c);
int LongNameOperatorToCodePoint(Token t);
"}

Print["exporting CodePoint.h"]
res = Export[FileNameJoin[{generatedCPPIncludeDir, "CodePoint.h"}], Column[codePointCPPHeader], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]


letterlikeSource = 
  {"std::unordered_set<int> letterlikeCodePoints {"} ~Join~
    (Row[{toGlobal["WLCharacter`LongName`"<>#], ","}]& /@ importedLetterlikeLongNames) ~Join~ 
    (Row[{#, ","}]& /@ importedStrangeLetterlikeCodePoints) ~Join~
    {"};", "",
    "bool isLetterlikeCodePoint(int i) { return letterlikeCodePoints.find(i) != letterlikeCodePoints.end();}", ""}

strangeLetterlikeSource = 
  {"std::unordered_set<int> strangeLetterlikeCodePoints {"} ~Join~
    (Row[{#, ","}]& /@ importedStrangeLetterlikeCodePoints) ~Join~
    {"};", "",
    "bool isStrangeLetterlikeCodePoint(int i) { return strangeLetterlikeCodePoints.find(i) != strangeLetterlikeCodePoints.end();}", ""}

operatorSource = 
  {"std::unordered_set<int> operatorCodePoints {"} ~Join~
    (Row[{toGlobal["WLCharacter`LongName`"<>#], ","}]& /@ importedOperatorLongNames) ~Join~
    {"};", "",
    "bool isOperatorCodePoint(int i) { return operatorCodePoints.find(i) != operatorCodePoints.end(); }", ""}

spaceSource = 
  {"std::unordered_set<int> spaceCodePoints {"} ~Join~
    (Row[{toGlobal["WLCharacter`LongName`"<>#], ","}]& /@ importedSpaceLongNames) ~Join~
    {"};", "",
    "bool isSpaceCodePoint(int i) { return spaceCodePoints.find(i) != spaceCodePoints.end(); }", ""}

newlineSource = 
  {"std::unordered_set<int> newlineCodePoints {"} ~Join~
    (Row[{toGlobal["WLCharacter`LongName`"<>#], ","}]& /@ importedNewlineLongNames) ~Join~
    {"};", "",
    "bool isNewlineCodePoint(int i) { return newlineCodePoints.find(i) != newlineCodePoints.end();}", ""}

commaSource = 
  {"std::unordered_set<int> commaCodePoints {"} ~Join~
    (Row[{toGlobal["WLCharacter`LongName`"<>#], ","}]& /@ importedCommaLongNames) ~Join~
    {"};", "",
    "bool isCommaCodePoint(int i) { return commaCodePoints.find(i) != commaCodePoints.end(); }", ""}

LongNameCodePointToOperatorSource = 
  {"Token LongNameCodePointToOperator(int c) {
switch (c) {"} ~Join~
    (Row[{"case", " ", toGlobal["WLCharacter`LongName`"<>#], ":", " ", "return", " ", 
        toGlobal["Token`Operator`LongName`"<>#], ";"}]& /@ importedOperatorLongNames) ~Join~
    {"default:
std::cerr << \"Need to add operator: 0x\" << std::setfill('0') << std::setw(4) << std::hex << c << std::dec << \"\\n\";
assert(false && \"Need to add operator\");
return TOKEN_ERROR_INTERNAL;
}
}"}

LongNameOperatorToCodePointSource = 
  {"
int LongNameOperatorToCodePoint(Token t) {
switch (t) {"} ~Join~
    (Row[{"case", " ", toGlobal["Token`Operator`LongName`"<>#], ":", " ", "return",
         " ", toGlobal["WLCharacter`LongName`"<>#], ";"}]& /@ importedOperatorLongNames) ~Join~
{"default:
std::cerr << \"Need to add operator: 0x\" << std::setfill('0') << std::setw(4) << std::hex << t << std::dec << \"\\n\";
assert(false && \"Need to add operator\");
return TOKEN_ERROR_INTERNAL;
}
}
"}

codePointCPPSource = Join[{
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#include \"CodePoint.h\"

#include \"LongNameDefines.h\"

#include <unordered_set>
#include <iostream>
#include <iomanip>
#include <cassert>
"}, letterlikeSource, strangeLetterlikeSource, 
    operatorSource, spaceSource, newlineSource, commaSource, 
    LongNameCodePointToOperatorSource, 
    LongNameOperatorToCodePointSource]

Print["exporting CodePoint.cpp"]
res = Export[FileNameJoin[{generatedCPPSrcDir, "CodePoint.cpp"}], Column[codePointCPPSource], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]











(* Token *)
Print["generating Token"]

operatorMacros = 
  Association[
   ToExpression["Token`Operator`LongName`" <> #] -> Next& /@ importedOperatorLongNames]

importedTokenEnumSource = 
  Get[FileNameJoin[{tablesDir, "TokenEnum.wl"}]]

If[FailureQ[importedTokenEnumSource],
  Print[importedTokenEnumSource];
  Quit[1]
]

joined = importedTokenEnumSource ~Join~ operatorMacros

oldTokens = ToString /@ Keys[joined]


cur = 0
enumMap = <||>
KeyValueMap[(
    Which[
     IntegerQ[#2], cur = #2,
     #2 === Next, cur = cur + 1,
     True, cur = enumMap[#2]];
    AssociateTo[enumMap, #1 -> cur]) &, joined]


tokenCPPHeader = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#pragma once

#include <string>

enum Token {"} ~Join~
   KeyValueMap[(Row[{toGlobal[#], " = ", #2, ","}])&, enumMap] ~Join~
   {"};", ""} ~Join~
   {"std::string TokenToString(Token type);",
   "bool isOperator(Token type);",
   "bool isError(Token type);",
   ""}

Print["exporting Token.h"]
res = Export[FileNameJoin[{generatedCPPIncludeDir, "Token.h"}], Column[tokenCPPHeader], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]



tokenWL = {
"
(*
AUTO GENERATED FILE
DO NOT MODIFY
*)
"} ~Join~ {"<|"} ~Join~
 (KeyValueMap[(Row[{#1, " -> ", #2, ","}])&, enumMap]) ~Join~
 {"Nothing", "|>", ""}

Print["exporting Token.wl"]
res = Export[FileNameJoin[{pacletASTDir, "Token.wl"}], Column[tokenWL], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]



res = Get[FileNameJoin[{generatedWLDir, "LongNameMap.wl"}]]

If[FailureQ[res],
  Print[res];
  Quit[1]
]



(*
remove values like Error`UNKNOWN in:
<|
Error`FIRST -> Next,
Error`UNKNOWN -> Error`FIRST
|>

because C switch statements cannot have duplicate cases

*)
uniqueEnums = DeleteCases[importedTokenEnumSource, v_ /; !IntegerQ[v] && UnsameQ[v, Next]]

tokenStrings = Association[# -> escapeString[ToString[#]]& /@ Keys[uniqueEnums]]

operatorMacros = 
  Association[ToExpression["Token`Operator`LongName`" <> #] -> escapeString["Token`Operator`LongName`" <> #]& /@ importedOperatorLongNames]



joined = tokenStrings ~Join~ operatorMacros

cases = KeyValueMap[Row[{"case ", toGlobal[#1], ": return ", #2, ";"}]&, joined]


tokenCPPSource = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#include \"Token.h\"
#include <iostream>
#include <cassert>
"} ~Join~
    {"std::string TokenToString(Token Tok) {"} ~Join~
    {"switch (Tok) {"} ~Join~
    cases ~Join~
    {"default:"} ~Join~
    {"std::cerr << \"Unhandled token type: \" << std::to_string(Tok) << \"\\n\"; assert(false && \"Unhandled token type\"); return \"\";"} ~Join~
    {"}"} ~Join~
    {"}"} ~Join~
    {""} ~Join~
    {"bool isOperator(Token Tok) { return TOKEN_OPERATOR_FIRST <= Tok && Tok < TOKEN_OPERATOR_END; }"} ~Join~
    {"bool isError(Token Tok) { return TOKEN_ERROR_FIRST <= Tok && Tok < TOKEN_ERROR_END; }"} ~Join~
    {""}

Print["exporting Token.cpp"]
res = Export[FileNameJoin[{generatedCPPSrcDir, "Token.cpp"}], Column[tokenCPPSource], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]









(* Precedence *)
Print["generating Precedence"]

importedPrecedenceSource = Get[FileNameJoin[{tablesDir, "Precedence.wl"}]]

If[FailureQ[importedPrecedenceSource],
  Print[importedPrecedenceSource];
  Quit[1]
]

oldPrecedences = Join[Names["Precedence`*"], Names["Precedence`*`*"]]

(*
resolve the symbolic values in the Precedence table to integer values
*)
cur = -Infinity;
enumMap = <||>;
KeyValueMap[(
    Which[
     NumberQ[#2], cur = #2,
     #2 === Indeterminate, cur = Indeterminate,
     #2 === Next, cur = cur + 1,
     True, cur = enumMap[#2]];
    AssociateTo[enumMap, #1 -> cur]) &, importedPrecedenceSource]

(*
sanity check that all precedences are in order
*)
cur = -Infinity;
KeyValueMap[
 If[#2 =!= Indeterminate && cur =!= Indeterminate && !TrueQ[#2 >= cur],
  Print["Precedence is out of order: ", #1->#2];
  Quit[1]
  ,
  cur = #2]&, enumMap]


precedenceCPPHeader = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#pragma once

enum precedence_t {"} ~Join~
   KeyValueMap[(Row[{toGlobal[#1], " = ",
    Which[
      NumberQ[#2], Floor[#2],
      #2 === Indeterminate, -1
    ], ","}]) &, enumMap] ~Join~ {"};", ""}

Print["exporting Precedence.h"]
res = Export[FileNameJoin[{generatedCPPIncludeDir, "Precedence.h"}], Column[precedenceCPPHeader], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]


precedenceWL = Column[{
"
(*
AUTO GENERATED FILE
DO NOT MODIFY
*)
"} ~Join~ {"<|"} ~Join~ (KeyValueMap[(Row[{#1, " -> ", #2, ","}]) &, enumMap]) ~Join~ {"Nothing", "|>", ""}]

Print["exporting Precedence.wl"]
res = Export[FileNameJoin[{pacletASTDir, "Precedence.wl"}], precedenceWL, "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]










(* Symbol *)
Print["generating Symbol"]

(*
sanity check Prefix operators
*)
If[Union[DownValues[PrefixOperatorToSymbol][[All, 2]]] =!= Union[DownValues[SymbolToPrefixOperatorString][[All, 1, 1, 1]]],
  Print["PrefixOperatorToSymbol and SymbolToPrefixOperatorString do not match"];
  Print["PrefixOperatorToSymbol:       ", Union[DownValues[PrefixOperatorToSymbol][[All, 2]]]];
  Print["SymbolToPrefixOperatorString: ", Union[DownValues[SymbolToPrefixOperatorString][[All, 1, 1, 1]]]];
  Quit[1]
]

(*
sanity check Postfix operators
*)
If[Union[DownValues[PostfixOperatorToSymbol][[All, 2]]] =!= Union[DownValues[SymbolToPostfixOperatorString][[All, 1, 1, 1]]],
  Print["PostfixOperatorToSymbol and SymbolToPostfixOperatorString do not match"];
  Print["PostfixOperatorToSymbol:       ", Union[DownValues[PostfixOperatorToSymbol][[All, 2]]]];
  Print["SymbolToPostfixOperatorString: ", Union[DownValues[SymbolToPostfixOperatorString][[All, 1, 1, 1]]]];
  Quit[1]
]

(*
sanity check Binary operators
*)
If[Union[DownValues[BinaryOperatorToSymbol][[All, 2]]] =!= Union[DownValues[SymbolToBinaryOperatorString][[All, 1, 1, 1]]],
  Print["BinaryOperatorToSymbol and SymbolToBinaryOperatorString do not match"];
  Print["BinaryOperatorToSymbol:       ", Union[DownValues[BinaryOperatorToSymbol][[All, 2]]]];
  Print["SymbolToBinaryOperatorString: ", Union[DownValues[SymbolToBinaryOperatorString][[All, 1, 1, 1]]]];
  Quit[1]
]

(*
sanity check Infix operators
*)
If[Union[DownValues[InfixOperatorToSymbol][[All, 2]]] =!= Union[DownValues[SymbolToInfixOperatorString][[All, 1, 1, 1]]],
  Print["InfixOperatorToSymbol and SymbolToInfixOperatorString do not match"];
  Print["InfixOperatorToSymbol:       ", Union[DownValues[InfixOperatorToSymbol][[All, 2]]]];
  Print["SymbolToInfixOperatorString: ", Union[DownValues[SymbolToInfixOperatorString][[All, 1, 1, 1]]]];
  Quit[1]
]

(*
sanity check Ternary operators
*)
If[Union[DownValues[TernaryOperatorsToSymbol][[All, 2]]] =!= Union[DownValues[SymbolToTernaryPair][[All, 1, 1, 1]]],
  Print["TernaryOperatorsToSymbol and SymbolToTernaryPair do not match"];
  Print["TernaryOperatorsToSymbol: ", Union[DownValues[TernaryOperatorsToSymbol][[All, 2]]]];
  Print["SymbolToTernaryPair:      ", Union[DownValues[SymbolToTernaryPair][[All, 1, 1, 1]]]];
  Quit[1]
]

If[Union[Flatten[DownValues[SymbolToTernaryPair][[All, 2]]]] =!= Union[DownValues[SymbolToTernaryOperatorString][[All, 1, 1, 1]]],
  Print["SymbolToTernaryPair and SymbolToTernaryOperatorString do not match"];
  Print["SymbolToTernaryPair:           ", Union[Flatten[DownValues[SymbolToTernaryPair][[All, 2]]]]];
  Print["SymbolToTernaryOperatorString: ", Union[DownValues[SymbolToTernaryOperatorString][[All, 1, 1, 1]]]];
  Quit[1]
]

(*
sanity check Group operators
*)
If[Union[Flatten[{DownValues[GroupOpenerToSymbol][[All, 2]],
                    DownValues[GroupCloserToSymbol][[All, 2]],
                    DownValues[GroupOpenerToMissingCloserSymbol][[All, 2]],
                    DownValues[GroupCloserToMissingOpenerSymbol][[All, 2]]}]] =!=
    Union[DownValues[SymbolToGroupPair][[All, 1, 1, 1]]],
  Print["GroupOpenerToSymbol ... and SymbolToGroupPair do not match"];
  Print["GroupOpenerToSymbol ...: ", Union[Flatten[{DownValues[GroupOpenerToSymbol][[All, 2]],
                                                      DownValues[GroupCloserToSymbol][[All, 2]],
                                                      DownValues[GroupOpenerToMissingCloserSymbol][[All, 2]],
                                                      DownValues[GroupCloserToMissingOpenerSymbol][[All, 2]]}]]];
  Print["SymbolToGroupPair:       ", Union[DownValues[SymbolToGroupPair][[All, 1, 1, 1]]]];
  Quit[1]
]

(*
Obtain all symbols by inspecting DownValues of functions
*)

symbols = Union[Join[DownValues[PrefixOperatorToSymbol][[All, 2]],
    DownValues[PostfixOperatorToSymbol][[All, 2]],
    DownValues[BinaryOperatorToSymbol][[All, 2]],
    DownValues[InfixOperatorToSymbol][[All, 2]],
    DownValues[TernaryOperatorToSymbol][[All, 2]],
    AST`Symbol`$Nodes,
    AST`Symbol`$Options,
    AST`Symbol`$Miscellaneous,
    AST`Symbol`$Tokens,
    AST`Symbol`$Groups,
    AST`Symbol`$Characters
    ]]

symbolCPPHeader = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#pragma once

#include \"Token.h\"

#include <string>
#include <utility>

class Symbol {
  std::string Name;
  public:Symbol(std::string Name):Name(Name) {}
  std::string name() const;
};

bool operator==(const Symbol& lhs, const Symbol& rhs);

const Symbol& PostfixOperatorToSymbol(Token);
const Symbol& PrefixOperatorToSymbol(Token);
const Symbol& BinaryOperatorToSymbol(Token);
const Symbol& InfixOperatorToSymbol(Token);
const Symbol& TernaryOperatorsToSymbol(Token, Token);
const Symbol& GroupOpenerToSymbol(Token);

Token GroupOpenerToCloser(Token);

const Symbol& GroupCloserToSymbol(Token);
const Symbol& GroupOpenerToMissingCloserSymbol(Token);
const Symbol& GroupCloserToMissingOpenerSymbol(Token);

std::string SymbolToPrefixOperatorString(const Symbol&);
std::string SymbolToPostfixOperatorString(const Symbol&);
std::string SymbolToBinaryOperatorString(const Symbol&);
std::string SymbolToInfixOperatorString(const Symbol&);
std::string SymbolToTernaryOperatorString(const Symbol&);

std::pair<std::string, std::string> SymbolToGroupPair(const Symbol&);
std::pair<const Symbol&, const Symbol&> SymbolToTernaryOperatorPair(const Symbol&);
"} ~Join~
(Row[{"extern", " ", "const", " ", "Symbol&", " ", toGlobal["Symbol`"<>ToString[#]], ";"}]& /@ symbols) ~Join~
{""}

Print["exporting Symbol.h"]
res = Export[FileNameJoin[{generatedCPPIncludeDir, "Symbol.h"}], Column[symbolCPPHeader], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]



symbolCPPSource = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#include \"Symbol.h\"

#include <cassert>
#include <iostream>

bool operator==(const Symbol& lhs, const Symbol& rhs) {
   return lhs.name() == rhs.name();
}

std::string Symbol::name() const {
   return Name;
}
"} ~Join~ 

    (Row[{"const", " ", "Symbol&", " ", toGlobal["Symbol`"<>ToString[#]], " ", "=", " ", "Symbol(\"", ToString[#], "\")", ";"}]& /@ symbols) ~Join~

      {""} ~Join~

      {"const Symbol& PrefixOperatorToSymbol(Token Type) {\nswitch (Type) {"} ~Join~
     
     Map[Row[{"case", " ", toGlobal[#[[1, 1, 1]]], ":", " ", "return", " ", toGlobal["Symbol`"<>ToString[#[[2]]]], ";"}]&, DownValues[PrefixOperatorToSymbol]] ~Join~ 
      {"default: std::cerr << \"Unhandled Token: \" << TokenToString(Type) << \"\\n\"; assert(false && \"Unhandled token\"); return " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ";",
      "}\n}"} ~Join~

     {""} ~Join~

     {"const Symbol& PostfixOperatorToSymbol(Token Type) {\nswitch (Type) {"} ~Join~
     
      Map[Row[{"case", " ", toGlobal[#[[1, 1, 1]]], ":", " ", "return", " ", toGlobal["Symbol`"<>ToString[#[[2]]]], ";"}]&, DownValues[PostfixOperatorToSymbol]] ~Join~
      {"default: std::cerr << \"Unhandled Token: \" << TokenToString(Type) << \"\\n\"; assert(false && \"Unhandled token\"); return " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ";",
     "}\n}"} ~Join~

     {""} ~Join~

     {"const Symbol& BinaryOperatorToSymbol(Token Type) {\nswitch (Type) {"} ~Join~
     
      Map[Row[{"case", " ", toGlobal[#[[1, 1, 1]]], ":", " ", "return", " ", toGlobal["Symbol`"<>ToString[#[[2]]]], ";"}]&, DownValues[BinaryOperatorToSymbol]] ~Join~
      {"default: std::cerr << \"Unhandled Token: \" << TokenToString(Type) << \"\\n\"; assert(false && \"Unhandled token\"); return " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ";",
     "}\n}"} ~Join~

     {""} ~Join~

     {"const Symbol& InfixOperatorToSymbol(Token Type) {\nswitch (Type) {"} ~Join~
     
      Map[Row[{"case", " ", toGlobal[#[[1, 1, 1]]], ":", " ", "return", " ", toGlobal["Symbol`"<>ToString[#[[2]]]], ";"}]&, DownValues[InfixOperatorToSymbol]] ~Join~
      {"default: std::cerr << \"Unhandled Token: \" << TokenToString(Type) << \"\\n\"; assert(false && \"Unhandled token\"); return " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ";",
     "}\n}"} ~Join~

     {""} ~Join~

     {"const Symbol& TernaryOperatorsToSymbol(Token Type1, Token Type2) {"} ~Join~

     (*
      cannot use C++ switch statements with 2 arguments, so just do a series of if statements
     *)
     Map[Row[{"if (Type1 == ", toGlobal[#[[1, 1, 1]]], " && Type2 == ", toGlobal[#[[1, 1, 2]]], ") {", "return", " ", toGlobal["Symbol`"<>ToString[#[[2]]]], ";", "}"}]&, DownValues[TernaryOperatorsToSymbol]] ~Join~
      {"std::cerr << \"Unhandled Tokens: \" << TokenToString(Type1) << \" \" << TokenToString(Type2) << \"\\n\"; assert(false && \"Unhandled token\"); return " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ";",
     "}"} ~Join~

     {""} ~Join~

     {"const Symbol& GroupOpenerToSymbol(Token Type) {\nswitch (Type) {"} ~Join~
      Map[Row[{"case", " ", toGlobal[#[[1, 1, 1]]], ":", " ", "return", " ", toGlobal["Symbol`"<>ToString[#[[2]]]], ";"}]&, DownValues[GroupOpenerToSymbol]] ~Join~
      {"default: std::cerr << \"Unhandled Token: \" << TokenToString(Type) << \"\\n\"; assert(false && \"Unhandled token\"); return " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ";",
     "}\n}"} ~Join~

     {""} ~Join~

     {"Token GroupOpenerToCloser(Token Type) {\nswitch (Type) {"} ~Join~
      Map[Row[{"case", " ", toGlobal[#[[1, 1, 1]]], ":", " ", "return", " ", toGlobal[#[[2]]], ";"}]&, DownValues[GroupOpenerToCloser]] ~Join~
      {"default: std::cerr << \"Unhandled Token: \" << TokenToString(Type) << \"\\n\"; assert(false && \"Unhandled token\"); return TOKEN_UNKNOWN;",
     "}\n}"} ~Join~

     {""} ~Join~

     {"const Symbol& GroupCloserToSymbol(Token Type) {\nswitch (Type) {"} ~Join~
      Map[Row[{"case", " ", toGlobal[#[[1, 1, 1]]], ":", " ", "return", " ", toGlobal["Symbol`"<>ToString[#[[2]]]], ";"}]&, DownValues[GroupCloserToSymbol]] ~Join~
      {"default: std::cerr << \"Unhandled Token: \" << TokenToString(Type) << \"\\n\"; assert(false && \"Unhandled token\"); return " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ";",
     "}\n}"} ~Join~

     {""} ~Join~

     {"const Symbol& GroupOpenerToMissingCloserSymbol(Token Type) {\nswitch (Type) {"} ~Join~
      Map[Row[{"case", " ", toGlobal[#[[1, 1, 1]]], ":", " ", "return", " ", toGlobal["Symbol`"<>ToString[#[[2]]]], ";"}]&, DownValues[GroupOpenerToMissingCloserSymbol]] ~Join~
      {"default: std::cerr << \"Unhandled Token: \" << TokenToString(Type) << \"\\n\"; assert(false && \"Unhandled token\"); return " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ";",
     "}\n}"} ~Join~

     {""} ~Join~

     {"const Symbol& GroupCloserToMissingOpenerSymbol(Token Type) {\nswitch (Type) {"} ~Join~
      Map[Row[{"case", " ", toGlobal[#[[1, 1, 1]]], ":", " ", "return", " ", toGlobal["Symbol`"<>ToString[#[[2]]]], ";"}]&, DownValues[GroupCloserToMissingOpenerSymbol]] ~Join~ 
      {"default: std::cerr << \"Unhandled Token: \" << TokenToString(Type) << \"\\n\"; assert(false && \"Unhandled token\"); return " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ";",
     "}\n}"} ~Join~

     {""} ~Join~
     {"std::pair<std::string, std::string> SymbolToGroupPair(const Symbol& Sym) {"} ~Join~
      (Row[{"if (Sym == ", toGlobal["Symbol`"<>ToString[#[[1, 1, 1]]]], ")", " ", 
          "{ return std::make_pair(std::string(", 
          escapeString[#[[2, 1]]], "), std::string(", 
          escapeString[#[[2, 2]]], "));", "}"}]& /@ DownValues[SymbolToGroupPair]) ~Join~ 
      {"return std::make_pair(std::string(\"XXX\"), std::string(\"XXX\"));",
     "}"} ~Join~

     {""} ~Join~
     {"std::string SymbolToPrefixOperatorString(const Symbol& Sym) {"} ~Join~
      (Row[{"if (Sym == ", toGlobal["Symbol`"<>ToString[#[[1, 1, 1]]]], ")", " ", 
          "{ return ", escapeString[#[[2]]], ";", "}"}]& /@ DownValues[SymbolToPrefixOperatorString]) ~Join~
      {"return \"XXX\";",
      "}",
     ""} ~Join~

     {"std::string SymbolToPostfixOperatorString(const Symbol& Sym) {"} ~Join~
      (Row[{"if (Sym == ", toGlobal["Symbol`"<>ToString[#[[1, 1, 1]]]], ")", " ", 
          "{ return ", escapeString[#[[2]]], ";", "}"}]& /@ DownValues[SymbolToPostfixOperatorString]) ~Join~
      {"return \"XXX\";",
     "}"} ~Join~
     {""} ~Join~

     {"std::string SymbolToBinaryOperatorString(const Symbol& Sym) {"} ~Join~
      (Row[{"if (Sym == ", toGlobal["Symbol`"<>ToString[#[[1, 1, 1]]]], ")", " ", 
          "{ return ", escapeString[#[[2]]], ";", "}"}]& /@ DownValues[SymbolToBinaryOperatorString]) ~Join~
      {"return \"XXX\";",
     "}",
     ""} ~Join~

     {"std::string SymbolToInfixOperatorString(const Symbol& Sym) {"} ~Join~
      (Row[{"if (Sym == ", toGlobal["Symbol`"<>ToString[#[[1, 1, 1]]]], ")", " ", 
          "{ return ", escapeString[#[[2]]], ";", "}"}]& /@ DownValues[SymbolToInfixOperatorString]) ~Join~
      {"return \"XXX\";",
     "}",
     ""} ~Join~

     {"std::string SymbolToTernaryOperatorString(const Symbol& Sym) {"} ~Join~
      (Row[{"if (Sym == ", toGlobal["Symbol`"<>ToString[#[[1, 1, 1]]]], ")", " ", 
          "{ return ", escapeString[#[[2]]], ";", "}"}]& /@ DownValues[SymbolToTernaryOperatorString]) ~Join~
      {"return \"XXX\";",
     "}",
     ""} ~Join~

     {"std::pair<const Symbol&, const Symbol&> SymbolToTernaryOperatorPair(const Symbol& Sym) {"} ~Join~
      (Row[{"if (Sym == ", toGlobal["Symbol`"<>ToString[#[[1, 1, 1]]]], ")", " ", 
          "{ return std::make_pair(", 
          toGlobal["Symbol`"<>ToString[#[[2, 1]]]], ", ", 
          toGlobal["Symbol`"<>ToString[#[[2, 2]]]], ");", "}"}]& /@ DownValues[SymbolToTernaryOperatorPair]) ~Join~
      {"return std::make_pair(" <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ", " <> toGlobal["Symbol`"<>ToString[InternalInvalid]] <> ");",
     "}",
     ""}

Print["exporting Symbol.cpp"]
res = Export[FileNameJoin[{generatedCPPSrcDir, "Symbol.cpp"}], Column[symbolCPPSource], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]







(* ToInputFormString *)
Print["generating ToInputFormString"]

toInputFormStringCPPHeader = {
"
//
// AUTO GENERATED FILE
// DO NOT MODIFY
//

#pragma once

#include \"Token.h\"

#include <string>

std::string ToInputFormString(std::shared_ptr<Node>);
"}

Print["exporting ToInputFormString.h"]
res = Export[FileNameJoin[{generatedCPPIncludeDir, "ToInputFormString.h"}], Column[toInputFormStringCPPHeader], "String"]

If[FailureQ[res],
  Print[res];
  Quit[1]
]






Print["Done generating additional required C++ and WL files"]


newTokens = Join[Names["Token`*"], Names["Token`*`*"]]

If[Complement[newTokens, oldTokens] =!= {},
  Print["New Tokens: ", Complement[newTokens, oldTokens]];
  Quit[1]
]

If[Length[Join[Names["LongName`*"], Names["LongName`*`*"]]] =!= 0,
  Print["LongName: ", Join[Names["LongName`*"], Names["LongName`*`*"]]];
  Quit[1]
]

newPrecedences = Join[Names["Precedence`*"], Names["Precedence`*`*"]]

If[Complement[newPrecedences, oldPrecedences] =!= {},
  Print["New Precedences: ", Complement[newPrecedences, oldPrecedences]];
  Quit[1]
]








