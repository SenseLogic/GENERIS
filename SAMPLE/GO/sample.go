package main;

// -- IMPORTS

import ( "html"
    "io"
    "log"
    "net/http"
    "strconv" );

// -- DEFINITIONS

// ~~

// ~~

// ~~

// ~~


// ~~


// -- TYPES

// -- TYPES

type StringStack struct {
    ElementArray []string;
}

// -- INQUIRIES

func ( stack * StringStack ) IsEmpty( ) bool {
    return len( stack.ElementArray ) == 0;
}

// -- OPERATIONS

func ( stack * StringStack ) Push( element string ) {
    stack.ElementArray = append( stack.ElementArray, element );
}

// ~~

func ( stack * StringStack ) Pop( ) string {
    var element string;

    element = stack.ElementArray[ len( stack.ElementArray ) - 1 ];

    stack.ElementArray = stack.ElementArray[ : len( stack.ElementArray ) - 1 ];

    return element;
}
// -- TYPES

type Int32Stack struct {
    ElementArray []int32;
}

// -- INQUIRIES

func ( stack * Int32Stack ) IsEmpty( ) bool {
    return len( stack.ElementArray ) == 0;
}

// -- OPERATIONS

func ( stack * Int32Stack ) Push( element int32 ) {
    stack.ElementArray = append( stack.ElementArray, element );
}

// ~~

func ( stack * Int32Stack ) Pop( ) int32 {
    var element int32;

    element = stack.ElementArray[ len( stack.ElementArray ) - 1 ];

    stack.ElementArray = stack.ElementArray[ : len( stack.ElementArray ) - 1 ];

    return element;
}

// -- FUNCTIONS

func HandleRootPage( response_writer http.ResponseWriter, request * http.Request ) {
    var boolean bool;
    var natural uint;
    var integer int;
    var real float64;
    var escaped_text, text string;
    var integer_stack Int32Stack;

    boolean = true;
    natural = 10;
    integer = 20;
    real = 30.0;
    text = "text";
    escaped_text = "<escaped text/>";

    integer_stack.Push( 10 );
    integer_stack.Push( 20 );
    integer_stack.Push( 30 );

    io.WriteString( response_writer, "<!DOCTYPE html>\n<html lang=\"en\">\n    <head>\n        <meta charset=\"utf-8\">\n        <title>" );
    io.WriteString( response_writer, html.EscapeString( request.URL.Path ) );
    io.WriteString( response_writer, "</title>\n    </head>\n    <body>\n        " );
 if ( boolean ) {
    io.WriteString( response_writer, "\n            " );
    io.WriteString( response_writer, html.EscapeString( "URL : " + request.URL.Path ) );
    io.WriteString( response_writer, "\n            <br/>\n            " );
    io.WriteString( response_writer, strconv.FormatUint( uint64( natural ), 10 ) );
    io.WriteString( response_writer, "\n            " );
    io.WriteString( response_writer, strconv.FormatInt( int64( integer ), 10 ) );
    io.WriteString( response_writer, "\n            " );
    io.WriteString( response_writer, strconv.FormatFloat( float64( real ), 'f', -1, 64 ) );
    io.WriteString( response_writer, "\n            <br/>\n            " );
    io.WriteString( response_writer, text );
    io.WriteString( response_writer, "\n            " );
    io.WriteString( response_writer, html.EscapeString( escaped_text ) );
    io.WriteString( response_writer, "\n            " );
    io.WriteString( response_writer, html.EscapeString( "<% ignored %>" ) );
    io.WriteString( response_writer, "\n        " );
 }
    io.WriteString( response_writer, "\n        <br/>\n        Stack :\n        <br/>\n        " );
 for !integer_stack.IsEmpty() {
    io.WriteString( response_writer, "\n            " );
    io.WriteString( response_writer, strconv.FormatInt( int64( integer_stack.Pop() ), 10 ) );
    io.WriteString( response_writer, "\n        " );
 }
    io.WriteString( response_writer, "\n    </body>\n</html>" );
}

// ~~

func main() {
    http.HandleFunc( "/", HandleRootPage );

    log.Println( "Listening on http://localhost:8080" );

    log.Fatal( http.ListenAndServe( ":8080", nil ) );
}
