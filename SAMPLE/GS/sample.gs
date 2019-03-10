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

#define DeclareStack( {{name}}, {{type}} )
#as
    type {{name}}Stack struct
    {
        ElementArray []{{type}};
    }

    // ~~

    func ( stack * {{name}}Stack ) IsEmpty(
        ) bool
    {
        return len( stack.ElementArray ) == 0;
    }

    // ~~

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
                <title><%~ request.URL.Path %></title>
            </head>
            <body>
                <% if ( boolean ) { %>
                    <%~ "URL : " + request.URL.Path %>
                    <br/>
                    <%@ natural %>
                    <%# integer %>
                    <%& real %>
                    <br/>
                    <%= text %>
                    <%~ escaped_text %>
                    <%~ "<\% ignored %\>" %>
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

// -- STATEMENTS

DeclareStack( String, string )
DeclareStack( Int32, int32 )