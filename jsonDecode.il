procedure( jsonDecode( file )
    let( ( state )

        indent = pcreCompile( "^[\\s\\t]+" )
        colon = pcreCompile( "\":[\\s\\t]+\n*" )
        comma = pcreCompile( "([\\s\\t]*,[\\s\\t]+$)" )

        keywordIdentifier = pcreCompile( "^\".+(\":)" )
        newline = pcreCompile( "\\n" )

        ; Type identifier
        boolTrue = pcreCompile( "(^true$)" )
        boolFalse = pcreCompile( "(^false$)" )
        number = pcreCompile( "(^[0-9]*$)|(^[0-9]*[.][0-9]+$)" )
        
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
            ; Replace
            line = pcreReplace( indent line "" 0 )
            line = pcreReplace( colon line "\":\n" 0 )
            line = pcreReplace( comma line "\n,\n" 0 )

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
                                )
                                (
                                    "["
                                    state = "awaitArray"
                                )
                                
                                (
                                    ","
                                    state = "awaitObject"
                                )
                                (
                                    t
                                    ; Set value
                                    if( pcreMatchp( number subString ) then
                                        subString = atof( subString )      
                                    else                              
                                        if( pcreMatchp( boolTrue subString ) then
                                            subString = t
                                        else
                                            if( pcreMatchp( boolFalse subString) then
                                                subString = nil
                                            else
                                                subString = substring( subString 2 strlen( subString ) - 2 )
                                            )
                                        )
                                    )

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
                                )
                                (
                                    t
                                    ; make List
                                    if( pcreMatchp( number subString ) then
                                        subString = atof( subString )      
                                    else                              
                                        if( pcreMatchp( boolTrue subString ) then
                                            subString = t
                                        else
                                            if( pcreMatchp( boolFalse subString) then
                                                subString = nil
                                            else
                                                subString = substring( subString 2 strlen( subString ) - 2 )
                                            )
                                        )
                                    )

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
        when( openCurlyBraces != 0 || openBrackets != 0 
            error( "unclosed objects" )
        )
        close( prt )
        json
    )
)