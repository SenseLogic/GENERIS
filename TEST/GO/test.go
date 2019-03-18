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

// ~~


// ~~



// -- TYPES

type Int32Stack struct {
    ElementArray []int32;
}

// -- FUNCTIONS

func HandleRootPage( response_writer http.ResponseWriter, request * http.Request ) {
    var real_32 float32;
    var real_64 float64;
    var integer_8 int8;
    var integer_16 int16;
    var integer_32 int32;
    var integer_64 int64;
    var escaped_text, text string;
    var natural_8 uint8;
    var natural_16 uint16;
    var natural_32 uint32;
    var natural_64 uint64;

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

    io.WriteString( response_writer, "<!DOCTYPE html>\n<html lang=\"en\">\n    <head>\n        <meta charset=\"utf-8\">\n        <title>" );
    io.WriteString( response_writer, html.EscapeString( request.URL.Path ) );
    io.WriteString( response_writer, "</title>\n    </head>\n    <body>\n        " );

        io.WriteString( response_writer, html.EscapeString( "URL=" + request.URL.Path ) );

    io.WriteString( response_writer, "\n        " );
    io.WriteString( response_writer, strconv.FormatUint( uint64( natural_8 ), 10 ) );
    io.WriteString( response_writer, strconv.FormatUint( uint64( natural_16 ), 10 ) );
    io.WriteString( response_writer, strconv.FormatUint( uint64( natural_32 ), 10 ) );
    io.WriteString( response_writer, strconv.FormatUint( uint64( natural_64 ), 10 ) );
    io.WriteString( response_writer, "\n        " );
    io.WriteString( response_writer, strconv.FormatInt( int64( integer_8 ), 10 ) );
    io.WriteString( response_writer, strconv.FormatInt( int64( integer_16 ), 10 ) );
    io.WriteString( response_writer, strconv.FormatInt( int64( integer_32 ), 10 ) );
    io.WriteString( response_writer, strconv.FormatInt( int64( integer_64 ), 10 ) );
    io.WriteString( response_writer, "\n        " );
    io.WriteString( response_writer, strconv.FormatFloat( float64( real_32 ), 'f', -1, 64 ) );
    io.WriteString( response_writer, strconv.FormatFloat( float64( real_64 ), 'f', -1, 64 ) );
    io.WriteString( response_writer, "\n        " );
    io.WriteString( response_writer, text );
    io.WriteString( response_writer, "\n        " );
    io.WriteString( response_writer, html.EscapeString( escaped_text ) );
    io.WriteString( response_writer, "\n        " );
    io.WriteString( response_writer, html.EscapeString( "<%% ignored %>" ) );
    io.WriteString( response_writer, "\n        <% ignored %%>\n    </body>\n</html>" );

log.Println( "true && true" );

log.Println( "!( true && !true )" );
log.Println( "!( true && false )" );

    log.Println( "true" );
    log.Println( "false" );

    log.Println( "TRUE :)" );

    log.Println( "FALSE :)" );
}

// ~~

func main() {
    http.HandleFunc( "/", HandleRootPage );

    log.Println( "Listening on http://localhost:8080" );

    log.Fatal( http.ListenAndServe( ":8080", nil ) );
}
