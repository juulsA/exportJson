axlCmdRegister( "exportJson" `exportJson )

procedure( addMetadata( dsnName rev company )
    let( ( metadata )    

        when( rev == ""
            rev = axlUIPrompt( strcat( "Enter Revision for " dsnName ":" ) )          
        )

        when( company == ""
            company =  axlUIPrompt( "Enter company name:" )                    
        )
        
        rev = strcat( "\"" rev "\"" )
        company = strcat( "\"" company "\"" )

        dsnName = strcat( "\"" upperCase( dsnName ) "\"" )
          
        currentTime = timeToTm( stringToTime( getCurrentTime() ) )
        day = sprintf( nil "%d" currentTime->tm_mday )
        month = sprintf( nil "%d" currentTime->tm_mon + 1 ) 
        year = sprintf( nil "%d" currentTime->tm_year - 100 )
        currentDate = strcat( "\"" day "." month "." year "\"" )
        
        metadata = strcat(            
            "\"metadata\": {\n"
            "\t\"title\": " dsnName ",\n",
            "\t \"revision\": " rev ",\n"
            "\t\"company\": " company ",\n"
            "\t\"date\": " currentDate "\n"
            "}"
        )       
    )
)

procedure( addIndent( string @optional ( tabs 1 ) )    
    let( ( ( indentedStrings 'unbound ) ( indent "" ) ) 
        
        for( i 1 tabs 
            indent = strcat( indent "\t" )
        )

        lines = parseString( string "\n" )
        foreach( line lines
            if( boundp( 'indentedStrings ) then 
                tconc( indentedStrings strcat( indent line ) )
            else
                indentedStrings = tconc( nil strcat( indent line ) )            
            )
        )    
        indentedStrings = buildString( car( indentedStrings ) "\n" )
    )
)

; ### segment

; ```js
; {
;   "type": "segment",
;   "start": [x, y],
;   "end": [x, y],
;   "width": width,
; }
; ```

procedure( addLine( segment @optional ( isEtch nil ) ( width 0.1 ) )
    let( ( extents xStart yStart xEnd yEnd element )    
        extents = segment->startEnd

        xStart = caar( extents )
        yStart = -cadar( extents ) ; multiply by -1, s. ibom y convention
        
        xEnd = caadr( extents )        
        yEnd = -cadadr( extents ) ; multiply by -1, s. ibom y convention

        if( isEtch then
            element = strcat(
                "{\n\t\"net\": \"" segment->net->name "\",\n"
            )

            width = segment->width            
        else 
            element = "{\n\t\"type\": \"segment\",\n"
        )

        element = strcat( 
            element            
            "\t\"start\": [" sprintf( nil "%f" xStart ) ", " sprintf( nil "%f" yStart ) "],\n"
            "\t\"end\": [" sprintf( nil "%f" xEnd ) ", " sprintf( nil "%f" yEnd ) "],\n"
            "\t\"width\": " sprintf( nil "%f" width ) "\n"    
            "}"        
        )
    )
)

; ### circle

; ```js
; {
;   "type": "circle",
;   "start": [x, y],
;   "radius": radius,
;   // Optional boolean, defaults to 0
;   "filled": 0,
;   // Line width (only has effect for non-filled shapes)
;   "width": width,
; }
; ```

procedure( addCircle( segment @optional ( width 0.1 ) )
    let( ( xy xStart yStart radius element )
        xy = segment->xy
        xStart = car( xy )
        yStart = -cadr( xy ) 
        radius = segment->radius       

        element = strcat( 
            "{\n"
            "\t\"type\": \"circle\",\n" 
            "\t\"start\": [" sprintf( nil "%f" xStart ) ", " sprintf( nil "%f" yStart ) "],\n"
            "\t\"radius\": " sprintf( nil "%f" radius ) ",\n"
            "\t\"width\": " sprintf( nil "%f" width ) "\n"            
            "}" 
        )
    )
)

; ### arc

; ```js
; {
;   "type": "arc",
;   "width": width,
;   // SVG path of the arc given as 'd' attribute of svg spec.
;   // If this parameter is specified everything below it is ignored.
;   "svgpath": svgpath,
;   "start": [x, y], // arc center
;   "radius": radius,
;   "startangle": angle1,
;   "endangle": angle2,
; }
; ```

procedure( addArc( segment @optional ( isEtch nil ) ( width 0.1 ) )
    let( ( xy xCenter yCenter radius extents xStart yStart xEnd yEnd cw angle1 angle2 startAngle endAngle element )
        xy = segment->xy
        xCenter = car( xy )
        yCenter = -cadr( xy )
        
        radius = segment->radius

        extents = segment->startEnd        

        xStart = caar( extents )
        yStart = -cadar( extents ) ; multiply by -1, s. ibom y convention
        
        xEnd = caadr( extents )        
        yEnd = -cadadr( extents ) ; multiply by -1, s. ibom y convention

        cw = segment->isClockwise
        
        ;width = 0.1 ;segment->width
        
        angle1 =  axlRadToDeg( atan2( ( yStart - yCenter ), ( xStart - xCenter ) ) )   

        ; convert to positive angle
        when( negativep( angle1 )
            angle1 = angle1 + 360
        )
        
        angle2 = axlRadToDeg( atan2( ( yEnd - yCenter ), ( xEnd - xCenter ) ) )

        ; convert to positive angle
        when( negativep( angle2 )
            angle2 = angle2 + 360    
        )
        
        ; map the correct angles
        if( ( angle2 - angle1 ) > 0 then
            if( cw then
                startAngle = angle1
                endAngle = angle2        
            else
                startAngle = angle2
                endAngle = angle1
            )

            ; if arc is a circle, but not marked as a circle ...
            when( startAngle == endAngle
                endAngle = endAngle + 360.0
            )
        else
            if( cw then
                startAngle = angle1
                endAngle = angle2        
            else
                startAngle = angle2
                endAngle = angle1
            )
            
            ; if arc is a circle, but not marked as a circle ...
            when( startAngle == endAngle
                startAngle = startAngle + 360.0
            )
        )

        if( isEtch then
            element = strcat(
                "{\n\t\"net\": \"" segment->net->name "\",\n"
                "\t\"center\": [" sprintf( nil "%f" xCenter ) ", " sprintf( nil "%f" yCenter ) "],\n"
            )

            width = segment->width            
        else 
            element = strcat( 
                "{\n\t\"type\": \"arc\",\n"
                "\t\"start\": [" sprintf( nil "%f" xCenter ) ", " sprintf( nil "%f" yCenter ) "],\n"
            )
        )

        element = strcat( 
            element          
            
            "\t\"radius\": " sprintf( nil "%f" radius ) ",\n"
            "\t\"startangle\": " sprintf( nil "%f" startAngle ) ",\n"
            "\t\"endangle\": " sprintf( nil "%f" endAngle ) ",\n"
            "\t\"width\": " sprintf( nil "%f" width ) "\n"
            "}" 
        )
    )
)

procedure( parseSegment( segment @optional ( isEtch nil ) )
    let( ( element )
        case( segment->objType
            (
                "line"
                element = addLine( segment isEtch )        
            )
            (
                "arc"
                if( segment->isCirle then
                    element = addCircle( segment )
                else
                    element = addArc( segment isEtch )
                )
            )
            (
                t
                warn( "Unknown segment ...\n")
            )        
        )    
        element
    )    
)

procedure( addText( object @optional ( textType t ) )
    let( ( xy x y angle attr alignment justify textBlock height width thickness text element )
        xy = object->xy
        x = xCoord( xy )
        y = -yCoord( xy )

        ; get rotation
        angle = object->rotation

        ; check, if text is mirrored
        if( object->isMirrored then
            attr = "\"mirrored\""
        else
            attr = ""
        )

        ; get text alignment
        alignment = object->justify

        case( alignment
            (
                "LEFT"
                justify = "[-1, 1]"
            )
            (
                "RIGHT"
                justify = "[1, 1]"
            )
            (
                "CENTER"
                justify = "[0, 1]"
            )
            (
                t    
                justify = "[0, 1]"
            )            
        )

        case( textType
            (
                "refdes"
                type = ",\n\t\"ref\": 1\n"
            )
            (
                "value"
                type = ",\n\t\"val\": 1\n"
            )
            (
                t
                type = "\n"
            )
        )
        
        ; get text parameters
        textBlock = axlGetParam( strcat( "paramTextBlock:" object->textBlock ) )
        height = textBlock->height
        width = textBlock->width
        thickness = textBlock->photoWidth

        ; escape " correctly"
        pattern = pcreCompile("[\\\"]")
        text = pcreReplace( pattern object->text "\\\\\"" 0 )
 
        element = strcat(
            "{\n"
            "\t\"pos\": [" sprintf( nil "%f" x ) ", " sprintf( nil "%f" y ) "],\n"
            "\t\"text\": \"" text "\",\n"
            "\t\"height\":  " sprintf( nil "%f" height ) ",\n"
            "\t\"width\": " sprintf( nil "%f" width ) ",\n"
            "\t\"justify\": " justify ",\n"
            "\t\"thickness\": " sprintf( nil "%f" thickness ) ",\n"
            "\t\"attr\": [" attr "],\n"
            "\t\"angle\": " sprintf( nil "%f" angle )
            type
            "}"
        ) 
    )
)

procedure( addVia( via layer )
    let( ( xy extents startEnd element ) 
        xy = via->xy

        pad = axlDBGetPad( via layer "REGULAR" ) 
        extents = pad->bBox

        ; calculate the pad diameter
        width = abs( xCoord( cadr( extents ) ) - xCoord( car( extents ) ) )        

        startEnd = strcat( "[" sprintf( nil "%f" xCoord( xy ) ) ", " sprintf( nil "%f" -yCoord( xy ) ) "]" )

        element = strcat( 
            "{\n"
            "\t\"net\": \"" via->net->name "\",\n" 
            "\t\"start\": " startEnd ",\n"
            "\t\"end\": " startEnd ",\n"
            "\t\"width\": " sprintf( nil "%f" width ) "\n"
            "}"            
        )         
    )  
)

procedure( lineToSvgPath( isFirst points ) 
    let( ( ( path 'unbound ) firstCommand segment )

        ; is it the first element in the svgpath
        if( isFirst then
            firstCommand = "M "
        else
            firstCommand = "L "
        )

        foreach( point points      
            segment = buildString( 
                list( 
                    sprintf( nil "%f" xCoord( point ) ) 
                    sprintf( nil "%f" yCoord( point ) )              
                )             
                " "
            )     

            if( boundp( 'path ) then
                tconc( path segment )
            else
                path = tconc( nil segment )
            ) 
        )  
        ; return svgpath    
        path = strcat( firstCommand buildString( car( path ) "L " ) )
    )
)

procedure( arcToSvgPath( isFirst xy startEnd isClockwise @optional ( radius nil ) ( isCircle nil ) ) 
    let( ( start end xArcCenter yArcCenter dx dy startAngle endAngle path sweepFlag dAngle largeArcFlag ) 
        start = car( startEnd )
        end = cadr( startEnd )

        xArcCenter = xCoord( xy )
        yArcCenter = yCoord( xy )                 
            
        dx = xCoord( start ) - xArcCenter
        ; reverse inverted y-axis for angle calculation
        dy = ( yCoord( start ) - yArcCenter ) * - 1 

        ; if no radius was passed, calculate radius
        unless( radius
            radius = sqrt( expt( dx 2 ) + expt( dy 2 ) )
        )

        startAngle = axlRadToDeg( atan2( dy dx ) )   
             
        when( negativep( startAngle )
            startAngle = startAngle + 360    
        )

        dx = xCoord( end ) - xArcCenter
        ; reverse inverted y-axis for angle calculation
        dy = ( yCoord( end ) - yArcCenter ) * - 1
        
        endAngle = axlRadToDeg( atan2( dy dx ) )

        when( negativep( endAngle )
            endAngle = endAngle + 360    
        )

        ; is it the first element in the svgpath
        if( isFirst then
            path = buildString( 
                list( 
                    "M" 
                    sprintf( nil "%f" xCoord( start ) ) 
                    sprintf( nil "%f" yCoord( start ) ) 
                    "A"
                ) 
                " "
            )
        else
            path = "A"
        )

        ; set the sweep-flag and the large-arg-flag                  
        if( isClockwise then   
            sweepFlag = "1"                      

            if( startAngle > endAngle then
                dAngle = startAngle - endAngle
            else
                dAngle = startAngle + ( 360.0 - endAngle )
            )                
        else
            sweepFlag = "0"

            if( startAngle > endAngle then
                dAngle = endAngle + ( 360.0 - startAngle )
            else
                dAngle = endAngle - startAngle
            ) 
        )

        if( dAngle > 180.0 then
            ; make small arc
            largeArcFlag = "1"
        else
            largeArcFlag = "0"
        )    

        ; since start = end for circles
        when( isCircle               
            end = list( ( xCoord( xy ) - radius ) yCoord( xy ) )
        )

        ; A rx ry x-axis-rotation large-arc-flag sweep-flag x y
        path = buildString( 
            list( 
                path 
                sprintf( nil "%f" radius ) 
                sprintf( nil "%f" radius ) 
                sprintf( nil "%f" 0.0 ) 
                largeArcFlag 
                sweepFlag 
                sprintf( nil "%f" xCoord( end ) ) 
                sprintf( nil "%f" yCoord( end ) ) 
            ) 
            " "
        )
       
        ; for circles only
        when( isCircle
            end = start

            path = buildString( 
                list( 
                    path
                    "A"
                    sprintf( nil "%f" radius ) 
                    sprintf( nil "%f" radius ) 
                    sprintf( nil "%f" 0.0 ) 
                    largeArcFlag 
                    sweepFlag 
                    sprintf( nil "%f" xCoord( end ) ) 
                    sprintf( nil "%f" yCoord( end ) ) 
                ) 
                " "
            )
        )    
        path      
    )
)

procedure( textToSvgPath( object @optional ( type t ) )
    let( (  ( svgPath 'unbound )
            textBlock thickness pathLists segments isFirst endPoint path text )        

        ; get text parameters
        textBlock = axlGetParam( strcat( "paramTextBlock:" object->textBlock ) )        
        thickness = textBlock->photoWidth

        case( type
            (
                "refdes"
                type = ",\n\t\"ref\": 1\n"
            )
            (
                "value"
                type = ",\n\t\"val\": 1\n"
            )
            (
                t
                type = "\n"
            )
        )

        ; get list if paths
        pathLists = axlText2Lines( object )

        foreach( pathList pathLists
            ; iterate though paths
            foreach( path pathList          
                ; get path segments
                segments = axlPathGetPathSegs( path )

                foreach( segment segments
                    isFirst = ( lindex( segments segment ) == 1 )

                    endPoint = segment->_endPoint
                    endPoint = list( xCoord( endPoint ) -yCoord( endPoint ) )
                        
                    ; vertice is a list: #1 element is the point, #2 is unimportant to us
                    path = lineToSvgPath( isFirst list( endPoint )  )  
                    
                    if( boundp( 'svgPath ) then
                        tconc( svgPath path )
                    else
                        svgPath = tconc( nil path )
                    )
                )               
            )                   
        )

        svgPath = buildString( car( svgPath ) " " )

        text = strcat(
            "{"
            "\t\"svgpath\": \"" svgPath "\",\n"            
            "\t\"thickness\": " sprintf( nil "%f" thickness )
            type
            "}"
        ) 
    )
)

procedure( createSvgPath( segments )
    let( (  ( paths 'unbound ) 
            isFirst arcCenter xArcCenter yArcCenter 
            radius isClockwise isCircle startEnd start end path svgpath )

        foreach( segment segments
            case( segment->objType
                (                    
                    "arc"        
                    isFirst = ( lindex( segments segment ) == 1 )

                    arcCenter = segment->xy
                    xArcCenter = xCoord( arcCenter )
                    yArcCenter = -yCoord( arcCenter )
                    arcCenter = list( xArcCenter yArcCenter )

                    radius = segment->radius

                    isClockwise = segment->isClockwise
                    isCircle = segment->isCircle

                    startEnd = segment->startEnd

                    start = car( startEnd )
                    start = list( xCoord( start ) -yCoord( start ) )

                    end = cadr( startEnd )
                    end = list( xCoord( end ) -yCoord( end ) )
                    
                    startEnd = list( start end )                    

                    ; create svgpath
                    path = arcToSvgPath( isFirst arcCenter startEnd isClockwise radius isCircle )

                    ; append to list
                    if( boundp( 'paths ) then
                        tconc( paths path )
                    else
                        paths = tconc( nil path )
                    )  
                )   
                (
                    "line"
                    isFirst = ( lindex( segments segment ) == 1 )

                    startEnd = segment->startEnd  
                    
                    start = car( startEnd )
                    start = list( xCoord( start ) -yCoord( start ) )

                    end = cadr( startEnd )
                    end = list( xCoord( end ) -yCoord( end ) )
                    
                    startEnd = list( start end )  

                    ; create svgpath
                    path = lineToSvgPath( isFirst startEnd )  

                    ; append to list
                    if( boundp( 'paths ) then
                        tconc( paths path )
                    else
                        paths = tconc( nil path )
                    )               
                )
                (
                    t
                    printf( "unknown type ... ")
                )
                
            )
        ) 
        
        ; combine and all subpaths and close path ( add Z )
        svgpath = strcat( buildString( car( paths ) " " ) " Z" )
    )
)

procedure( createZone( zone )
    let( (  ( svgpath 'unbound )            
            net segments path voids )

        net = zone->net->name
        segments = zone->segments

        ; draw the copper
        path = createSvgPath( segments )

        if( boundp( 'svgpath ) then
            tconc( svgpath path )
        else
            svgpath = tconc( nil path )
        )             

        ; draw the voids
        voids = zone->voids

        foreach( void voids
            segments = void->segments
            path = createSvgPath( segments )

            ; void can only exist, if a path already exists
            tconc( svgpath path )     
        )   
    
        zone = strcat(
            "{\n"
            "\t\"svgpath\": \"" buildString( car( svgpath ) " " ) "\",\n"  
            "\t\"fillrule\": \"evenodd\",\n"
            "\t\"net\": \"" net "\"\n"
            "}"
        )        
    )
)

procedure( addBoardGeometry( @optional ( expand list( '( 0.0 0.0) '( 0.0 0.0 ) ) ) )
    let( ( ( edges 'unbound ) dsn outline segments extents xStart yStart xEnd yEnd bBox element boardGeometry )

        dsn = axlDBGetDesign()
        outline = dsn->designOutline
        segments = outline->segments
        
        extents =  axlDBGetExtents( segments nil )

        xStart = caar( extents ) - caar( expand )
        yStart = -cadar( extents ) + cadar( expand ) ;multiply by -1, s. ibom y convention
        
        xEnd = caadr( extents ) + caadr( expand )        
        yEnd = -cadadr( extents ) - cadadr( expand ) ; multiply by -1, s. ibom y convention

        bBox = strcat( 
            "{\n"
            "\t\"minx\": " sprintf(nil "%f" xStart ) ",\n"
            "\t\"miny\": " sprintf( nil "%f" yStart ) ",\n"
            "\t\"maxx\": " sprintf(nil "%f" xEnd ) ",\n"
            "\t\"maxy\": " sprintf( nil "%f" yEnd ) "\n"
            "}" 
        )

        foreach( segment segments
            ; parse segment
            element = parseSegment( segment )  
    
            if( boundp( 'edges ) then
                tconc( edges element )
            else
                edges = tconc( nil element )
            )      
        )

        ; add cutout to edges list
        cutout = car( axlDBGetShapes( "BOARD GEOMETRY/CUTOUT" ) )
        segments = cutout->segments

        foreach( segment segments
            ; parse segment
            element = parseSegment( segment )  
    
            if( boundp( 'edges ) then
                tconc( edges element )
            else
                edges = tconc( nil element )
            )      
        )

        ; build string
        edges = buildString( car( edges ) ",\n" )
    
        boardGeometry = strcat( 
            "\"edges_bbox\": \n"
            addIndent( bBox ) ",\n"
            "\"edges\": [\n" 
            addIndent( edges ) "\n"
            "]"
        )   
    )
)

; rotate a vector around 0:0
procedure( rotateVector( point angle )
    let( ( angleRad x y xy )  
        angleRad = axlDegToRad( angle )
        x = car( point ) * cos( angleRad ) - cadr( point ) * sin( angleRad )
        y = car( point ) * sin( angleRad ) + cadr( point ) * cos( angleRad )
        ; return xy
        xy = list( x y )
    )
)

; rotation is the rotation of the symbol, it gets negated in the function
procedure( getBboxSize( segments xOffset yOffset rotation ) 
    let( (  ( xDim 'unbound )
            ( yDim 'unbound )
            points radius xy x y xMin xMax yMin yMax xSize ySize )
        
        foreach( segment segments     
            radius = segment->radius

            if( radius then
                points = segment->bBox
            else
                points = segment->startEnd            
            )
            
            foreach( point points            
                ; transform each point of the segment
                x = car( point ) - xOffset
                y = cadr( point ) * -1 - yOffset
                
                ; because of the negative y-axis it needs to be turned with rotation to make it undone
                xy = rotateVector( list( x y ) rotation )
                
                if( boundp( 'xDim ) then
                    tconc( xDim car( xy ) )
                else
                    xDim = tconc( nil car( xy ) )
                ) 
            
                if( boundp( 'yDim ) then
                    tconc( yDim cadr( xy ) )
                else
                    yDim = tconc( nil cadr( xy ) )
                )
            )
        )

        xDim = car( xDim )
        yDim = car( yDim )

        ; calculate min and max values for the x-dimension
        xMin = car( sort( copy( xDim ) 'lessp ) ) 
        xMax = car( sort( copy( xDim ) 'greaterp ) ) 

        ; calculate min and max values for the y-dimension
        yMin = car( sort( copy( yDim ) 'lessp ) )
        yMax = car( sort( copy( yDim ) 'greaterp ) )   

        xSize = xMax - xMin
        ySize = yMax - yMin

        dxCenter = xMin + xSize / 2
        ; yMax is the lowest point ... since y-axis is inverted
        dyCenter = yMax - ySize / 2

        sizeCenter = list( list( xSize ySize ) list( dxCenter dyCenter ) )
    )
)

procedure( figureToSvgPath( figure xOffset yOffset rotation )
    let( (  ( paths 'unbound ) segments endPoint x y xArcCenter yArcCenter 
        isClockwise loopIteration prevSegment prevEndpoint 
        xPrevEndpoint yPrevEndpoint startPoint path svgpath )
        
        ; convert path to segments
        segments = axlPathGetPathSegs( car( figure ) )

        foreach( segment segments          

            endPoint = segment->_endPoint
            x = xCoord( endPoint ) - xOffset
            y = yCoord( endPoint ) * - 1 - yOffset

            endPoint = rotateVector( list( x y ) rotation )     
            
            if( segment->_arcCenter then                    
                ; ARC             
                arcCenter = segment->_arcCenter
                xArcCenter = xCoord( arcCenter ) - xOffset
                yArcCenter = yCoord( arcCenter ) * -1 - yOffset
                ; perform vector rotation
                arcCenter = rotateVector( list( xArcCenter yArcCenter ) rotation )

                isClockwise = segment->_arcClockwise                

                ; check, if segment is first
                loopIteration = lindex( segments segment )
                isFirst = ( loopIteration == 1 )

                if( isFirst then
                    prevSegment = nthelem( length( segments ) segments )                    
                else 
                    prevSegment = nthelem( sub1( loopIteration ) segments )  
                )

                prevEndpoint = prevSegment->_endPoint
                xPrevEndpoint = xCoord( prevEndpoint ) - xOffset
                yPrevEndpoint = yCoord( prevEndpoint ) * -1 - yOffset
                
                ; because the y-axis is inverted, the vector needs to be rotated in direction of the rotation to make rotation undone
                startPoint = rotateVector( list( xPrevEndpoint yPrevEndpoint ) rotation )               

                ;arcToSvgPath( isFirst xy startEnd isClockwise @optional ( radius nil ) ( isCircle nil ) )  
                path = arcToSvgPath( isFirst arcCenter list( startPoint endPoint ) isClockwise )

                ; append to list
                if( boundp( 'paths ) then
                    tconc( paths path )
                else
                    paths = tconc( nil path )
                ) 
            else         
                ; LINE
                isFirst = ( lindex( segments segment ) == 1 )
                path = lineToSvgPath( isFirst list( endPoint ) )  

                if( boundp( 'paths ) then
                    tconc( paths path )
                else
                    paths = tconc( nil path )
                )     
            )             
        )                   
        svgpath = strcat( buildString( car( paths ) " " ) " Z" )
    ) 
)

procedure( addPad( pin ) 
    let( (  ( padLayers 'unbound ) 
            ( drill 'unbound ) 
            ( pads 'unbound ) 
            xy xPos yPos pos net angle pinOnes pinNumber 
            type padstack startEnd layers pad 
            drillShape drillSize bBox xSize ySize size shape svgpath innerDiameter outerDiameter startInner startOuter )   

        ; get position
        xy = pin->xy
        xPos = car( xy )
        yPos = -cadr( xy )
        
        pos = strcat( 
            "[ " 
            sprintf( nil "%f" xPos ) 
            ", " 
            sprintf( nil "%f" yPos ) 
            "]" 
        )         
        
        ; get net
        net = pin->net->name

        ;add netname, if present
        if( ( net != "" ) && ( net != nil ) then
            net = strcat( "\"" net "\"" )
        else
            net = "\"\""
        )

        ; get pin angle
        angle = sprintf( nil "%f" pin->rotation )

        ; default smd, overwritten later, if needed
        type = "\"smd\""
                
        ; mark pin 1
        pinOnes = list( "1" "A" "A1" )
        pinNumber = pin->number

        if( member( pinNumber pinOnes ) then
            isPinOne = t
        else
            isPinOne = nil
        )
       
        ; get padstack
        padstack = axlLoadPadstack( pin->name ) 
        startEnd = unique( padstack->startEnd )
        
        when( member( "ETCH/TOP" startEnd )             
            padLayers = tconc( nil "ETCH/TOP" )
        )

        when( member( "ETCH/BOTTOM" startEnd ) 
            if( boundp( 'padLayers ) then
                tconc( padLayers "ETCH/BOTTOM" )
            else
                padLayers = tconc( nil "ETCH/BOTTOM" )
            )        
        )

        ; check, if etch is defined
        if( boundp( 'padLayers ) then
            padLayers = car( padLayers )
        else
            ; let pad be defined on top, but size is set to zero later ( mechanical hole )
            padLayers = list( "ETCH/TOP" )          
        )       
        
        ; draw independent pad each layer, only append drilling to first pad
        foreach( padLayer padLayers 
            ; if pin is through all, define holes
            if( pin->isThrough && ( lindex( padLayers padLayer ) == 1 ) then
                type = "\"th\""

                if( padstack->usage == "Slot" then
                    drillShape = "oblong"
                    drillSize = strcat( 
                        "[ "
                        sprintf( nil "%f" padstack->drillSizeWidth )
                        ", "
                        sprintf( nil "%f" padstack->drillSizeHeight )
                        "]"
                    )                  
                else
                    drillShape = "circle"
                    drillSize = strcat( 
                        "[ "
                        sprintf( nil "%f" padstack->drillDiameter )
                        ", "
                        sprintf( nil "%f" 0.0 )
                        "]"
                    )             
                ) 

                drill = strcat(
                    "\"drillshape\": \"" drillShape "\",\n"
                    "\"drillsize\": " drillSize ",\n"
                    "\"offset\": [" sprintf( nil "%f" car( padstack->drillOffset ) ) ", " sprintf( nil "%f" cadr( padstack->drillOffset ) ) "]"
                )            
            else
                type = "\"smd\""                
            )

            if( pin->isMirrored == nil then
                if( padLayer == "ETCH/TOP" then
                    layers = "[\"F\"]"
                    pad = axlDBGetPad( pin, "ETCH/TOP", "REGULAR" ) 
                else
                    layers = "[\"B\"]"
                    pad = axlDBGetPad( pin, "ETCH/BOTTOM", "REGULAR" )  
                )
            else
                if( padLayer == "ETCH/TOP" then
                    layers = "[\"B\"]"
                    pad = axlDBGetPad( pin, "ETCH/BOTTOM", "REGULAR" ) 
                else
                    layers = "[\"F\"]"
                    pad = axlDBGetPad( pin, "ETCH/TOP", "REGULAR" )  
                )                
            )

            ; get pad size
            bBox = pad->bBox               
            xSize = caadr( bBox ) - caar( bBox )
            ySize = cadadr( bBox ) - cadar( bBox )
            
            size = strcat(
                "[ "
                sprintf( nil "%f" xSize )
                ", "
                sprintf( nil "%f" ySize )
                "]"
            )

            case( pad->figureName
                (
                    "CIRCLE"
                    shape = "\"circle\""
                    svgpath = nil
                )
                (   
                    "OCTAGON"
                    shape = "\"custom\""
    
                    when( pad->figure                     
                        svgpath = strcat( 
                            "\"svgpath\": \"" 
                            figureToSvgPath( pad->figure xPos yPos pin->rotation )                            
                            "\""                                           
                        )                                              
                    )
                )                          
                ( 
                    "SQUARE"
                    shape = "\"custom\""
    
                    when( pad->figure                     
                        svgpath = strcat( 
                            "\"svgpath\": \"" 
                            figureToSvgPath( pad->figure xPos yPos pin->rotation )                            
                            "\""                                           
                        )    
                    ) 
                ) 
                ( 
                    "RECTANGLE"
                    shape = "\"custom\""
    
                    when( pad->figure                     
                        svgpath = strcat( 
                            "\"svgpath\": \"" 
                            figureToSvgPath( pad->figure xPos yPos pin->rotation )                            
                            "\""                                           
                        )    
                    )             
                ) 
                ( 
                    "OBLONG_X"
                    shape = "\"custom\""
    
                    when( pad->figure                     
                        svgpath = strcat( 
                            "\"svgpath\": \"" 
                            figureToSvgPath( pad->figure xPos yPos pin->rotation )                            
                            "\""                                           
                        )    
                    )
                )
                (
                    "OBLONG_Y"
                    shape = "\"custom\""
    
                    when( pad->figure                     
                        svgpath = strcat( 
                            "\"svgpath\": \"" 
                            figureToSvgPath( pad->figure xPos yPos pin->rotation )                            
                            "\""                                           
                        )    
                    )
                )
                (
                    "SHAPE"
                    shape = "\"custom\""
    
                    when( pad->figure                     
                        svgpath = strcat( 
                            "\"svgpath\": \"" 
                            figureToSvgPath( pad->figure xPos yPos pin->rotation )                            
                            "\""                                           
                        )    
                    )
                ) 
                (
                    "FLASH" 
                    warn( "Flash pad is not supported ..." )              
    
                ) 
                ( 
                    "DONUT"
                    shape = "\"custom\""
                    innerDiameter = pad->inside
                    outerDiameter = abs( xCoord( cadr( bBox ) ) - xCoord( car( bBox ) ) )

                    ; calculate diameters
                    startOuter = list( ( outerDiameter / 2 ) 0.0 )          
                    startInner = list( ( innerDiameter / 2 ) 0.0 )
                                                            
                    svgpath = strcat( 
                        "\"svgpath\": \""                 
                        arcToSvgPath( t list( 0.0 0.0 ) list( startOuter startOuter ) t outerDiameter/2 t ) " "
                        arcToSvgPath( t list( 0.0 0.0 ) list( startInner startInner ) nil innerDiameter/2 t )
                        "\""                                           
                    )    
                     
                ) 
                ( 
                    "ROUNDED_RECTANGLE"
                    shape = "\"custom\""
    
                    when( pad->figure   
                        svgpath = strcat( 
                            "\"svgpath\": \"" 
                            figureToSvgPath( pad->figure xPos yPos pin->rotation )                            
                            "\""                                           
                        ) 
                    )
                )
                (
                    "CHAMFERED_RECTANGLE"
                    shape = "\"custom\""
    
                    when( pad->figure                     
                        svgpath = strcat( 
                            "\"svgpath\": \"" 
                            figureToSvgPath( pad->figure xPos yPos pin->rotation )                            
                            "\""                                           
                        )    
                    )
                )
                (
                    "N_SIDED_POLY"
                    shape = "\"custom\""
    
                    when( pad->figure                     
                        svgpath = strcat( 
                            "\"svgpath\": \"" 
                            figureToSvgPath( pad->figure xPos yPos pin->rotation )                            
                            "\""                                           
                        )    
                    )
                ) 
                (
                    "NULL"
                    ; pin is mechanical
                    shape = "\"circle\""
    
                    ; set size to zero
                    size = strcat(
                        "[ "
                        sprintf( nil "%f" 0.0 )
                        ", "
                        sprintf( nil "%f" 0.0 )
                        "]"
                    )
                )
                (
                    t
                    error( "Unknown pad shape ..." )
                )            
            )    
               
            ;build pad
            pad = strcat(                
                "\"layers\": " layers ",\n"
                "\"pos\": " pos ",\n"
                "\"size\": " size ",\n"
                "\"angle\": " angle ",\n"
                "\"shape\": " shape ",\n"
                "\"net\": " net ",\n"
                "\"type\": " type
            )

            when( svgpath
                pad = strcat( pad ",\n"
                    svgpath
                )
            )

            when( isPinOne
                pad = strcat( pad ",\n"
                    "\"pin1\": 1"
                )                
            )
    
            ; if present, add the drill information
            when( boundp( 'drill )
                ;build pad
                pad = strcat( pad ",\n" drill )
            )

            pad = strcat( "{\n" addIndent( pad ) "\n}" )

            ; add pad to pad list
            if( boundp( 'pads ) then
                tconc( pads pad )
            else
                pads = tconc( nil pad )
            )

            ; unbind drill for next iteration
            drill = 'unbound
        )
        ; build pads string                
        pads = buildString( car( pads ) ",\n" )       
    )
)

procedure( addComponentTable( @optional ( variantSymbolList 'unbound ) ( alternateParts 'unbound ) )
    let( ( pattern dsn symbols refDes layer value ( extraFields 'unbound ) userProperties extraField component ( components 'unbound ) )

        pattern = pcreCompile( "[\\\"]" )
        percent = pcreCompile( "%" )
        dsn = axlDBGetDesign()

        ; get symbols
        symbols = dsn->symbols   

        foreach( symbol symbols
            refDes = symbol->refdes
            when( refDes

                ; get symbol layer
                if( symbol->layer == "TOP" then
                    layer = "\"F\""
                else
                    layer = "\"B\""
                )

                ; handle alternate parts
                if( boundp( 'alternateParts ) then
                    if( alternateParts[refDes] != nil then
                        value = alternateParts[refDes]
                    else
                        value = cadr( assoc( 'VALUE, axlDBGetProperties( symbol->component->compdef ) ) )                
                    )
                else
                    value = cadr( assoc( 'VALUE, axlDBGetProperties( symbol->component->compdef ) ) )  
                )

                unless( value 
                    value = "undefined"
                )
                
                ; escape " correctly"
                value = pcreReplace( percent value "%%" 0 )
                value = pcreReplace( pattern value "\\\\\"" 0 )

                ;dnp
                when( boundp( 'variantSymbolList )
                    unless( member( symbol variantSymbolList)
                        extraFields = tconc( nil "\"DNP\": \"1\"" )
                    )  
                )

                ; add extra fields
                userProperties = axlDBGetProperties( symbol->component->compdef )

                foreach( userProperty userProperties
                    extraField = strcat( "\"" sprintf( nil "%L" car( userProperty) ) "\": \"" pcreReplace( pattern cadr( userProperty ) "\\\\\"" 0 ) "\"" )
                    ; escape fields correctly
                    extraField = pcreReplace( percent extraField "%%" 0 )

                    if( boundp( 'extraFields ) then
                        tconc( extraFields extraField )
                    else
                        extraFields = tconc( nil extraField )
                    )
                )

                ; make list
                if( boundp( 'extraFields ) then
                    extraFields = car( extraFields )
                    extraFields = strcat( addIndent( buildString( extraFields ",\n" ) ) "\n" )
                else
                    extraFields = ""                    
                )
        
                component = strcat( "{\n"
                    addIndent( strcat(
                        "\"attr\": \"\",\n"
                        "\"footprint\": \"" symbol->component->package "\",\n"
                        "\"layer\": " layer ",\n"
                        "\"ref\": \"" refDes "\",\n" 
                        "\"val\": \"" value "\",\n"                
                        "\"extra_fields\": {\n"
                        extraFields
                        "}"
                        )
                    ) "\n"
                    "}"
                )

                ; append to field list            
                if( boundp( 'components ) then
                    tconc( components component )
                else
                    components = tconc( nil component )
                )

                ; unbind variable
                extraFields = 'unbound
            )
        )

        ; COMPONENTS
        if( boundp( 'components ) then
            components = strcat( 
                "\"components\": [\n"
                addIndent( buildString( car( components ) ",\n" ) ) "\n"
                "]"
            )
        else
            components = "\"components\": []" 
        )
    )   
)

procedure( addFootprint( symbol )
    let( (  ( sizeCenterTop 'unbound )
            ( sizeCenterBottom 'unbound )
            ( sizeTop list( 0.0 0.0 ) )
            ( centerTop list( 0.0 0.0 ) )
            ( sizeBottom list( 0.0 0.0 ) )
            ( centerBottom list( 0.0 0.0 ) )
            ( size 'unbound ) 
            ( pads 'unbound ) 
            ( sizeCenter 'unbound ) 
            ( bBox list( '(0.0 0.0) '(0.0 0.0) ) )
            xy x y xPos yPos angle bBox xSize ySize footprint ) 
      
        ; get reference designator
        refdes = symbol->refdes       

        ; get symbol layer
        if( symbol->layer == "TOP" then
            layer = "\"layer\": \"F\""
        else
            layer = "\"layer\": \"B\""
        )
        
        ; get symbol origin and rotation angle
        xy = symbol->xy
        angle = symbol->rotation

        ; get children of symbol
        children = symbol->children        

        ; loop through children
        foreach( child children          
            when( child->layer == "PACKAGE GEOMETRY/PLACE_BOUND_TOP" && child->objType == "shape"               
                segments = child->segments
                sizeCenterTop = getBboxSize( segments xCoord( xy ) -yCoord( xy ) angle )
                sizeTop = car( sizeCenter )  
                centerTop = cadr( sizeCenter )                              
            )            

            when( child->layer == "PACKAGE GEOMETRY/PLACE_BOUND_BOTTOM" && child->objType == "shape"
                segments = child->segments
                sizeCenterBottom = getBboxSize( segments xCoord( xy ) -yCoord( xy ) angle )
                sizeBottom = car( sizeCenter )  
                centerBottom = cadr( sizeCenter )
            )
        )

        ; if boundary is defined at both layer, combine both
        if( boundp( 'sizeCenterTop ) && boundp( 'sizeCenterBottom ) then
            ; check if there is a difference
            dxCenter = xCoord( centerBottom ) - xCoord( centerTop )
            dyCenter = yCoord( centerBottom ) - yCoord( centerTop )

            dxLeft = ( xCoord( centerBottom ) - xCoord( sizeBottom ) / 2 ) - ( xCoord( centerTop ) - xCoord( sizeTop ) / 2 ) 
            dxRight = ( xCoord( centerBottom ) + xCoord( sizeBottom ) / 2 ) - ( xCoord( centerTop ) + xCoord( sizeTop ) / 2 ) 
            dyBottom = ( yCoord( centerBottom ) - yCoord( sizeBottom ) / 2 ) - ( yCoord( centerTop ) - yCoord( sizeTop ) / 2 ) 
            dyTop = ( yCoord( centerBottom ) + yCoord( sizeBottom ) / 2 ) - ( yCoord( centerTop ) + yCoord( sizeTop ) / 2 ) 

            ; initial values
            xSize = xCoord( sizeTop )
            ySize = yCoord( sizeTop )

            xCenter = xCoord( centerTop )
            yCenter = yCoord( centerTop )
          
            unless( dxLeft > 0.0
                xSize = xSize + dxLeft
                xCenter = xCenter - dxLeft / 2              
            )

            unless( dxRight > 0.0
                xSize = xSize + dxRight
                xCenter = xCenter + dxRight / 2              
            )

            ; negative implies increasing y-size
            unless( dyBottom > 0.0
                ySize = ySize + dyBottom
                yCenter = yCenter + dyBottom / 2              
            )

            unless( dyTop > 0.0
                ySize = ySize + dyTop
                yCenter = yCenter - dyTop / 2              
            )    

            size = list( xSize ySize )
            center = list( xCenter yCenter )
            sizeCenter = list( size center )           
        else
            when( boundp( 'sizeCenterTop )
                size = sizeTop
                center = centerTop
                sizeCenter = list( size center )
            )

            when( boundp( 'sizeCenterBottom ) 
                size = sizeBottom
                center = centerBottom
                sizeCenter = list( size center )
            )        
        )
              
        if( boundp( 'sizeCenter ) then
            xSize = xCoord( size )
            ySize = yCoord( size )

            center = rotateVector( center -angle )
        
            xCenter = xCoord( center )
            yCenter = yCoord( center )
        else
            ; get extents of symbol, if boundary is not defined
            bBox = axlDBGetExtents( symbol nil )
            xSize = caadr( bBox ) - caar( bBox )
            ySize = cadadr( bBox ) - cadar( bBox )

            xCenter = 0.0
            yCenter = 0.0
        )
           
        ; center bBox around 0:0
        bBoxCenter = rotateVector( list( -xSize/2 -ySize/2 ) -angle )   

        ; shift x/y position ( center offset and rotated vector )
        xPos = xCoord( xy ) + xCoord( bBoxCenter ) + xCenter
        yPos = -yCoord( xy ) + yCoord( bBoxCenter ) + yCenter
        
        xRelPos = 0.0
        yRelPos = 0.0     
             
        general = strcat( 
            "\"ref\": \"" refdes "\",\n"
            "\"center\": [" sprintf( nil "%f" xCoord( xy ) ) ", " sprintf( nil "%f" -yCoord( xy ) ) "],\n"
            "\"bbox\": {\n"
            "\t\"pos\": [" sprintf( nil "%f" xPos ) ", " sprintf( nil "%f" yPos ) "],\n"
            "\t\"angle\": " sprintf( nil "%f" angle ) ",\n"
            "\t\"relpos\": [" sprintf( nil "%f" xRelPos ) ", " sprintf( nil "%f" yRelPos ) "],\n"
            "\t\"size\": [" sprintf( nil "%f" xSize ) ", " sprintf( nil "%f" ySize ) "]\n"
            "}"
        )

        ; get pins
        pins = symbol->pins

        ; add each pin
        foreach( pin pins
            pad = addPad( pin )

            if( boundp( 'pads ) then
                tconc( pads pad )
            else
                pads = tconc( nil pad )
            )                                         
        )       

        ; PAD DEFINITION        
        if( boundp( 'pads ) then
            pads = strcat( "\"pads\": [\n" 
                addIndent( buildString( car( pads ) ",\n" ) ) "\n"
                "]"
            ) 
        else        
            pads = "\"pads\": []"  
        )    
              
        ; DRAWINGS
        drawings = "\"drawings\": []"

        ; MERGE FOOTPRINT
        footprint = strcat( 
            "{\n"
            addIndent( buildString( list( general pads drawings layer) ",\n" ) ) "\n"
            "}"
        )
    )        
)

procedure( addSymbols( @optional ( variantSymbolList 'unbound ) ( textsAsSvgPaths t ) ( excludeDNP nil ) )
    let( (  ( silkscreenTop 'unbound ) 
            ( silkscreenBottom 'unbound ) 
            ( fabricationTop 'unbound ) 
            ( fabricationBottom 'unbound )             
            ( footprints 'unbound ) 
            ( nets 'unbound )
            dsn symbols footprint excludeSymbol id sym value package field children segments element silkscreen fabrication drawings syms ) 

        ; get design
        dsn = axlDBGetDesign()

        ; get symbols
        symbols = dsn->symbols           
    
        ; loop through symbols
        foreach( symbol symbols
            ; fill bom
            ; if, symbol has a refdes
            ; make bom
            when( symbol->refdes               
                ; adding all pads
                footprint = addFootprint( symbol )

                ; check if symbol is in variantS
                if( boundp( 'variantSymbolList ) && excludeDNP then
                    if( member( symbol variantSymbolList) then
                        excludeSymbol = nil
                    else 
                        excludeSymbol = t
                    )       
                else
                    excludeSymbol = nil                    
                )

                ; append to field list            
                if( boundp( 'footprints ) then
                    tconc( footprints footprint )
                else
                    footprints = tconc( nil footprint )
                )         

                ; loop through children of symbols
                children = symbol->children

                foreach( child children
                    unless( excludeSymbol
                        case( child->layer 
                            (
                                "PACKAGE GEOMETRY/SILKSCREEN_TOP"  
                                if( ( child->objType == "path" ) || ( child->objType == "shape" ) then                      
                                    segments = child->segments

                                    ; loop though segments of each child
                                    foreach( segment segments
                                        element = parseSegment( segment )                   
                                        if( boundp( 'silkscreenTop ) then
                                            tconc( silkscreenTop element )
                                        else
                                            silkscreenTop = tconc( nil element )
                                        )                  
                                    )
                                else
                                    when( child->objType == "text" 
                                        if( textsAsSvgPaths then 
                                            element = textToSvgPath( child )
                                        else
                                            element = addText( child )
                                        )

                                        if( boundp( 'silkscreenTop ) then
                                            tconc( silkscreenTop element )
                                        else
                                            silkscreenTop = tconc( nil element )
                                        )                                 
                                    )                        
                                ) 
                            )
                            (
                                "PACKAGE GEOMETRY/SILKSCREEN_BOTTOM"
                                if( ( child->objType == "path" ) || ( child->objType == "shape" ) then
                                    segments = child->segments

                                    ; loop though segments of each child
                                    foreach( segment segments
                                        element = parseSegment( segment )                   
                                        if( boundp( 'silkscreenBottom ) then
                                            tconc( silkscreenBottom element )
                                        else
                                            silkscreenBottom = tconc( nil element )
                                        )                  
                                    )
                                else
                                    when( child->objType == "text" 
                                        if( textsAsSvgPaths then 
                                            element = textToSvgPath( child )
                                        else
                                            element = addText( child )
                                        )  

                                        if( boundp( 'silkscreenBottom ) then
                                            tconc( silkscreenBottom element )
                                        else
                                            silkscreenBottom = tconc( nil element )
                                        )                                 
                                    )                        
                                ) 
                            )
                            (
                                "REF DES/SILKSCREEN_TOP"
                                when( child->objType == "text"    
                                    if( textsAsSvgPaths then
                                        element = textToSvgPath( child "refdes" )
                                    else
                                        element = addText( child "refdes" )   
                                    )
                                                        
                                    if( boundp( 'silkscreenTop ) then
                                        tconc( silkscreenTop element )
                                    else
                                        silkscreenTop = tconc( nil element )
                                    )                 
                                )
                            )      
                            (
                                "REF DES/SILKSCREEN_BOTTOM"
                                when( child->objType == "text"    
                                    if( textsAsSvgPaths then
                                        element = textToSvgPath( child "refdes" )
                                    else
                                        element = addText( child "refdes" )   
                                    )
                                                        
                                    if( boundp( 'silkscreenBottom ) then
                                        tconc( silkscreenBottom element )
                                    else
                                        silkscreenBottom = tconc( nil element )
                                    )                 
                                )
                            )  
                            (
                                "COMPONENT VALUE/SILKSCREEN_TOP"
                                when( child->objType == "text"    
                                    if( textsAsSvgPaths then
                                        element = textToSvgPath( child "value" )                                    
                                    else
                                        element = addText( child "value" )
                                    )  

                                    if( boundp( 'silkscreenTop ) then
                                        tconc( silkscreenTop element )
                                    else
                                        silkscreenTop = tconc( nil element )
                                    )                 
                                )
                            )      
                            (
                                "COMPONENT VALUE/SILKSCREEN_BOTTOM"
                                when( child->objType == "text"    
                                    if( textsAsSvgPaths then
                                        element = textToSvgPath( child "value" )                                    
                                    else
                                        element = addText( child "value" )
                                    )     

                                    if( boundp( 'silkscreenBottom ) then
                                        tconc( silkscreenBottom element )
                                    else
                                        silkscreenBottom = tconc( nil element )
                                    )                 
                                )
                            )   
                            (
                                "PACKAGE GEOMETRY/ASSEMBLY_TOP"
                                if( ( child->objType == "path" ) || ( child->objType == "shape" ) then
                                    segments = child->segments

                                    ; loop though segments of each child
                                    foreach( segment segments
                                        element = parseSegment( segment )                   
                                        if( boundp( 'fabricationTop ) then
                                            tconc( fabricationTop element )
                                        else
                                            fabricationTop = tconc( nil element )
                                        )                  
                                    )    
                                else
                                    when( child->objType == "text" 
                                        if( textsAsSvgPaths then 
                                            element = textToSvgPath( child )
                                        else
                                            element = addText( child )
                                        )  

                                        if( boundp( 'fabricationTop ) then
                                            tconc( fabricationTop element )
                                        else
                                            fabricationTop = tconc( nil element )
                                        )                                 
                                    )                        
                                )                                            
                            )
                            (
                                "PACKAGE GEOMETRY/ASSEMBLY_BOTTOM"                        
                                if( ( child->objType == "path" ) || ( child->objType == "shape" ) then
                                    segments = child->segments

                                    ; loop though segments of each child
                                    foreach( segment segments
                                        element = parseSegment( segment )                   
                                        if( boundp( 'fabricationBottom ) then
                                            tconc( fabricationBottom element )
                                        else
                                            fabricationBottom = tconc( nil element )
                                        )                  
                                    )
                                else
                                    when( child->objType == "text" 
                                        if( textsAsSvgPaths then 
                                            element = textToSvgPath( child )
                                        else
                                            element = addText( child )
                                        ) 

                                        if( boundp( 'fabricationBottom ) then
                                            tconc( fabricationBottom element )
                                        else
                                            fabricationBottom = tconc( nil element )
                                        )                                 
                                    )                        
                                ) 
                            )        
                            (
                                "REF DES/ASSEMBLY_TOP"
                                when( child->objType == "text"    
                                    if( textsAsSvgPaths then
                                        element = textToSvgPath( child "refdes" )
                                    else
                                        element = addText( child "refdes" )   
                                    )
                                                    
                                    if( boundp( 'fabricationTop ) then
                                        tconc( fabricationTop element )
                                    else
                                        fabricationTop = tconc( nil element )
                                    )                 
                                )
                            )      
                            (
                                "REF DES/ASSEMBLY_BOTTOM"
                                when( child->objType == "text"    
                                    if( textsAsSvgPaths then
                                        element = textToSvgPath( child "refdes" )
                                    else
                                        element = addText( child "refdes" )   
                                    )
                                                        
                                    if( boundp( 'fabricationBottom ) then
                                        tconc( fabricationBottom element )
                                    else
                                        fabricationBottom = tconc( nil element )
                                    )                 
                                )
                            )    
                            (
                                "COMPONENT VALUE/ASSEMBLY_TOP"
                                when( child->objType == "text"  
                                    if( textsAsSvgPaths then
                                        element = textToSvgPath( child "value" )                                    
                                    else
                                        element = addText( child "value" )
                                    )
                                    
                                    if( boundp( 'fabricationTop ) then
                                        tconc( fabricationTop element )
                                    else
                                        fabricationTop = tconc( nil element )
                                    )                 
                                )
                            )      
                            (
                                "COMPONENT VALUE/ASSEMBLY_BOTTOM"
                                when( child->objType == "text"    
                                    if( textsAsSvgPaths then
                                        element = textToSvgPath( child "value" )                                    
                                    else
                                        element = addText( child "value" )
                                    )  

                                    if( boundp( 'fabricationBottom ) then
                                        tconc( fabricationBottom element )
                                    else
                                        fabricationBottom = tconc( nil element )
                                    )                 
                                )
                            )   
                            ; OTHER LAYERS, WHICH HAVE TO BE CONSIDERED, CAN BE ADDED HERE
                            (
                                t
                                ; ignored
                            )
                        )
                    ) 
                )    
            )   
        ) 

        ; TOP SILKSCREEN
        if( boundp( 'silkscreenTop ) then
            silkscreenTop = strcat( 
                "\"F\": [\n" 
                addIndent( buildString( car( silkscreenTop ) ",\n" ) ) "\n"
                "]"
            )    
        else
            silkscreenTop = "\"F\": []"                    
        )

        ; BOTTOM SILKSCREEN
        if( boundp( 'silkscreenBottom )  then
            silkscreenBottom = strcat( 
                "\"B\": [\n" 
                addIndent( buildString( car( silkscreenBottom ) ",\n" ) ) "\n"
                "]"
                ) 
        else
            silkscreenBottom = "\"B\": []"  
        )

        ; silkscren data in JSON format
        silkscreen = strcat( 
            "\"silkscreen\": {\n" 
            addIndent( buildString( list( silkscreenTop silkscreenBottom ) ",\n" ) ) "\n"
            "}" 
            )

        ; TOP ASSEMBLY
        if( boundp( 'fabricationTop ) then
            fabricationTop = strcat( 
                "\"F\": [\n" 
                addIndent( buildString( car( fabricationTop ) ",\n" ) ) "\n" 
                "]"
            )    
        else
            fabricationTop = "\"F\": []"                    
        )

        ; BOTTOM ASSEMBLY
        if( boundp( 'fabricationBottom )  then
            fabricationBottom = strcat( 
                "\"B\": [\n" 
                addIndent( buildString( car( fabricationBottom ) ",\n" ) ) "\n" 
                "]"
            ) 
        else
            fabricationBottom = "\"B\": []"  
        )
        
        ; fabrication data in JSON format
        fabrication = strcat( "\"fabrication\": {\n"
            addIndent( buildString( list( fabricationTop fabricationBottom ) ",\n" ) ) "\n"
            "}"
        )
        
        ; combine silkscreen and fabrication layer in drawings
        drawings = strcat( "\"drawings\": {\n" 
            addIndent( buildString( list( silkscreen fabrication ) ",\n" ) ) "\n"
            "}"
        )

        ; FOOTPRINTS
        if( boundp( 'footprints ) then
            footprints = strcat( 
                "\"footprints\": [\n"
                addIndent( buildString( car( footprints ) ",\n" ) ) "\n"
                "]"
            )
        else
            footprints = "\"footprints\": []" 
        )

        syms = buildString( list( drawings footprints ) ",\n" )       
    )
)

procedure( addCopper()
    let( (  ( tracksTop 'unbound ) 
            ( tracksBottom 'unbound ) 
            ( zonesTop 'unbound )
            ( zonesBottom 'unbound )
            dsn nets branches children segments track zone ) 
        dsn = axlDBGetDesign()
        nets = dsn->nets
        
        ; find the dummy nets
        axlClearSelSet()
        noNet = axlSelectByName("NET" "Dummy" )
        axlClearSelSet()

        ; append dummy nets to net list, to draw the copper
        when( noNet
            nets = nconc( nets noNet )            
        )

        foreach( net nets
            branches = net->branches

            foreach( branch branches 
                children = branch->children

                foreach( child children 
                    case( child->objType
                        (
                            "path"
                            segments = child->segments

                            ; loop though segments of each child
                            foreach( segment segments
                                track = parseSegment( segment t ) 
                                
                                case( child->layer 
                                    (
                                        "ETCH/TOP"
                                        if( boundp( 'tracksTop ) then
                                            tconc( tracksTop track )
                                        else
                                            tracksTop = tconc( nil track )
                                        ) 
                                    )
                                    (
                                        "ETCH/BOTTOM"
                                        if( boundp( 'tracksBottom ) then
                                            tconc( tracksBottom track )
                                        else
                                            tracksBottom = tconc( nil track )
                                        ) 
                                    )
                                    (
                                        t
                                    )
                                )                 
                            )

                        )
                        (
                            "pin"
                        )
                        (
                            "shape"                          
                            zone = createZone( child )

                            case( child->layer 
                                ( 
                                    "ETCH/TOP"                                   
                                    if( boundp( 'zonesTop ) then
                                        tconc( zonesTop zone )
                                    else
                                        zonesTop = tconc( nil zone )
                                    ) 
                                )
                                (
                                    "ETCH/BOTTOM"
                                    if( boundp( 'zonesBottom ) then
                                        tconc( zonesBottom zone )
                                    else
                                        zonesBottom = tconc( nil zone )
                                    ) 
                                )
                                (
                                    t
                                )                         
                            )                   
                        )
                        (
                            "tee"
                            ; a tee is only a point, there is nothing to draw
                        )
                        (
                            "via"                                 
                            element = addVia( child "ETCH/TOP" )                                    
                            if( boundp( 'tracksTop ) then
                                tconc( tracksTop element )
                            else
                                tracksTop = tconc( nil element )
                            ) 

                            element = addVia( child "ETCH/BOTTOM" )
                            if( boundp( 'tracksBottom ) then
                                tconc( tracksBottom element )
                            else
                                tracksBottom = tconc( nil element )
                            )
                        )
                        (
                            t
                            printf( "%s was not considered ... \n" child->objType )
                        )                        
                    )
                )                              
            )            
        )   

        ; COPPER TOP
        if( boundp( 'tracksTop )  then
            tracksTop = strcat( 
                "\"F\": [\n" 
                addIndent( buildString( car( tracksTop ) ",\n" ) ) "\n" 
                "]"
            ) 
        else
            tracksTop = "\"F\": []"  
        )

        if( boundp( 'zonesTop )  then
            zonesTop = strcat( 
                "\"F\": [\n" 
                addIndent( buildString( car( zonesTop ) ",\n" ) ) "\n" 
                "]"
            ) 
        else
            zonesTop = "\"F\": []"  
        )

        ; COPPER BOTTOM
        if( boundp( 'tracksBottom )  then
            tracksBottom = strcat( 
                "\"B\": [\n" 
                addIndent( buildString( car( tracksBottom ) ",\n" ) ) "\n" 
                "]"
            ) 
        else
            tracksBottom = "\"B\": []"  
        )

        if( boundp( 'zonesBottom )  then
            zonesBottom = strcat( 
                "\"B\": [\n" 
                addIndent( buildString( car( zonesBottom ) ",\n" ) ) "\n" 
                "]"
            ) 
        else
            zonesBottom = "\"B\": []"  
        )

        ; track data in JSON format
        tracks = strcat( "\"tracks\": {\n"
            addIndent( buildString( list( tracksTop tracksBottom ) ",\n" ) ) "\n"
            "}"
        )  
        
        ; track data in JSON format
        zones = strcat( "\"zones\": {\n"
            addIndent( buildString( list( zonesTop zonesBottom ) ",\n" ) ) "\n"
            "}"
        ) 

        copper = buildString( list( tracks zones ) ",\n" )
    )
)

procedure( addNets() 
    let( ( (netList 'unbound ) )
        dsn = axlDBGetDesign()
        nets = dsn->nets       

        foreach( net nets 
            if( boundp( 'netList ) then
                tconc( netList strcat( "\"" net->name "\"" ) )
            else
                netList = tconc( nil strcat( "\"" net->name "\"" ) )
            )            
        )

        netList = car( netList )
        netList = strcat( "\"nets\": [" buildString( netList ", " ) "]" )        
    )
)

procedure( writeJsonFile( @key ( variant nil ) ( symbols 'unbound ) ( alternateParts 'unbound ) ( textsAsSvgPaths t ) ( excludeDNP nil ) ( rev "" ) ( company "" ) )
    let( ( outPort pcbData )
        workingDir = getWorkingDir()
        dsnName = axlCurrentDesign()
        fileName = dsnName

        when( variant
            dsnName = strcat( dsnName " - " variant )            
            fileName = lowerCase( strcat( fileName "_" variant ) )
        )                

        jsonDir = buildString( list( workingDir "json" ) "/" )
        outFile = strcat( jsonDir "/" fileName ".json" ) 

        ; create directory if not existing
        unless( isDir( jsonDir )
            createDir( jsonDir )
        )

        ; check if directory was created successfully
        if( isDir( jsonDir ) then
            ; open port
            outPort = outfile( outFile )

            ; check if port exists
            if( outPort then
                ; build json string
                pcbData = strcat( "{\n"            
                    addIndent(
                        strcat( 
                            "\"spec_version\": 1, \n"
                            "\"pcbdata\": {\n" 
                            addIndent(    
                                strcat(     
                                    buildString( list(
                                        addMetadata( dsnName rev company )
                                        addBoardGeometry( list( '( 10.0 10.0 ) '( 10.0 10.0 ) ) )
                                        addSymbols( symbols textsAsSvgPaths excludeDNP )            
                                        )             
                                        ",\n" 
                                    )              
                                    "\n"
                                )
                            ) ",\n"
                            addCopper() ",\n"
                            addNets() "\n" 
                            "},\n"                    
                            addComponentTable( symbols alternateParts )
                            "\n"
                        )                 
                    ) "\n"
                    "}"
                )

                ; to prevent fprintf insufficient memory error
                lines = parseString( pcbData "\n" )

                foreach( line lines
                    fprintf( outPort line )
                    fprintf( outPort "\n" )
                )               

                close( outPort )                
                print( "Export complete!" )

            else 
                axlUIConfirm( "Can not open file or write to file ..." 'error )
                ; error( "Can not open file or write to file ..." )  
            )
        else
            ; error( "Directory was not created ..." ) 
            axlUIConfirm( "Directory was not created ..." 'error )
        )
    )    
)

procedure( getVariantInfo()
    let( (  (   variantFile "Variants.lst" ) 
                ( state "findVariant" )
                pattern valueExpr inPort currentVariant variantTable alternateParts  symbols )       

        pattern = pcreCompile("[()]")
        valueExpr = pcreCompile( "VALUE=" )

        inPort = infile( variantFile )

        if( inPort then 

            variantTable = makeTable( "variantTable" nil )
            alternateParts = makeTable( "alternateParts" nil )

            while( gets( line inPort ) 

                case( state 
                    (
                        "findVariant"
                        ; parse for \"
                        subStrings = parseString( line "\"" )


                        when( length( subStrings ) == 3
                            currentVariant = nth( 1 subStrings )
                            state = "awaitStartCondition"
                        )
                    )
                    (
                        "awaitStartCondition"
                        when( strcmp( line "\t\t(base\n" ) == 0
                            state = "appendSymbols"  
                            symbols = list()               
                        )
                    )
                    ( 
                        "appendSymbols"
                        if( strcmp( line "\t\t)\n" ) == 0 then
                            state = "awaitEndCondition"
                        else
                            ;append symbols to list
                            symbols = nconc( symbols parseString( line ) )
                        )
                    )
                    (
                        "awaitEndCondition"
                        if( strcmp( line "\t)\n" ) == 0 then
                            ;remove ")" in list
						    symbols = remove( ")" symbols )    
						    symbols = mapcar( lambda( ( symbol ) pcreReplace( pattern symbol "" 0 ) )  symbols )						

                            variantTable[currentVariant] = symbols
                            state = "findVariant"
                        else
                            ; find variant specific information                            
                            subStrings = parseString( line )                            
                            when( length( subStrings ) > 1
                                refDes = pcreReplace( pattern nth( 0 subStrings ) "" 0 )
                                
                                foreach( subString subStrings
                                    when( pcreMatchp( valueExpr subString )
                                        value = parseString( subString "\"" )
                                        alternateParts[refDes] = nth( 1 value )
                                    )                                    
                                )

                                symbols = nconc( symbols list( nth( 0 subStrings ) ) )
                            )                            
                        )
                    )
                    (
                        t
                        warn( "I should not be here ... " )
                    )                   
                )     
            )            
            list( variantTable alternateParts )
        else
            error( "Can not read from file ... " )            
            nil
        )                  
    )    
)

procedure( exportJson( @key ( textsAsSvgPaths t ) ( excludeDNP nil ) ( rev "" ) ( company "" ) )
    let( ( ( variantFile "Variants.lst" ) variantInformation variantSymbolList alternateParts symbols )
        
        ; information
        unless( textsAsSvgPaths
            warn( "External font_data is used, text may look different ... " )
        )

        when( excludeDNP
            warn( "Outlines and texts of non-placed components are ignored ... \n" )
        )

        if( isFile( variantFile ) then
            variantInformation = getVariantInfo()

            if( variantInformation then
                variantSymbolList = car( variantInformation )
                alternateParts = cadr( variantInformation )

                foreach( key variantSymbolList
                    printf( "Exporting .json for variant: %s\n" key )

                    ; build symbol list
                    symbols = mapcar( lambda( ( refdes ) axlDBFindByName( 'refdes refdes )->symbol ) variantSymbolList[key] )
                    writeJsonFile( ?variant key ?symbols symbols ?alternateParts alternateParts ?textsAsSvgPaths textsAsSvgPaths ?excludeDNP excludeDNP ?rev rev ?company company )                
                )        
            else
                error( "Tables could not be created ... " ) 
            )
        else
            ; if no variant is available
            warn( "No variant.lst found, exporting entire design ... ")
            writeJsonFile( ?textsAsSvgPaths textsAsSvgPaths )        
        )  
    )
)