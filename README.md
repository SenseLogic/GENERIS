![](https://github.com/senselogic/GENERIS/blob/master/LOGO/generis.png)

# Generis

Versatile Go code generator.

## Description

Generis is a lightweight code preprocessor adding the following features to the Go language :

*   Generics.
*   Free-form macros.
*   Conditional compilation.
*   HTML templating.
*   Allman style conversion.

## Sample

```go
package main;

// -- IMPORTS

import (
    "html"
    "io"
    "log"
    "net/http"
    "net/url"
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
        escaped_html_text,
        escaped_url_text,
        text : string;
    local
        integer_stack : Int32Stack;

    boolean = true;
    natural = 10;
    integer = 20;
    real = 30.0;
    text = "text";
    escaped_url_text = "&escaped text?";
    escaped_html_text = "<escaped text/>";

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
                    <%^ escaped_url_text %>
                    <%= escaped_html_text %>
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
        http.ListenAndServe( ":HttpPort", nil )
        );
}
```

## Syntax

### #define directive

Constants and generic code can be defined with the following syntax :

```go
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
```

#### #define parameter

The `#define` directive can contain one or several parameters :

```go
{{variable name}} : hierarchical code (with properly matching brackets and parentheses)
{{variable name#}} : statement code (hierarchical code without semicolon)
{{variable name$}} : plain code
{{variable name:boolean expression}} : conditional hierarchical code
{{variable name#:boolean expression}} : conditional statement code
{{variable name$:boolean expression}} : conditional plain code
```

They can have a boolean expression to require they match specific conditions :

```go
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

The `#define` directive must not start or end with a parameter.

#### #as parameter

The `#as` directive can use the value of the `#define` parameters :

```go
{{variable name}}
{{variable name:filter function}}
{{variable name:filter function:filter function:...}}
```

Their value can be changed through one or several filter functions :

```go
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

### #if directive

Conditional code can be defined with the following syntax :

```go
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
```

The boolean expression can use the following operators :

```go
false
true
!expression
expression && expression
expression || expression
( expression )
```

### #write directive

Templated HTML code can be sent to a stream writer using the following syntax :

```html
#write writer expression
    <% code %>
    <%@ natural expression %>
    <%# integer expression %>
    <%& real expression %>
    <%~ text expression %>
    <%= escaped text expression %>
    <%! removed content %>
    <%% ignored tags %%>
#end
```

## Limitations

*   There is no operator precedence in boolean expressions.
*   The `--join` option requires to end the statements with a semicolon.
*   The `#writer` directive is only available for the Go language.

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html) (using the MinGW setup option on Windows).

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
--parse INPUT_FOLDER/ : parse the definitions of the Generis files in the input folder
--process INPUT_FOLDER/ OUTPUT_FOLDER/ : reads the Generis files in the input folder and writes the processed files in the output folder
--trim : trim the HTML templates
--join : join the split statements
--create : create the output folders if needed
--watch : watch the Generis files for modifications
--pause 500 : time to wait before checking the Generis files again
--tabulation 4 : set the tabulation space count
--go : generate Go files
--cs : generate C# files
--js : generate JavaScript files
```

One of the `--go`, `--cs` or `--js` options must be used.

### Examples

```bash
generis --process GS/ GO/ --go
```

Reads the Generis files in the `GS/` folder and writes Go files in the `GO/` folder.

```bash
generis --process GS/ GO/ --create --go
```

Reads the Generis files in the `GS/` folder and writes Go files in the `GO/` folder,
creating the output folders if needed.

```bash
generis --process GS/ GO/ --create --watch --go
```

Reads the Generis files in the `GS/` folder and writes Go files in the `GO/` folder,
creating the output folders if needed and watching the Generis files for modifications.

```bash
generis --process GS/ GO/ --trim --join --create --watch --go
```

Reads the Generis files in the `GS/` folder and writes Go files in the `GO/` folder,
trimming the HTML templates, joining the split statements, creating the output folders if needed
and watching the Generis files for modifications.

## Version

1.0

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
