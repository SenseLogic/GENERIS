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

#define ItIsTrue
#as true

// ~~

#define ItIsFalse
#as false

// ~~

#define TestCondition( {{condition}} )
#as
    #if ItIsTrue && {{condition}}
        log.Println( "ItIsTrue && {{condition}}" );

        #if ItIsTrue && !{{condition}}
            log.Println( "ItIsTrue && !{{condition}}" );
        #else
            log.Println( "!( ItIsTrue && !{{condition}} )" );
        #end
    #else
        log.Println( "!( ItIsTrue && {{condition}} )" );
    #end
#end

// ~~

#define aaa {{xxx}} aaa
#as "AAA{{xxx}}AAA"

// ~~

#define bbb {{xxx}} bbb
#as
    "BBB{{xxx}}BBB"
#end

// ~~

#define
    ccc {{xxx}} ccc
#as "CCC{{xxx}}CCC"

// ~~

#define
    ddd {{xxx}} ddd
#as
    "DDD{{xxx}}DDD"
#end

// ~~

#define var {{variable#}} : {{type#}};
#as var {{variable}} {{type}};

// -- FUNCTIONS

func HandleRootPage(
    response_writer http.ResponseWriter,
    request * http.Request
    )
{
    var
        real_32 float32;
    var
        real_64 float64;
    var
        integer_8 int8;
    var
        integer_16 int16;
    var
        integer_32 int32;
    var
        integer_64 int64;
    var
        escaped_text,
        text string;
    var
        natural_8 uint8;
    var
        natural_16 uint16;
    var
        natural_32 uint32;
    var
        natural_64 uint64;

    natural_8 = 8;
    natural_16 = 16;
    natural_32 = 32;
    natural_64 = 64;

    integer_8 = 8;
    integer_16 = 16;
    integer_32 = 32;
    integer_64 = 64;

    real_32 = 32.0;
    real_64 = 64.0;

    text = "text";
    escaped_text = "<escaped text/>";

    #write response_writer
        <!DOCTYPE html>
        <html lang="en">
            <head>
                <meta charset="utf-8">
                <title><%~ request.URL.Path %></title>
            </head>
            <body>
                <%
                io.WriteString(
                    response_writer,
                    html.EscapeString( "URL=" + request.URL.Path )
                    );
                %>
                <%@ natural_8 %><%@ natural_16 %><%@ natural_32 %><%@ natural_64 %>
                <%# integer_8 %><%# integer_16 %><%# integer_32 %><%# integer_64 %>
                <%& real_32 %><%& real_64 %>
                <%= text %>
                <%~ escaped_text %>
                <%~ "<\% ignored %\>" %>
            </body>
        </html>
    #end

    TestCondition( ItIsTrue )
    TestCondition( ItIsFalse )

    log.Println( "ItIsTrue" );
    log.Println( "ItIsFalse" );

    #if true
        log.Println( "TRUE :)" );
    #else
        log.Println( "FALSE :(" );
    #end

    #if false
        log.Println( "TRUE :(" );
    #else
        log.Println( "FALSE :)" );
    #end
}

// ~~

func main()
{
    http.HandleFunc( "/", HandleRootPage );

    log.Println( "Listening on http://localhost:8080" );

    log.Fatal(
        http.ListenAndServe( ":8080", nil )
        );
}
