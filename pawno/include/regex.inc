
// Автор: Fro он же Fro1sha

#if defined _regex_included
	#endinput
#endif
#define _regex_included
#pragma library regex

// -------------------------------------------------------------------------------------*-

native RegEx:regex_build(const expression[]);
native regex_delete(RegEx:expID);
native regex_isvalid(RegEx:expID);
native regex_delete_all();

native regex_match(const string[], const expression[]);
native regex_search(const string[], const expression[]);
native regex_replace(const string[], const expression[], const to[], dest[], size = sizeof dest);

native regex_match_exid(const string[], RegEx:expID);
native regex_search_exid(const string[], RegEx:expID);
native regex_replace_exid(const string[], RegEx:expID, const to[], dest[], size = sizeof dest);

// -------------------------------------------------------------------------------------*-
