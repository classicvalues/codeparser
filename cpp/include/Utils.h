
#pragma once

#include "WLCharacter.h" // for WLCharacter
#include "Source.h" // for Source

#include <string>
#include <unordered_set> // for unordered_set


std::ostream& set_graphical(std::ostream& stream);

std::ostream& clear_graphical(std::ostream& stream);

int get_graphical_i();

//
//
//
class Utils {
public:
    
    static bool isStraySurrogate(codepoint point);
    
#if !NISSUES
    static bool isStrange(codepoint point);
    
    static bool isMBStrange(codepoint point);
#endif // !NISSUES
    
    //
    // Convert val to the digit that it represents
    //
    static uint8_t toDigit(unsigned char val);
    
    static SourceConvention parseSourceConvention(std::string s);
    
    //
    // if c is an ASCII WLCharacter, then compare to test
    //
    static bool ifASCIIWLCharacter(unsigned char c, char test);
    
    //
    //
    //
    static CodeActionPtrVector certainCharacterReplacementActions(WLCharacter c, Source src);
};
