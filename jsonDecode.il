procedure( jsonDecode( file )
    let( ( state )

        indent = pcreCompile( "^[\\s\\t]+" )
        colon = pcreCompile( "\":[\\s\\t]+\n*" )
        comma = pcreCompile( "([\\s\\t]*,[\\s\\t]+$)" )

        keywordIdentifier = pcreCompile( "^\".+(\":)" )
        newline = pcreCompile( "\\n" )
        
        tmpTable = makeTable( "json" nil )

        json = tmpTable

        prt = infile( file )

        state = "awaitObject"
        
        openCurlyBraces = 0
        openBrackets = 0

        currentKey = nil
        tmpArray = nil

        ; Read file
        while( gets(line prt)
            ; char = getc(prt) 

            line = pcreReplace( indent line "" 0 )
            line = pcreReplace( colon line "\":\n" 0 )
            line = pcreReplace( comma line "\n,\n" 0 )
            
            ; print( line )

            subStrings = parseString( line "\n" )

            foreach( subString subStrings
                ; Detect start of json
                if( openCurlyBraces > 0 then
                    case( state
                        (
                            "awaitObject"
                            name = pcreMatchList( keywordIdentifier list( subString ) )
                            if( name then
                                state = "awaitTypeOrValue"
                            else                                
                                when( state != "start" && member( subString list( "{" "," "[" "]" ) ) 
                                    error()
                                )
                            )


                            name = car( name )
                            name = substring( name 2 strlen( name ) - 3)                       

                            currentKey = tconc( currentKey name )

                            cmd = strcat( "json->" buildString( car( currentKey ) "->" ) )

                            if( evalstring( cmd ) then
                                print( "existing" )                                
                            else
                                cmd = strcat( "json->" buildString( car( currentKey ) "->" ) "=makeTable( \"json\" nil )" ) 
                                evalstring( cmd )    
                            )
                        )
                        (
                            "awaitTypeOrValue"
                            case( subString
                                (
                                    "{"
                                    state = "awaitObject"
                                    openCurlyBraces = openCurlyBraces + 1
                                )
                                (
                                    "}"
                                    ;  remove last element
                                    currentKey = lconc( nil reverse( cdr( reverse( car( currentKey ) ) ) ) )
                                    openCurlyBraces = openCurlyBraces - 1
                                    print( "closed curly brace" )
                                )
                                (
                                    "["
                                    state = "awaitArray"
                                    ; print( "array" )
                                )
                                
                                (
                                    ","
                                    state = "awaitObject"
                                    ; print( "next" )
                                )
                                (
                                    t
                                    ; Set value
                                    cmd = strcat( "json->" buildString( car( currentKey ) "->" ) "=subString" ) 
                                    evalstring( cmd )    
                                    state = "awaitTypeOrValue"
                                    ;  remove last element
                                    currentKey = lconc( nil reverse( cdr( reverse( car( currentKey ) ) ) ) )
                                )
                            )                        
                        )    
                        (
                            "awaitArray"
                            case( subString                                
                                ( 
                                    ","
                                    ; print("next")
                                )
                                (
                                    "]"
                                    ; Set list
                                    state = "awaitTypeOrValue"
                                    tmpArray = car( tmpArray )
                                    ; append array
                                    cmd = strcat( "json->" buildString( car( currentKey ) "->" ) "=tmpArray" ) 
                                    evalstring( cmd )    

                                    tmpArray = nil
                                    ;  remove last element
                                    currentKey = lconc( nil reverse( cdr( reverse( car( currentKey ) ) ) ) )                                    
                                    ; print("closing")                                    
                                )
                                (
                                    t
                                    ; make List
                                    tmpArray = tconc( tmpArray subString )
                                )                                
                            )
                        )
                        (
                            t
                            error()
                        )
                    )
                else
                    when( subString == "{"
                        openCurlyBraces = openCurlyBraces + 1                         
                    )
                )                
            )
        )
        json
    )
)