/*
    This file is part of the generis distribution.

    https://github.com/senselogic/generis

    Copyright (C) 2017 Eric Pelzer (ecstatic.coder@gmail.com)

    generis is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    generis is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with generis.  If not, see <http://www.gnu.org/licenses/>.
*/

// -- IMPORTS

import core.stdc.stdlib : exit;
import core.thread;
import std.conv : to;
import std.datetime : Clock, SysTime;
import std.file : dirEntries, exists, mkdirRecurse, readText, timeLastModified, write, FileException, SpanMode;
import std.path : dirName;
import std.stdio : writeln;
import std.string : endsWith, indexOf, join, replace, split, startsWith, strip, stripLeft, stripRight, toLower, toUpper;

// -- TYPES

enum TOKEN_CONTEXT
{
    Code,
    ShortComment,
    LongComment,
    String
}

// ~~

enum TOKEN_TYPE
{
    Character,
    Blank,
    Identifier,
    Literal,
    Value,
    Parameter
}

// ~~

class TOKEN
{
    // -- ATTRIBUTES

    string
        Text;
    TOKEN_CONTEXT
        Context;
    TOKEN_TYPE
        Type;
    long
        Level;

    // -- CONSTRUCTORS

    this(
        TOKEN token
        )
    {
        Text = token.Text;
        Context = token.Context;
        Type = token.Type;
        Level = token.Level;
    }

    // ~~

    this(
        string text = "",
        TOKEN_CONTEXT token_context = TOKEN_CONTEXT.Code,
        TOKEN_TYPE token_type = TOKEN_TYPE.Character
        )
    {
        Text = text;
        Context = token_context;
        Type = token_type;
    }

    // ~~

    this(
        char character,
        TOKEN_CONTEXT token_context = TOKEN_CONTEXT.Code,
        TOKEN_TYPE token_type = TOKEN_TYPE.Character
        )
    {
        Text ~= character;
        Context = token_context;
        Type = token_type;
    }

    // -- INQUIRIES

    bool IsCode(
        )
    {
        return Context == TOKEN_CONTEXT.Code;
    }

    // ~~

    bool IsShortComment(
        )
    {
        return Context == TOKEN_CONTEXT.ShortComment;
    }

    // ~~

    bool IsLongComment(
        )
    {
        return Context == TOKEN_CONTEXT.LongComment;
    }

    // ~~

    bool IsComment(
        )
    {
        return
            Context == TOKEN_CONTEXT.ShortComment
            || Context == TOKEN_CONTEXT.LongComment;
    }

    // ~~

    bool IsString(
        )
    {
        return Context == TOKEN_CONTEXT.String;
    }

    // ~~

    bool IsCharacter(
        )
    {
        return Type == TOKEN_TYPE.Character;
    }

    // ~~

    bool IsBlank(
        )
    {
        return Type == TOKEN_TYPE.Blank;
    }

    // ~~

    bool IsIdentifier(
        )
    {
        return Type == TOKEN_TYPE.Identifier;
    }

    // ~~

    bool IsLiteral(
        )
    {
        return Type == TOKEN_TYPE.Literal;
    }

    // ~~

    bool IsValue(
        )
    {
        return Type == TOKEN_TYPE.Value;
    }

    // ~~

    bool IsParameter(
        )
    {
        return Type == TOKEN_TYPE.Parameter;
    }

    // ~~

    bool IsStringDelimiter(
        )
    {
        return
            Context == TOKEN_CONTEXT.String
            && Type == TOKEN_TYPE.Character
            && ( Text == "'"
                 || Text == "\""
                 || Text == "`" );
    }

    // ~~

    bool Matches(
        TOKEN token
        )
    {
        if ( Type == TOKEN_TYPE.Blank )
        {
            return token.Type == TOKEN_TYPE.Blank;
        }
        else
        {
            return token.Text == Text;
        }
    }

    // ~~

    void Dump(
        long token_index
        )
    {
        writeln( "[", token_index, "] ", Context, " ", Type, " : ", Text );
    }
}

// ~~

class CODE
{
    // -- ATTRIBUTES

    TOKEN[]
        TokenArray;

    // -- CONSTRUCTORS

    this(
        TOKEN[] token_array
        )
    {
        TokenArray = token_array;
    }

    // ~~

    this(
        string text,
        bool parameters_are_parsed
        )
    {
        SetFromText( text, parameters_are_parsed );
    }

    // -- INQUIRIES

    string GetText(
        )
    {
        return TokenArray.GetText();
    }

    // ~~

    void Dump(
        )
    {
        TokenArray.Dump();
    }

    // -- OPERATIONS

    void AddToken(
        TOKEN token
        )
    {
        if ( token.Text.length > 0 )
        {
            TokenArray ~= token;
        }
    }

    // ~~

    void AddTokenArray(
        TOKEN token,
        bool parameters_are_parsed
        )
    {
        char
            character;
        long
            character_index;
        string
            text;
        TOKEN_CONTEXT
            token_context;

        text = token.Text;
        token_context = token.Context;

        if ( text.length > 0 )
        {
            token = new TOKEN( "", token_context );

            for ( character_index = 0;
                  character_index < text.length;
                  ++character_index )
            {
                character = text[ character_index ];

                if ( token.IsBlank()
                     && character.IsBlankCharacter() )
                {
                    token.Text ~= character;
                }
                else if ( token.IsIdentifier()
                          && character.IsIdentifierCharacter() )
                {
                    token.Text ~= character;
                }
                else if ( token.IsParameter()
                          && character == '}'
                          && character_index + 1 < text.length
                          && text[ character_index + 1 ] == '}' )
                {
                    token.Text ~= "}}";

                    AddToken( token );

                    ++character_index;

                    token = new TOKEN( "", token_context );
                }
                else if ( token.IsParameter() )
                {
                    token.Text ~= character;
                }
                else if ( character.IsBlankCharacter() )
                {
                    AddToken( token );

                    token = new TOKEN( character, token_context, TOKEN_TYPE.Blank );
                }
                else if ( character.IsIdentifierCharacter() )
                {
                    AddToken( token );

                    token = new TOKEN( character, token_context, TOKEN_TYPE.Identifier );
                }
                else if ( parameters_are_parsed
                          && character == '{'
                          && character_index + 1 < text.length
                          && text[ character_index + 1 ] == '{' )
                {
                    AddToken( token );

                    token = new TOKEN( "{{", token_context, TOKEN_TYPE.Parameter );

                    ++character_index;
                }
                else
                {
                    AddToken( token );

                    token = new TOKEN( character, token_context );
                }
            }

            AddToken( token );
        }
    }

    // ~~

    void SetFromText(
        string text,
        bool parameters_are_parsed
        )
    {
        char
            character,
            delimiter_character;
        long
            character_index;
        TOKEN
            token;

        TokenArray = null;

        token = new TOKEN();

        for ( character_index = 0;
              character_index < text.length;
              ++character_index )
        {
            character = text[ character_index ];

            if ( token.Context == TOKEN_CONTEXT.ShortComment )
            {
                if ( character == '\n' )
                {
                    AddTokenArray( token, parameters_are_parsed );

                    token = new TOKEN( "\n" );
                }
                else
                {
                    token.Text ~= character;
                }
            }
            else if ( token.Context == TOKEN_CONTEXT.LongComment )
            {
                if ( character == '*'
                     && character_index + 1 < text.length
                     && text[ character_index + 1 ] == '/' )
                {
                    AddTokenArray( token, parameters_are_parsed );

                    token = new TOKEN( "*/", TOKEN_CONTEXT.LongComment );
                    AddToken( token );

                    token = new TOKEN( "" );

                    ++character_index;
                }
                else
                {
                    token.Text ~= character;
                }
            }
            else if ( token.Context == TOKEN_CONTEXT.String )
            {
                if ( character == delimiter_character )
                {
                    AddTokenArray( token, parameters_are_parsed );

                    token = new TOKEN( delimiter_character, token.Context );
                    AddToken( token );

                    token = new TOKEN( "" );
                }
                else if ( character == '\\'
                          && character + 1 < text.length )
                {
                    AddTokenArray( token, parameters_are_parsed );

                    token = new TOKEN( text[ character_index .. character_index + 2 ], TOKEN_CONTEXT.String );
                    AddToken( token );

                    token = new TOKEN( "", TOKEN_CONTEXT.String );

                    ++character_index;
                }
                else
                {
                    token.Text ~= character;
                }
            }
            else if ( character == '/'
                      && character_index + 1 < text.length
                      && text[ character_index + 1 ] == '/' )
            {
                AddTokenArray( token, parameters_are_parsed );

                token = new TOKEN( "//", TOKEN_CONTEXT.ShortComment );
                AddToken( token );

                token = new TOKEN( "", TOKEN_CONTEXT.ShortComment );

                ++character_index;
            }
            else if ( character == '/'
                      && character_index + 1 < text.length
                      && text[ character_index + 1 ] == '*' )
            {
                AddTokenArray( token, parameters_are_parsed );

                token = new TOKEN( "/*", TOKEN_CONTEXT.LongComment );
                AddToken( token );

                token = new TOKEN( "", TOKEN_CONTEXT.LongComment );
                ++character_index;
            }
            else if ( character == '\''
                      || character == '"'
                      || character == '`' )
            {
                AddTokenArray( token, parameters_are_parsed );

                delimiter_character = character;

                token = new TOKEN( delimiter_character, TOKEN_CONTEXT.String );
                AddToken( token );

                token = new TOKEN( "", TOKEN_CONTEXT.String );
            }
            else
            {
                token.Text ~= character;
            }
        }

        AddTokenArray( token, parameters_are_parsed );
    }

    // ~~

    bool ReplaceDefinitions(
        )
    {
        bool
            match_was_found,
            code_has_changed;
        long
            token_index;
        MATCH
            match;

        code_has_changed = false;

        do
        {
            match_was_found = false;

            for ( token_index = 0;
                  token_index < TokenArray.length;
                  ++token_index )
            {
                match = null;

                foreach ( definition; DefinitionArray )
                {
                    match = definition.GetMatch( TokenArray, token_index );

                    if ( match !is null )
                    {
                        TokenArray
                            = TokenArray[ 0 .. token_index ]
                              ~ match.NewTokenArray
                              ~ TokenArray[ token_index + match.OldTokenArray.length .. $ ];

                        break;
                    }
                }

                if ( match !is null )
                {
                    match_was_found = true;
                    code_has_changed = true;

                    --token_index;
                }
            }
        }
        while ( match_was_found );

        return code_has_changed;
    }
}

// ~~

class MATCH
{
    // -- ATTRIBUTES

    TOKEN[]
        OldTokenArray,
        NewTokenArray;
    CODE[ string ]
        ParameterCodeMap;

    // -- INQUIRIES

    bool HasParameter(
        string parameter_name
        )
    {
        return ( parameter_name in ParameterCodeMap ) !is null;
    }
}

// ~~

class DEFINITION
{
    // -- ATTRIBUTES

    string[]
        OldLineArray,
        NewLineArray;
    CODE
        OldCode,
        NewCode;
    TOKEN[]
        OldTokenArray,
        NewTokenArray;

    // -- INQUIRIES

    void ParseParameter(
        ref string parameter_name,
        ref TOKEN[] parameter_token_array,
        string parameter_text
        )
    {
        string
            parameter_token_text;
        CODE
            parameter_code;

        parameter_code = new CODE( parameter_text[ 2 .. $ - 2 ], false );
        parameter_token_array = parameter_code.TokenArray;

        PackStrings( parameter_token_array );
        EvaluateStrings( parameter_token_array );
        RemoveBlanks( parameter_token_array );

        if ( parameter_token_array.length == 0
             || !parameter_token_array[ 0 ].IsIdentifier() )
        {
            Abort( "Invalid parameter : " ~ parameter_text );
        }

        parameter_name = parameter_token_array[ 0 ].Text;
        parameter_token_array = parameter_token_array[ 1 .. $ ];
    }

    // ~~

    bool MatchesParameter(
        TOKEN[] parameter_token_array,
        TOKEN[] token_array
        )
    {
        bool
            boolean;
        long
            parameter_token_index;
        string
            argument_text;
        TOKEN
            parameter_token;
        TOKEN[]
            expression_token_array;

        for ( parameter_token_index = 0;
              parameter_token_index < parameter_token_array.length;
              ++parameter_token_index )
        {
            parameter_token = parameter_token_array[ parameter_token_index ];

            if ( parameter_token.IsIdentifier() )
            {
                boolean = false;

                if ( ( parameter_token.Text == "HasText"
                       || parameter_token.Text == "HasPrefix"
                       || parameter_token.Text == "HasSuffix"
                       || parameter_token.Text == "HasIdentifier" )
                     && parameter_token_index + 1 < parameter_token_array.length
                     && parameter_token_array[ parameter_token_index + 1 ].IsString() )
                {
                    ++parameter_token_index;

                    argument_text = parameter_token_array[ parameter_token_index ].Text;

                    if ( parameter_token.Text == "HasText" )
                    {
                        boolean = token_array.HasText( argument_text );
                    }
                    else if ( parameter_token.Text == "HasPrefix" )
                    {
                        boolean = token_array.HasPrefix( argument_text );
                    }
                    else if ( parameter_token.Text == "HasSuffix" )
                    {
                        boolean = token_array.HasSuffix( argument_text );
                    }
                    else if ( parameter_token.Text == "HasIdentifier" )
                    {
                        boolean = token_array.HasIdentifier( argument_text );
                    }
                }
                else
                {
                    Abort( "Invalid function : " ~ parameter_token_array[ parameter_token_index .. $ ].GetText() );
                }

                expression_token_array
                    ~= new TOKEN(
                           boolean ? "true" : "false",
                           TOKEN_CONTEXT.Code,
                           TOKEN_TYPE.Identifier
                           );
            }
            else if ( !parameter_token.IsBlank() )
            {
                expression_token_array ~= parameter_token;
            }
        }

        return EvaluateBooleanExpression( expression_token_array.GetText() );
    }

    // ~~

    bool MatchesParameter(
        TOKEN[] parameter_token_array,
        ref TOKEN[] matched_token_array,
        TOKEN[] token_array
        )
    {
        CODE
            parameter_code;

        if ( parameter_token_array.length >= 1
             && parameter_token_array[ 0 ].IsCharacter()
             && parameter_token_array[ 0 ].Text == "$" )
        {
            parameter_token_array = parameter_token_array[ 1 .. $ ];
        }
        else
        {
            if ( GetLevel( token_array ) != 0 )
            {
                return false;
            }

            if ( parameter_token_array.length >= 1
                 && parameter_token_array[ 0 ].IsCharacter()
                 && parameter_token_array[ 0 ].Text == "#" )
            {
                parameter_token_array = parameter_token_array[ 1 .. $ ];

                if ( token_array.EndsStatement() )
                {
                    return false;
                }
            }
        }

        if ( parameter_token_array.length >= 2
             && parameter_token_array[ 0 ].IsCharacter()
             && parameter_token_array[ 0 ].Text == ":" )
        {
            if ( !MatchesParameter( parameter_token_array[ 1 .. $ ], token_array ) )
            {
                return false;
            }

            parameter_token_array = null;
        }

        if ( parameter_token_array.length > 0 )
        {
            Abort( "Invalid parameter : " ~ parameter_token_array.GetText( " " ) );
        }

        matched_token_array = token_array;

        return true;
    }

    // ~~

    TOKEN[] GetNewTokenArray(
        TOKEN[] parameter_token_array,
        TOKEN[] token_array
        )
    {
        long
            argument_count,
            token_index;
        string
            function_name;
        CODE
            parameter_code;
        TOKEN[]
            new_token_array;

        for ( token_index = 0;
              token_index < token_array.length;
              ++token_index )
        {
            new_token_array ~= new TOKEN( token_array[ token_index ] );
        }

        while ( parameter_token_array.length >= 2
                && parameter_token_array[ 0 ].IsCharacter()
                && parameter_token_array[ 0 ].Text == ":"
                && parameter_token_array[ 1 ].IsIdentifier() )
        {
            function_name = parameter_token_array[ 1 ].Text;

            parameter_token_array = parameter_token_array[ 2 .. $ ];

            argument_count = 0;

            while ( argument_count < parameter_token_array.length )
            {
                if ( parameter_token_array[ argument_count ].IsCharacter()
                     && parameter_token_array[ argument_count ].Text == ":" )
                {
                    break;
                }

                ++argument_count;
            }

            if ( function_name == "LowerCase"
                 && argument_count == 0 )
            {
                new_token_array.ConvertToLowerCase();
            }
            else if ( function_name == "UpperCase"
                      && argument_count == 0 )
            {
                new_token_array.ConvertToUpperCase();
            }
            else if ( function_name == "MinorCase"
                      && argument_count == 0 )
            {
                new_token_array.ConvertToMinorCase();
            }
            else if ( function_name == "MajorCase"
                      && argument_count == 0 )
            {
                new_token_array.ConvertToMajorCase();
            }
            else if ( function_name == "SnakeCase"
                      && argument_count == 0 )
            {
                new_token_array.ConvertToSnakeCase();
            }
            else if ( function_name == "PascalCase"
                      && argument_count == 0 )
            {
                new_token_array.ConvertToPascalCase();
            }
            else if ( function_name == "CamelCase"
                      && argument_count == 0 )
            {
                new_token_array.ConvertToCamelCase();
            }
            else if ( function_name == "RemoveComments"
                      && argument_count == 0 )
            {
                new_token_array.RemoveComments();
            }
            else if ( function_name == "RemoveBlanks"
                      && argument_count == 0 )
            {
                new_token_array.RemoveBlanks();
            }
            else if ( function_name == "PackStrings"
                      && argument_count == 0 )
            {
                new_token_array.PackStrings();
            }
            else if ( function_name == "PackIdentifiers"
                      && argument_count == 0 )
            {
                new_token_array.PackIdentifiers();
            }
            else if ( function_name == "ReplaceText"
                      && argument_count == 0 )
            {
                new_token_array.RemoveComments();
            }
            else if ( function_name == "RemoveComments"
                      && argument_count == 0 )
            {
                new_token_array.RemoveComments();
            }
            else if ( function_name == "ReplaceText"
                      && argument_count == 2
                      && parameter_token_array[ 0 ].IsString()
                      && parameter_token_array[ 1 ].IsString() )
            {
                new_token_array.ReplaceText(
                    parameter_token_array[ 0 ].Text,
                    parameter_token_array[ 1 ].Text
                    );
            }
            else if ( function_name == "ReplacePrefix"
                      && argument_count == 2
                      && parameter_token_array[ 0 ].IsString()
                      && parameter_token_array[ 1 ].IsString() )
            {
                new_token_array.ReplacePrefix(
                    parameter_token_array[ 0 ].Text,
                    parameter_token_array[ 1 ].Text
                    );
            }
            else if ( function_name == "ReplaceSuffix"
                      && argument_count == 2
                      && parameter_token_array[ 0 ].IsString()
                      && parameter_token_array[ 1 ].IsString() )
            {
                new_token_array.ReplaceSuffix(
                    parameter_token_array[ 0 ].Text,
                    parameter_token_array[ 1 ].Text
                    );
            }
            else if ( function_name == "ReplaceIdentifier"
                      && argument_count == 2
                      && parameter_token_array[ 0 ].IsString()
                      && parameter_token_array[ 1 ].IsString() )
            {
                new_token_array.ReplaceIdentifier(
                    parameter_token_array[ 0 ].Text,
                    parameter_token_array[ 1 ].Text
                    );
            }
            else if ( function_name == "RemoveText"
                      && argument_count == 1
                      && parameter_token_array[ 0 ].IsString() )
            {
                new_token_array.RemoveText(
                    parameter_token_array[ 0 ].Text
                    );
            }
            else if ( function_name == "RemovePrefix"
                      && argument_count == 1
                      && parameter_token_array[ 0 ].IsString() )
            {
                new_token_array.RemovePrefix(
                    parameter_token_array[ 0 ].Text
                    );
            }
            else if ( function_name == "RemoveSuffix"
                      && argument_count == 1
                      && parameter_token_array[ 0 ].IsString() )
            {
                new_token_array.RemoveSuffix(
                    parameter_token_array[ 0 ].Text
                    );
            }
            else if ( function_name == "RemoveIdentifier"
                      && argument_count == 1
                      && parameter_token_array[ 0 ].IsString() )
            {
                new_token_array.RemoveIdentifier(
                    parameter_token_array[ 0 ].Text
                    );
            }
            else
            {
                Abort( "Invalid function call : " ~ function_name ~ parameter_token_array[ 0 .. argument_count ].GetText( " " ) );
            }

            parameter_token_array = parameter_token_array[ argument_count .. $ ];
        }

        if ( parameter_token_array.length > 0 )
        {
            Abort( "Invalid parameter : " ~ parameter_token_array.GetText( " " ) );
        }

        return new_token_array;
    }

    // ~~

    MATCH GetMatch(
        TOKEN[] token_array,
        long token_index
        )
    {
        long
            matched_token_count,
            matched_token_index,
            next_old_token_index,
            next_token_index,
            old_token_index;
        string
            parameter_name;
        CODE
            parameter_code;
        MATCH
            match;
        TOKEN
            next_old_token,
            next_token,
            old_token,
            token;
        TOKEN[]
            matched_token_array,
            parameter_token_array;

        match = new MATCH();

        old_token_index = 0;

        while ( old_token_index < OldTokenArray.length
                && token_index < token_array.length )
        {
            old_token = OldTokenArray[ old_token_index ];
            token = token_array[ token_index ];

            if ( old_token.IsParameter() )
            {
                ParseParameter( parameter_name, parameter_token_array, old_token.Text );

                next_old_token_index = old_token_index + 1;
                matched_token_count = 0;

                while ( next_old_token_index + matched_token_count < OldTokenArray.length
                        && !OldTokenArray[ next_old_token_index + matched_token_count ].IsParameter() )
                {
                    ++matched_token_count;
                }

                matched_token_index = 0;
                next_token_index = token_index;

                while ( next_token_index < token_array.length )
                {
                    matched_token_index = 0;

                    while ( matched_token_index < matched_token_count
                            && next_token_index + matched_token_index < token_array.length
                            && next_old_token_index + matched_token_index < OldTokenArray.length )
                    {
                        next_token = token_array[ next_token_index + matched_token_index ];
                        next_old_token = OldTokenArray[ next_old_token_index + matched_token_index ];

                        if ( next_token.Matches( next_old_token ) )
                        {
                            ++matched_token_index;
                        }
                        else
                        {
                            break;
                        }
                    }

                    if ( matched_token_index == matched_token_count
                         && MatchesParameter( parameter_token_array, matched_token_array, token_array[ token_index .. next_token_index ] ) )
                    {
                        break;
                    }
                    else
                    {
                        ++next_token_index;
                    }
                }

                if ( matched_token_index == matched_token_count )
                {
                    if ( match.HasParameter( parameter_name ) )
                    {
                        writeln( OldCode.GetText() );

                        Abort( "Duplicate parameter : {{" ~ parameter_name ~ "}}" );
                    }

                    match.OldTokenArray ~= matched_token_array;
                    match.ParameterCodeMap[ parameter_name ] = new CODE( matched_token_array );

                    old_token_index = next_old_token_index;
                    token_index = next_token_index;
                }
                else
                {
                    return null;
                }
            }
            else if ( token.Matches( old_token ) )
            {
                match.OldTokenArray ~= token;

                ++old_token_index;
                ++token_index;
            }
            else
            {
                return null;
            }
        }

        if ( old_token_index == OldTokenArray.length )
        {
            foreach ( new_token; NewTokenArray )
            {
                if ( new_token.IsParameter() )
                {
                    ParseParameter( parameter_name, parameter_token_array, new_token.Text );

                    if ( !match.HasParameter( parameter_name ) )
                    {
                        writeln( OldCode.GetText() );
                        writeln( NewCode.GetText() );

                        Abort( "Missing parameter : {{" ~ parameter_name ~ "}}" );
                    }

                    parameter_code = match.ParameterCodeMap[ parameter_name ];

                    match.NewTokenArray ~= GetNewTokenArray( parameter_token_array, parameter_code.TokenArray );
                }
                else
                {
                    match.NewTokenArray ~= new_token;
                }
            }

            return match;
        }
        else
        {
            return null;
        }
    }

    // ~~

    void Dump(
        )
    {
        writeln( OldCode.GetText() );
        writeln( NewCode.GetText() );
    }

    // -- OPERATIONS

    void Parse(
        )
    {
        OldCode = new CODE( OldLineArray.join( '\n' ), true );
        NewCode = new CODE( NewLineArray.join( '\n' ), true );

        OldTokenArray = OldCode.TokenArray;
        NewTokenArray = NewCode.TokenArray;
    }
}

// ~~

class FILE
{
    // -- ATTRIBUTES

    string
        InputPath,
        OutputPath;
    bool
        Exists,
        HasChanged,
        IsProcessed;
    SysTime
        SystemTime;
    bool
        UsesCarriageReturn;
    string
        Text;
    string[]
        LineArray;

    // -- CONSTRUCTORS

    this(
        string input_file_path,
        string output_file_path
        )
    {
        InputPath = input_file_path;
        OutputPath = output_file_path;
        Exists = true;
        HasChanged = true;
        IsProcessed = true;
    }

    // -- INQUIRIES

    void AbortFile(
        string message
        )
    {
        Abort( "[" ~ InputPath ~ "] " ~ message );
    }

    // -- OPERATIONS

    void CheckChange(
        bool modification_time_is_used
        )
    {
        SysTime
            old_system_time;

        if ( modification_time_is_used )
        {
            HasChanged = true;
        }
        else
        {
            old_system_time = SystemTime;
            SystemTime = InputPath.timeLastModified();
            HasChanged = ( SystemTime > old_system_time );
        }

        IsProcessed
            = ( HasChanged
                || ( OutputPath != ""
                     && ( !OutputPath.exists()
                          || InputPath.timeLastModified() > OutputPath.timeLastModified() ) ) );
    }

    // ~~

    void ReadInputFile(
        )
    {
        if ( HasChanged )
        {
            writeln( "Reading file : ", InputPath );

            try
            {
                Text = InputPath.readText();
            }
            catch ( FileException file_exception )
            {
                Abort( "Can't read file : " ~ InputPath, file_exception );
            }

            UsesCarriageReturn = ( Text.indexOf( '\r' ) >= 0 );

            if ( UsesCarriageReturn )
            {
                Text = Text.replace( "\r", "" );
            }

            Text = Text.replace( "\t", GetSpaceText( TabulationSpaceCount ) );
        }

        LineArray = null;
    }

    // ~~

    void ParseDefinitions(
        )
    {
        long
            command_space_count,
            level,
            line_index,
            space_count,
            state;
        string
            line,
            stripped_line;
        string[]
            line_array;
        DEFINITION
            definition;

        LineArray = Text.split( '\n' );

        for ( line_index = 0;
              line_index < LineArray.length;
              ++line_index )
        {
            line = LineArray[ line_index ].stripRight();
            stripped_line = line.stripLeft();

            if ( stripped_line == "#define"
                 || stripped_line.startsWith( "#define " ) )
            {
                command_space_count = GetSpaceCount( line );

                ++line_index;

                definition = new DEFINITION();

                if ( stripped_line.startsWith( "#define " ) )
                {
                    definition.OldLineArray ~= stripped_line[ 8 .. $ ].strip();
                }

                while ( line_index < LineArray.length )
                {
                    line = LineArray[ line_index ].stripRight();
                    stripped_line = line.stripLeft();

                    if ( stripped_line == "#as"
                         || stripped_line.startsWith( "#as " ) )
                    {
                        break;
                    }
                    else
                    {
                        definition.OldLineArray ~= line.RemoveSpaceCount( command_space_count + TabulationSpaceCount );
                    }

                    ++line_index;
                }

                if ( line_index == LineArray.length )
                {
                    Dump( LineArray );

                    AbortFile( "Missing #as for #define" );
                }

                ++line_index;


                if ( stripped_line.startsWith( "#as " ) )
                {
                    definition.NewLineArray ~= stripped_line[ 4 .. $ ].strip();
                }
                else
                {
                    command_space_count = GetSpaceCount( line );

                    level = 0;

                    while ( line_index < LineArray.length )
                    {
                        line = LineArray[ line_index ].stripRight();
                        stripped_line = line.stripLeft();

                        if ( stripped_line.IsOpeningCommand() )
                        {
                            ++level;
                        }

                        if ( stripped_line == "#end"
                             && level == 0 )
                        {
                            break;
                        }
                        else
                        {
                            definition.NewLineArray ~= line.RemoveSpaceCount( command_space_count + TabulationSpaceCount );

                            if ( stripped_line == "#end" )
                            {
                                --level;

                                if ( level < 0 )
                                {
                                    Dump( LineArray[ 0 .. line_index + 1 ] );

                                    AbortFile( "Invalid #end" );
                                }
                            }
                        }

                        ++line_index;
                    }

                    if ( line_index == LineArray.length )
                    {
                        Dump( LineArray );

                        AbortFile( "Missing #end for #define" );
                    }
                }

                definition.Parse();

                DefinitionArray ~= definition;
            }
            else
            {
                line_array ~= line;
            }
        }

        LineArray = line_array;
    }

    // ~~

    void ApplyDefinitions(
        )
    {
        CODE
            code;

        code = new CODE( LineArray.join( '\n' ), false );

        if ( code.ReplaceDefinitions() )
        {
            LineArray = code.GetText().split( '\n' );
        }
    }

    // ~~

    void ApplyConditions(
        )
    {
        bool
            condition;
        long
            end_line_index,
            level,
            line_index;
        string
            line,
            stripped_line;
        string[]
            condition_line_array;

        for ( line_index = 0;
              line_index < LineArray.length;
              ++line_index )
        {
            line = LineArray[ line_index ].stripRight();
            stripped_line = line.stripLeft();

            if ( stripped_line.startsWith( "#if " ) )
            {
                condition = stripped_line[ 4 .. $ ].EvaluateBooleanExpression();
                level = 0;

                end_line_index = line_index + 1;

                condition_line_array = null;

                while ( end_line_index < LineArray.length )
                {
                    line = LineArray[ end_line_index ].stripRight();
                    stripped_line = line.stripLeft();

                    if ( stripped_line.IsOpeningCommand() )
                    {
                        ++level;
                    }

                    if ( stripped_line == "#end"
                         && level == 0 )
                    {
                        break;
                    }
                    else
                    {
                        if ( stripped_line == "#else"
                             && level == 0 )
                        {
                            condition = !condition;
                        }
                        else if ( condition )
                        {
                            condition_line_array ~= line.RemoveSpaceCount( TabulationSpaceCount );
                        }

                        if ( stripped_line == "#end" )
                        {
                            --level;

                            if ( level < 0 )
                            {
                                Dump( LineArray[ 0 .. end_line_index + 1 ] );

                                AbortFile( "Invalid #end" );
                            }
                        }
                    }

                    ++end_line_index;
                }

                if ( end_line_index == LineArray.length )
                {
                    Dump( LineArray );

                    AbortFile( "Missing #end for #if" );
                }

                LineArray
                    = LineArray[ 0 .. line_index ]
                      ~ condition_line_array
                      ~ LineArray[ end_line_index + 1 .. $ ];

                --line_index;
            }
        }
    }

    // ~~

    string GetTemplateText(
        string[] template_line_array,
        string writer_expression,
        long space_count
        )
    {
        char
            character,
            next_character;
        long
            character_index,
            first_character_index,
            state;
        string
            empty_string_writer_line,
            string_writer_prefix,
            string_writer_suffix,
            text,
            writer_prefix,
            writer_suffix,
            writer_text;
        string[]
            writer_line_array;

        if ( template_line_array.length > 0 )
        {
            writer_prefix = GetSpaceText( space_count ) ~ "io.WriteString( " ~ writer_expression ~ ", ";
            writer_suffix = " );";

            string_writer_prefix = writer_prefix ~ "\"";
            string_writer_suffix = "\"" ~ writer_suffix;

            text = template_line_array.join( '\n' );
            writer_line_array ~= string_writer_prefix;

            for ( character_index = 0;
                  character_index < text.length;
                  ++character_index )
            {
                character = text[ character_index ];

                if ( character_index + 2 < text.length
                     && character == '<'
                     && text[ character_index + 1 ] == '%'
                     && text[ character_index + 2 ] != '!' )
                {
                    writer_line_array[ $ - 1 ] ~= string_writer_suffix;

                    character_index += 2;

                    first_character_index = character_index;

                    while ( character_index < text.length )
                    {
                        if ( text[ character_index ] == '%'
                             && character_index + 1 < text.length
                             && text[ character_index + 1 ] == '>' )
                        {
                            break;
                        }
                        else
                        {
                            ++character_index;
                        }
                    }

                    if ( character_index == text.length )
                    {
                        writeln( text );

                        AbortFile( "Missing %>" );
                    }

                    writer_text = text[ first_character_index .. character_index ];

                    ++character_index;

                    if ( writer_text.startsWith( '@' ) )
                    {
                        writer_line_array
                            ~= writer_prefix
                               ~ "strconv.FormatUint( uint64( "
                               ~ writer_text[ 1 .. $ ].strip()
                               ~ " ), 10 )"
                               ~ writer_suffix;
                    }
                    else if ( writer_text.startsWith( '#' ) )
                    {
                        writer_line_array
                            ~= writer_prefix
                               ~ "strconv.FormatInt( int64( "
                               ~ writer_text[ 1 .. $ ].strip()
                               ~ " ), 10 )"
                               ~ writer_suffix;
                    }
                    else if ( writer_text.startsWith( '&' ) )
                    {
                        writer_line_array
                            ~= writer_prefix
                               ~ "strconv.FormatFloat( float64( "
                               ~ writer_text[ 1 .. $ ].strip()
                               ~ " ), 'f', -1, 64 )"
                               ~ writer_suffix;
                    }
                    else if ( writer_text.startsWith( '=' ) )
                    {
                        writer_line_array
                            ~= writer_prefix
                               ~ writer_text[ 1 .. $ ].strip()
                               ~ writer_suffix;
                    }
                    else if ( writer_text.startsWith( '~' ) )
                    {
                        writer_line_array
                            ~= writer_prefix
                               ~ "html.EscapeString( "
                               ~ writer_text[ 1 .. $ ].strip()
                               ~ " )"
                               ~ writer_suffix;
                    }
                    else
                    {
                        writer_line_array ~= writer_text;
                    }

                    writer_line_array ~= string_writer_prefix;
                }
                else
                {
                    if ( character == '"' )
                    {
                        writer_line_array[ $ - 1 ] ~= "\\\"";
                    }
                    else if ( character == '\n' )
                    {
                        writer_line_array[ $ - 1 ] ~= "\\n";
                    }
                    else
                    {
                        writer_line_array[ $ - 1 ] ~= character;
                    }
                }
            }

            writer_line_array[ $ - 1 ] ~= string_writer_suffix;
        }

        empty_string_writer_line = string_writer_prefix ~ string_writer_suffix;
        template_line_array = null;

        foreach ( writer_line; writer_line_array )
        {
            if ( writer_line != empty_string_writer_line )
            {
                template_line_array ~= writer_line;
            }
        }

        return template_line_array.join( '\n' ).replace( "<\\%", "<%" ).replace( "%\\>", "%>" );
    }

    // ~~

    void ApplyTemplates(
        )
    {
        long
            line_index,
            space_count;
        string
            line,
            stripped_line,
            template_text,
            writer_expression;
        string[]
            line_array,
            template_line_array;

        for ( line_index = 0;
              line_index < LineArray.length;
              ++line_index )
        {
            line = LineArray[ line_index ].stripRight();
            stripped_line = line.stripLeft();

            if ( stripped_line.startsWith( "#write " ) )
            {
                writer_expression = stripped_line[ 7 .. $ ].strip();

                if ( writer_expression == "" )
                {
                    Dump( LineArray[ 0 .. line_index ] );

                    AbortFile( "Missing writer expression" );
                }

                ++line_index;

                space_count = GetSpaceCount( line );

                while ( line_index < LineArray.length )
                {
                    line = LineArray[ line_index ].stripRight().RemoveSpaceCount( space_count + TabulationSpaceCount );
                    stripped_line = line.stripLeft();

                    if ( stripped_line == "#end" )
                    {
                        break;
                    }
                    else
                    {
                        template_line_array ~= line;
                    }

                    ++line_index;
                }

                if ( line_index == LineArray.length )
                {
                    Dump( LineArray );

                    AbortFile( "Missing #end for #write" );
                }

                template_text = GetTemplateText( template_line_array, writer_expression, space_count );

                line_array ~= template_text;
            }
            else
            {
                line_array ~= line;
            }
        }

        LineArray = line_array;
    }

    // ~~

    void SplitLines(
        )
    {
        long
            line_index;

        LineArray = LineArray.join( '\n' ).split( '\n' );

        for ( line_index = 0;
              line_index < LineArray.length;
              ++line_index )
        {
            LineArray[ line_index ] = LineArray[ line_index ].stripRight();
        }
    }

    // ~~

    void JoinStatements(
        )
    {
        char
            line_first_character,
            line_last_character,
            next_line_first_character,
            prior_line_last_character;
        long
            line_index;
        string
            line,
            line_first_characters,
            next_stripped_line,
            prior_stripped_line,
            stripped_line;

        if ( JoinOptionIsEnabled )
        {
            SplitLines();

            line_index = 0;

            while ( line_index < LineArray.length )
            {
                line = LineArray[ line_index ];
                stripped_line = line.strip();

                if ( stripped_line != "" )
                {
                    line_first_character = stripped_line[ 0 ];

                    if ( stripped_line.length >= 2 )
                    {
                        line_first_characters = stripped_line[ 0 .. 2 ];
                    }
                    else
                    {
                        line_first_characters = stripped_line[ 0 .. 1 ];
                    }

                    line_last_character = stripped_line[ $ - 1 ];

                    if ( line_index > 0
                         && "{)]+-*/%&|^<>=!:.".indexOf( line_first_character ) >= 0
                         && line_first_characters != "--"
                         && line_first_characters != "++"
                         && line_first_characters != "/*"
                         && line_first_characters != "*/"
                         && line_first_characters != "//" )
                    {
                        prior_stripped_line = stripRight( LineArray[ line_index - 1 ] );

                        if ( prior_stripped_line.length > 0 )
                        {
                            prior_line_last_character = prior_stripped_line[ $ - 1 ];
                        }
                        else
                        {
                            prior_line_last_character = 0;
                        }

                        if ( !HasEndingComment( prior_stripped_line )
                             && prior_stripped_line != ""
                             && ( "{};".indexOf( prior_line_last_character ) < 0
                                  || ( prior_line_last_character == '}'
                                       && ")]".indexOf( line_first_character ) >= 0 ) ) )
                        {
                            LineArray[ line_index - 1 ] = prior_stripped_line ~ " " ~ stripped_line;
                            LineArray = LineArray[ 0 .. line_index ] ~ LineArray[ line_index + 1 .. $ ];

                            --line_index;

                            continue;
                        }
                    }

                    if ( line_index + 1 < LineArray.length )
                    {
                        next_stripped_line = LineArray[ line_index + 1 ].strip();

                        if ( next_stripped_line.length > 0 )
                        {
                            next_line_first_character = next_stripped_line[ 0 ];
                        }
                        else
                        {
                            next_line_first_character = 0;
                        }

                        if ( "([,".indexOf( line_last_character ) >= 0
                             || ( line_first_characters != "//"
                                  && "};,".indexOf( line_last_character ) < 0
                                  && next_line_first_character == '}' )
                             || stripped_line == "return"
                             || stripped_line == "var"
                             || ( stripped_line == "}"
                                  && ( next_stripped_line == "else"
                                       || next_stripped_line.startsWith( "else " ) ) ) )
                        {
                            stripped_line = stripRight( LineArray[ line_index ] );

                            if ( !HasEndingComment( stripped_line ) )
                            {
                                LineArray[ line_index ] = stripped_line ~ " " ~ next_stripped_line;
                                LineArray = LineArray[ 0 .. line_index + 1 ] ~ LineArray[ line_index + 2 .. $ ];

                                continue;
                            }
                        }
                    }
                }

                ++line_index;
            }
        }
    }

    // ~~

    void CreateOutputFolder(
        )
    {
        string
            output_folder_path;

        output_folder_path = OutputPath.dirName();

        if ( !output_folder_path.exists() )
        {
            writeln( "Creating folder : ", output_folder_path );

            try
            {
                if ( output_folder_path != ""
                     && output_folder_path != "/"
                     && !output_folder_path.exists() )
                {
                    output_folder_path.mkdirRecurse();
                }
            }
            catch ( FileException file_exception )
            {
                Abort( "Can't create folder : " ~ output_folder_path, file_exception );
            }
        }
    }

    // ~~

    void WriteOutputFile(
        )
    {
        string
            output_text;

        if ( CreateOptionIsEnabled )
        {
            CreateOutputFolder();
        }

        writeln( "Writing file : ", OutputPath );

        if ( UsesCarriageReturn )
        {
            output_text = LineArray.join( "\r\n" );
        }
        else
        {
            output_text = LineArray.join( "\n" );
        }

        try
        {
            OutputPath.write( output_text );
        }
        catch ( FileException file_exception )
        {
            Abort( "Can't write file : " ~ OutputPath, file_exception );
        }
    }
}

// -- VARIABLES

bool
    CreateOptionIsEnabled,
    JoinOptionIsEnabled,
    WatchOptionIsEnabled;
string
    SpaceText;
string[]
    InputFolderPathArray,
    OutputFolderPathArray;
long
    PauseDuration,
    TabulationSpaceCount;
FILE[ string ]
    FileMap;
DEFINITION[]
    DefinitionArray;

// -- FUNCTIONS

void PrintError(
    string message
    )
{
    writeln( "*** ERROR : ", message );
}

// ~~

void Abort(
    string message
    )
{
    PrintError( message );

    exit( -1 );
}

// ~~

void Abort(
    string message,
    FileException file_exception
    )
{
    PrintError( message );
    PrintError( file_exception.msg );

    exit( -1 );
}

// ~~

void Dump(
    string[] line_array
    )
{
    writeln( line_array.join( '\n' ) );
}

// ~~

bool IsBlankCharacter(
    char character
    )
{
    return
        character == ' '
        || character == '\t'
        || character == '\r'
        || character == '\n';
}

// ~~

bool IsIdentifierCharacter(
    char character
    )
{
    return
        ( character >= 'a' && character <= 'z' )
        || ( character >= 'A' && character <= 'Z' )
        || ( character >= '0' && character <= '9' )
        || character == '_';
}

// ~~

string GetMinorCaseText(
    string text
    )
{
    return text[ 0 .. 1 ].toLower() ~ text[ 1 .. $ ];
}

// ~~

string GetMajorCaseText(
    string text
    )
{
    return text[ 0 .. 1 ].toUpper() ~ text[ 1 .. $ ];
}

// ~~

string GetSnakeCaseText(
    string text
    )
{
    char
        character,
        prior_character;
    string
        snake_case_text;

    snake_case_text = "";
    character = 0;

    foreach ( character_index; 0 .. text.length )
    {
        prior_character = character;
        character = text[ character_index ];

        if ( ( ( prior_character >= 'a' && prior_character <= 'z' )
               && ( ( character >= 'A' && character <= 'Z' )
                    || ( character >= '0' && character <= '9' ) ) )
             || ( ( prior_character >= '0' && prior_character <= '9' )
                  && ( ( character >= 'a' && character <= 'z' )
                       || ( character >= 'A' && character <= 'Z' ) ) ) )
        {
            snake_case_text ~= '_';
        }

        snake_case_text ~= character;
    }

    return snake_case_text.toLower();
}

// ~~

string GetPascalCaseText(
    string text
    )
{
    string[]
        word_array;

    word_array = text.toLower().split( '_' );

    foreach ( ref word; word_array )
    {
        word = word.GetMajorCaseText();
    }

    return word_array.join( "" );
}

// ~~

string GetCamelCaseText(
    string text
    )
{
    return text.GetPascalCaseText().GetMinorCaseText();
}

// ~~

void ReplacePrefix(
    ref string text,
    string old_prefix,
    string new_prefix
    )
{
    if ( text.startsWith( old_prefix ) )
    {
        text = new_prefix ~ text[ old_prefix.length .. $ ];
    }
}

// ~~

void ReplaceSuffix(
    ref string text,
    string old_suffix,
    string new_suffix
    )
{
    if ( text.endsWith( old_suffix ) )
    {
        text = text[ 0 .. $ - old_suffix.length ] ~ new_suffix;
    }
}

// ~~

void ReplaceText(
    ref string text,
    string old_text,
    string new_text
    )
{
    text = text.replace( old_text, new_text );
}

// ~~

long GetSpaceCount(
    string text
    )
{
    long
        space_count;

    space_count = 0;

    while ( space_count < text.length
            && text[ space_count ] == ' ' )
    {
        ++space_count;
    }

    return space_count;
}

// ~~

string RemoveSpaceCount(
    string text,
    long space_count
    )
{
    long
        space_index;

    while ( space_index < space_count
            && space_index < text.length
            && text[ space_index ] == ' ' )
    {
        ++space_index;
    }

    return text[ space_index .. $ ];
}

// ~~

string GetSpaceText(
    long space_count
    )
{
    if ( space_count <= 0 )
    {
        return "";
    }
    else
    {
        while ( SpaceText.length < space_count )
        {
            SpaceText ~= SpaceText;
        }

        return SpaceText[ 0 .. space_count ];
    }
}

// ~~

string GetLogicalPath(
    string path
    )
{
    return path.replace( "\\", "/" );
}

// ~~

string[] GetWordArray(
    string text,
    string separator
    )
{
    char
        character,
        state;
    long
        character_index;
    string[]
        word_array;

    word_array = [ "" ];
    state = 0;

    for ( character_index = 0;
          character_index < text.length;
          ++character_index )
    {
        character = text[ character_index ];

        if ( character == separator[ 0 ]
             && character_index + separator.length <= text.length
             && text[ character_index .. character_index + separator.length ] == separator )
        {
            word_array ~= "";
        }
        else
        {
            word_array[ word_array.length.to!long() - 1 ] ~= character;

            if ( "'\"`".indexOf( character ) >= 0 )
            {
                if ( state == 0 )
                {
                    state = character;
                }
                else if ( character == state )
                {
                    state = 0;
                }

            }
            else if ( character == '\\'
                      && character_index + 1 < text.length
                      && state != 0 )
            {
                ++character_index;

                word_array[ word_array.length.to!long() - 1 ] ~= text[ character_index ];
            }
        }
    }

    return word_array;
}

// ~~

bool HasEndingComment(
    string text
    )
{
    string[]
        word_array;

    word_array = GetWordArray( text, "//" );

    return word_array.length > 1;
}

// ~~

bool IsOpeningCommand(
    string stripped_line
    )
{
    return
        stripped_line == "#as"
        || stripped_line.startsWith( "#if " );
}

// ~~

string GetText(
    TOKEN[] token_array,
    string delimiter_text = ""
    )
{
    string
        text;

    foreach ( token_index, token; token_array )
    {
        if ( token_index > 0
             && delimiter_text.length > 0 )
        {
            text ~= delimiter_text;
        }

        text ~= token.Text;
    }

    return text;
}

// ~~

bool HasText(
    TOKEN[] token_array,
    string text
    )
{
    return token_array.GetText().indexOf( text ) >= 0;
}

// ~~

bool HasPrefix(
    TOKEN[] token_array,
    string prefix
    )
{
    return token_array.GetText().startsWith( prefix );
}

// ~~

bool HasSuffix(
    TOKEN[] token_array,
    string suffix
    )
{
    return token_array.GetText().startsWith( suffix );
}

// ~~

bool HasIdentifier(
    TOKEN[] token_array,
    string identifier
    )
{
    foreach ( token; token_array )
    {
        if ( token.IsIdentifier()
             && token.Text == identifier )
        {
            return true;
        }
    }

    return false;
}

// ~~

void RemoveComments(
    ref TOKEN[] token_array
    )
{
    long
        token_index;
    TOKEN
        token;
    TOKEN[]
        new_token_array;

    for ( token_index = 0;
          token_index < token_array.length;
          ++token_index )
    {
        token = token_array[ token_index ];

        if ( !token.IsComment() )
        {
            new_token_array ~= token;
        }
    }

    token_array = new_token_array;
}

// ~~

void RemoveBlanks(
    ref TOKEN[] token_array
    )
{
    long
        token_index;
    TOKEN
        token;
    TOKEN[]
        new_token_array;

    for ( token_index = 0;
          token_index < token_array.length;
          ++token_index )
    {
        token = token_array[ token_index ];

        if ( !token.IsBlank()
             || !token.IsCode() )
        {
            new_token_array ~= token;
        }
    }

    token_array = new_token_array;
}

// ~~

void PackStrings(
    ref TOKEN[] token_array
    )
{
    long
        token_index;
    string
        delimiter_text;
    TOKEN
        token;
    TOKEN[]
        new_token_array;

    for ( token_index = 0;
          token_index < token_array.length;
          ++token_index )
    {
        token = token_array[ token_index ];

        if ( token.IsStringDelimiter() )
        {
            delimiter_text = token.Text;

            while ( token_index + 1 < token_array.length
                    && token_array[ token_index + 1 ].IsString() )
            {
                token.Type = TOKEN_TYPE.Literal;

                ++token_index;

                token.Text ~= token_array[ token_index ].Text;

                if ( token_array[ token_index ].Text == delimiter_text )
                {
                    break;
                }
            }
        }

        new_token_array ~= token;
    }

    token_array = new_token_array;
}

// ~~

void EvaluateStrings(
    ref TOKEN[] token_array
    )
{
    long
        token_index;
    string
        delimiter_text;

    foreach ( token; token_array )
    {
        if ( token.IsString() )
        {
            token.Text = token.Text[ 1 .. $ - 1 ];
            token.Type = TOKEN_TYPE.Value;
        }
    }
}

// ~~

void PackIdentifiers(
    ref TOKEN[] token_array
    )
{
    long
        token_index;
    TOKEN
        token;
    TOKEN[]
        new_token_array;

    for ( token_index = 0;
          token_index < token_array.length;
          ++token_index )
    {
        token = token_array[ token_index ];

        if ( token.IsIdentifier() )
        {
            while ( token_index + 1 < token_array.length
                    && token_array[ token_index + 1 ].IsIdentifier() )
            {
                ++token_index;

                token.Text ~= token_array[ token_index ].Text;
            }
        }

        new_token_array ~= token;
    }

    token_array = new_token_array;
}

// ~~

void ConvertToLowerCase(
    ref TOKEN[] token_array
    )
{
    foreach ( token; token_array )
    {
        if ( token.IsIdentifier() )
        {
            token.Text = token.Text.toLower();
        }
    }
}

// ~~

void ConvertToUpperCase(
    ref TOKEN[] token_array
    )
{
    foreach ( token; token_array )
    {
        if ( token.IsIdentifier() )
        {
            token.Text = token.Text.toUpper();
        }
    }
}

// ~~

void ConvertToMinorCase(
    ref TOKEN[] token_array
    )
{
    foreach ( token; token_array )
    {
        if ( token.IsIdentifier() )
        {
            token.Text = token.Text.GetMinorCaseText();
        }
    }
}

// ~~

void ConvertToMajorCase(
    ref TOKEN[] token_array
    )
{
    foreach ( token; token_array )
    {
        if ( token.IsIdentifier() )
        {
            token.Text = token.Text.GetMajorCaseText();
        }
    }
}

// ~~

void ConvertToSnakeCase(
    ref TOKEN[] token_array
    )
{
    foreach ( token; token_array )
    {
        if ( token.IsIdentifier() )
        {
            token.Text = token.Text.GetSnakeCaseText();
        }
    }
}

// ~~

void ConvertToPascalCase(
    ref TOKEN[] token_array
    )
{
    foreach ( token; token_array )
    {
        if ( token.IsIdentifier() )
        {
            token.Text = token.Text.GetPascalCaseText();
        }
    }
}

// ~~

void ConvertToCamelCase(
    ref TOKEN[] token_array
    )
{
    foreach ( token; token_array )
    {
        if ( token.IsIdentifier() )
        {
            token.Text = token.Text.GetCamelCaseText();
        }
    }
}

// ~~

void ReplacePrefix(
    ref TOKEN[] token_array,
    string old_prefix,
    string new_prefix
    )
{
    if ( token_array.length > 0
         && token_array[ 0 ].IsIdentifier() )
    {
        ReplacePrefix( token_array[ 0 ].Text, old_prefix, new_prefix );
    }
}

// ~~

void ReplaceSuffix(
    ref TOKEN[] token_array,
    string old_suffix,
    string new_suffix
    )
{
    if ( token_array.length > 0
         && token_array[ 0 ].IsIdentifier() )
    {
        ReplaceSuffix( token_array[ 0 ].Text, old_suffix, new_suffix );
    }
}

// ~~

void ReplaceText(
    ref TOKEN[] token_array,
    string old_text,
    string new_text
    )
{
    foreach ( token; token_array )
    {
        ReplaceText( token.Text, old_text, new_text );
    }
}

// ~~

void ReplaceIdentifier(
    ref TOKEN[] token_array,
    string old_identifier,
    string new_identifier
    )
{
    foreach ( token; token_array )
    {
        if ( token.IsIdentifier()
             && token.Text == old_identifier )
        {
            token.Text = new_identifier;
        }
    }
}

// ~~

void RemovePrefix(
    ref TOKEN[] token_array,
    string prefix
    )
{
    if ( token_array.length > 0
         && token_array[ 0 ].IsIdentifier() )
    {
        ReplacePrefix( token_array[ 0 ].Text, prefix, "" );
    }
}

// ~~

void RemoveSuffix(
    ref TOKEN[] token_array,
    string suffix
    )
{
    if ( token_array.length > 0
         && token_array[ 0 ].IsIdentifier() )
    {
        ReplaceSuffix( token_array[ 0 ].Text, suffix, "" );
    }
}

// ~~

void RemoveText(
    ref TOKEN[] token_array,
    string text
    )
{
    foreach ( token; token_array )
    {
        ReplaceText( token.Text, text, "" );
    }
}

// ~~

void RemoveIdentifier(
    ref TOKEN[] token_array,
    string identifier
    )
{
    TOKEN[]
        new_token_array;

    foreach ( token; token_array )
    {
        if ( !token.IsIdentifier()
             || token.Text != identifier )
        {
            new_token_array ~= token;
        }
    }

    token_array = new_token_array;
}

// ~~

long GetLevel(
    TOKEN[] token_array
    )
{
    long
        level;

    foreach ( token; token_array )
    {
        token.Level = level;

        if ( token.IsCharacter() )
        {
            if ( token.Text == "{"
                 || token.Text == "["
                 || token.Text == "(" )
            {
                if ( level >= 0 )
                {
                    ++level;
                }
            }
            else if ( token.Text == "}"
                 || token.Text == "]"
                 || token.Text == ")" )
            {
                --level;
            }
        }
    }

    return level;
}

// ~~

bool EndsStatement(
    TOKEN[] token_array
    )
{
    long
        level;

    foreach ( token; token_array )
    {
        if ( token.IsCharacter()
             && token.IsCode()
             && token.Text == ";"
             && token.Level == 0 )
        {
            return true;
        }
    }

    return false;
}


// ~~

void Dump(
    TOKEN[] token_array
    )
{
    foreach( token_index, token; token_array )
    {
        token.Dump( token_index );
    }
}

// ~~

bool EvaluateBooleanExpression(
    string boolean_expression
    )
{
    string
        old_value,
        value;

    value = boolean_expression;

    do
    {
        old_value = value;

        value
            = value
                  .replace( " ", "" )
                  .replace( "!false", "true" )
                  .replace( "!true", "false" )
                  .replace( "false&&false", "false" )
                  .replace( "false&&true", "false" )
                  .replace( "true&&false", "false" )
                  .replace( "true&&true", "true" )
                  .replace( "false||false", "false" )
                  .replace( "false||true", "true" )
                  .replace( "true||false", "true" )
                  .replace( "true||true", "true" )
                  .replace( "(true)", "true")
                  .replace( "(false)", "false" );
    }
    while ( value != old_value );

    if ( value == "false" )
    {
        return false;
    }
    else if ( value == "true" )
    {
        return true;
    }

    Abort( "Invalid boolean expression : " ~ boolean_expression );

    return false;
}

// ~~

void FindInputFiles(
    )
{
    long
        folder_path_index;
    string
        input_file_path,
        input_folder_path,
        output_file_path,
        output_folder_path;
    FILE *
        found_file;

    foreach ( file; FileMap )
    {
        file.Exists = false;
    }

    for ( folder_path_index = 0;
          folder_path_index < InputFolderPathArray.length;
          ++folder_path_index )
    {
        input_folder_path = InputFolderPathArray[ folder_path_index ];
        output_folder_path = OutputFolderPathArray[ folder_path_index ];

        foreach ( input_folder_entry; dirEntries( input_folder_path, "*.gs", SpanMode.depth ) )
        {
            if ( input_folder_entry.isFile() )
            {
                input_file_path = input_folder_entry.name();

                if ( input_file_path.startsWith( input_folder_path )
                     && input_file_path.endsWith( ".gs" ) )
                {
                    if ( output_folder_path == "" )
                    {
                        output_file_path = "";
                    }
                    else
                    {
                        output_file_path
                            = output_folder_path
                              ~ input_file_path[ input_folder_path.length .. $ - 3 ]
                              ~ ".go";
                    }

                    found_file = input_file_path in FileMap;

                    if ( found_file is null )
                    {
                        FileMap[ input_file_path ] = new FILE( input_file_path, output_file_path );
                    }
                    else
                    {
                        found_file.Exists = true;
                    }
                }
            }
        }
    }

    foreach ( file; FileMap )
    {
        if ( !file.Exists )
        {
            file.Text = "";
        }
    }
}

// ~~

void ReadInputFiles(
    )
{
    foreach ( file; FileMap )
    {
        if ( file.Exists )
        {
            file.ReadInputFile();
            file.ParseDefinitions();
        }
    }
}

// ~~

void WriteOutputFiles(
    )
{
    foreach ( file; FileMap )
    {
        if ( file.Exists
             && file.OutputPath != "" )
        {
            file.ApplyDefinitions();
            file.ApplyConditions();
            file.ApplyTemplates();
            file.JoinStatements();
            file.WriteOutputFile();
        }
    }
}

// ~~

void ProcessFiles(
    bool modification_time_is_used
    )
{
    bool
        files_are_processed;

    DefinitionArray = null;

    FindInputFiles();

    files_are_processed = false;

    foreach ( file; FileMap )
    {
        if ( file.Exists )
        {
            file.CheckChange( modification_time_is_used );

            if ( file.IsProcessed )
            {
                files_are_processed = true;
            }
        }
    }

    if ( files_are_processed )
    {
        ReadInputFiles();
        WriteOutputFiles();
    }
}

// ~~

void WatchFiles(
    )
{
    ProcessFiles( false );

    writeln( "Watching files..." );

    while ( true )
    {
        Thread.sleep( dur!( "msecs" )( PauseDuration ) );

        ProcessFiles( true );
    }
}

// ~~

void main(
    string[] argument_array
    )
{
    string
        input_folder_path,
        option,
        output_folder_path;

    argument_array = argument_array[ 1 .. $ ];

    SpaceText = " ";

    InputFolderPathArray = null;
    OutputFolderPathArray = null;
    JoinOptionIsEnabled = false;
    CreateOptionIsEnabled = false;
    WatchOptionIsEnabled = false;
    PauseDuration = 500;
    TabulationSpaceCount = 4;

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--parse"
             && argument_array.length >= 1
             && argument_array[ 0 ].GetLogicalPath().endsWith( '/' ) )
        {
            InputFolderPathArray ~= argument_array[ 0 ].GetLogicalPath();
            OutputFolderPathArray ~= "";

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--process"
             && argument_array.length >= 2
             && argument_array[ 0 ].GetLogicalPath().endsWith( '/' )
             && argument_array[ 1 ].GetLogicalPath().endsWith( '/' ) )
        {
            InputFolderPathArray ~= argument_array[ 0 ].GetLogicalPath();
            OutputFolderPathArray ~= argument_array[ 1 ].GetLogicalPath();

            argument_array = argument_array[ 2 .. $ ];
        }
        else if ( option == "--join" )
        {
            JoinOptionIsEnabled = true;
        }
        else if ( option == "--create" )
        {
            CreateOptionIsEnabled = true;
        }
        else if ( option == "--watch" )
        {
            WatchOptionIsEnabled = true;
        }
        else if ( option == "--pause"
                  && argument_array.length >= 1 )
        {
            PauseDuration = argument_array[ 0 ].to!long();

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--tabulation"
                  && argument_array.length >= 1 )
        {
            TabulationSpaceCount = argument_array[ 0 ].to!long();

            argument_array = argument_array[ 1 .. $ ];
        }
        else
        {
            PrintError( "Invalid option : " ~ option );
        }
    }

    if ( argument_array.length == 0 )
    {
        if ( WatchOptionIsEnabled )
        {
            WatchFiles();
        }
        else
        {
            ProcessFiles( false );
        }
    }
    else
    {
        writeln( "Usage :" );
        writeln( "    generis [options]" );
        writeln( "Options :" );
        writeln( "    --parse INPUT_FOLDER/" );
        writeln( "    --process INPUT_FOLDER/ OUTPUT_FOLDER/" );
        writeln( "    --join" );
        writeln( "    --create" );
        writeln( "    --watch" );
        writeln( "    --pause 500" );
        writeln( "    --tabulation 4" );
        writeln( "Examples :" );
        writeln( "    generis GS/ GO/" );
        writeln( "    generis --create GS/ GO/" );
        writeln( "    generis --create --watch GS/ GO/" );

        PrintError( "Invalid arguments : " ~ argument_array.to!string() );
    }
}
