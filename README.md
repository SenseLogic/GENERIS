![](https://github.com/senselogic/GENERIS/blob/master/LOGO/generis.png)

# Generis

Go code generator.

## Sample

```go
package main;

// -- IMPORTS

import (
    "html"
    "io"
    "log"
    "net/http"
    "strconv"
    );

// -- DEFINITIONS

#define DebugMode
#as true

// ~~

#define HttpPort
#as 8080

// ~~

#define WriteLine( {{text}} )
#as log.Println( {{text}} )

// ~~

#define local {{variable}} : {{type}};
#as var {{variable}} {{type}};

// ~~

#define DeclareStack( {{type}}, {{name}} )
#as
    // -- TYPES

    type {{name}}Stack struct
    {
        ElementArray []{{type}};
    }

    // -- INQUIRIES

    func ( stack * {{name}}Stack ) IsEmpty(
        ) bool
    {
        return len( stack.ElementArray ) == 0;
    }

    // -- OPERATIONS

    func ( stack * {{name}}Stack ) Push(
        element {{type}}
        )
    {
        stack.ElementArray = append( stack.ElementArray, element );
    }

    // ~~

    func ( stack * {{name}}Stack ) Pop(
        ) {{type}}
    {
        local
            element : {{type}};

        element = stack.ElementArray[ len( stack.ElementArray ) - 1 ];

        stack.ElementArray = stack.ElementArray[ : len( stack.ElementArray ) - 1 ];

        return element;
    }
#end

// ~~

#define DeclareStack( {{type}} )
#as DeclareStack( {{type}}, {{type:PascalCase}} )

// -- TYPES

DeclareStack( string )
DeclareStack( int32 )

// -- FUNCTIONS

func HandleRootPage(
    response_writer http.ResponseWriter,
    request * http.Request
    )
{
    local
        boolean : bool;
    local
        natural : uint;
    local
        integer : int;
    local
        real : float64;
    local
        escaped_text,
        text : string;
    local
        integer_stack : Int32Stack;

    boolean = true;
    natural = 10;
    integer = 20;
    real = 30.0;
    text = "text";
    escaped_text = "<escaped text/>";

    integer_stack.Push( 10 );
    integer_stack.Push( 20 );
    integer_stack.Push( 30 );

    #write response_writer
        <!DOCTYPE html>
        <html lang="en">
            <head>
                <meta charset="utf-8">
                <title><%= request.URL.Path %></title>
            </head>
            <body>
                <% if ( boolean ) { %>
                    <%= "URL : " + request.URL.Path %>
                    <br/>
                    <%@ natural %>
                    <%# integer %>
                    <%& real %>
                    <br/>
                    <%~ text %>
                    <%= escaped_text %>
                    <%= "<%% ignored %%>" %>
                    <%% ignored %%>
                <% } %>
                <br/>
                Stack :
                <br/>
                <% for !integer_stack.IsEmpty() { %>
                    <%# integer_stack.Pop() %>
                <% } %>
            </body>
        </html>
    #end
}

// ~~

func main()
{
    http.HandleFunc( "/", HandleRootPage );

    #if DebugMode
        WriteLine( "Listening on http://localhost:HttpPort" );
    #end

    log.Fatal(
        http.ListenAndServe( ":8080", nil )
        );
}
```

### Commands

```cpp
#define old code
#as new code

#define old code
#as
    new
    code
#end

#define
    old
    code
#as new code

#define
    old
    code
#as
    new
    code
#end

#if boolean expression
    #if boolean expression
        ...
    #else
        ...
    #end
#else
    #if boolean expression
        ...
    #else
        ...
    #end
#end

#write writer expression
    <% code %>
    <%@ natural expression %>
    <%# integer expression %>
    <%& real expression %>
    <%~ escaped text expression %>
    <%= unescaped text expression %>
    <%! ignored comment %>
    <%% escaped tag %%>
#end
```

### Old code parameter

```cpp
{{variable name}} : hierarchical code
{{variable name#}} : statement code (without semicolon)
{{variable name$}} : plain code
{{variable name:boolean expression}} : conditional hierarchical code
{{variable name#:boolean expression}} : conditional statement code
{{variable name$:boolean expression}} : conditional plain code
```

### Old code boolean expression

```cpp
HasText text
HasPrefix prefix
HasSuffix suffix
HasIdentifier text
false
true
!expression
expression && expression
expression || expression
( expression )
```

### New code parameter

```cpp
{{variable name}}
{{variable name:filter function}}
{{variable name:filter function:filter function:...}}
```

### New code filter function

```cpp
LowerCase
UpperCase
MinorCase
MajorCase
SnakeCase
PascalCase
CamelCase
RemoveComments
RemoveBlanks
PackStrings
PackIdentifiers
ReplaceText old_text new_text
ReplacePrefix old_prefix new_prefix
ReplaceSuffix old_suffix new_suffix
ReplaceIdentifier old_identifier new_identifier
RemoveText text
RemovePrefix prefix
RemoveSuffix suffix
RemoveIdentifier identifier
```

### Boolean expression

```
false
true
!expression
expression && expression
expression || expression
( expression )
```

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html).

Build the executable with the following command line :

```bash
dmd -m64 generis.d
```

## Command line

```
generis [options]
```

### Options

```
--parse INPUT_FOLDER/ : parse the definitions from the Generis files of this folder
--process INPUT_FOLDER/ OUTPUT_FOLDER/ : processes the Generis files of the input folder to generate Go files in the output folder
--join : join split statements
--create : create the output folders if needed
--watch : watch the Generis files for modifications
--pause 500 : time to wait before checking the Generis files again
--tabulation 4 : set the tabulation space count
```

### Examples

```bash
generis --process GS/ GO/ --join
```

Processes the Generis files of the input folder to generate Go files in the output folder, and joins the split statements.

## Version

0.9

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
