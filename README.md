# JSON export for Allegro PCB designs
**Skill script for Allegro PCB Designer to generate a JSON file representing the design.**

The generated json file complies to the [schema](https://github.com/openscopeproject/InteractiveHtmlBom/tree/master/InteractiveHtmlBom/ecad/schema), that is needed to generate the [InteractiveHtmlBom](https://github.com/openscopeproject/InteractiveHtmlBom).

[A demo is worth a thousand words.](https://openscopeproject.org/InteractiveHtmlBomDemo/)

## Prerequisites
To make the skill script available for use, you need to copy the `exportJson.il` file to your local skill directory ( usually your installation path + `\share\pcb\etc` ) or the skill directory in the `$CDS_SITE` path. Append it to the `allegro.ilinit` file ( add `load( "path/exportJson.il" )` ) or load it manually via the skill load command ( type `set telskill` into the command line and then type `load("exportJson.il" )`.

## Usage
Once the script is loaded successfully, you can start exporting the json file by typing `exportJson + enter` in the command line.
A directory named `json` is created in your project folder containing the `.json`.

The script uses the "project name" ( optional:  + "_" + "variant" ) as the file name and asks for the optional arguments `revision` and `company`. By passing `?rev "xyz"` and `?company "name"` as arguments to the `exportJson` function, the input prompt is suppressed and these values are used for file generation. This is can be useful to customize the function to your needs.

### Optional arguments
| argument | description | type |
| ------| ------ | ------ |
| ?exportInnerLayers | default: nil, exports the inner layers | bool |
| ?textAsSvgPaths | default: t, uses font-data otherwise | bool |
| ?excludeDNP | default: nil, all fabrication and silkscreen data of an unplaced component are ignored | bool |
| ?pcbLineWidth | override value | float |
| ?fabricationLayerLinewidth | override value | float |
| ?silkscreenLayerLinewidth | override value | float |
| ?margin | extra spacing for displaying | list / float |
| ?rev | revision | string |
| ?company | company name | string |

## Linewidths
Without appending any additional arguments to the `exportJson` function, the linewidth of every segment is assigned to its original value. However, in some cases you may want to use a different and consistent linewidth as used in the pcb design. In this case three optional arguments can be passed to override the linewidth of pcb outline (`?pcbLinewidth`), the fabrication layer (`?fabricationLayerLinewidth`) and the silkscreen layer (`silkscreenLayerLinewidth`). For example: 
```
    exportJson( ?pcbLinewidth 0.1 ?fabricationLayerLinewidth 0.2 ?silkscreenLayerLinewidth 0.2 )
```
uses a 0.1 unit linewidth for the pcb outline and a linewidth of 0.2 unit for the fabrication and the silkscreen layer.

## Margin
Because the extents are defined by the pcb's minimum and maximum x/y values you may want to add some extra spacing. The function call below, adds a spacing of 20.0 unit to all four directions ( `list( '( spacingLeft spacingBottom ) '( spacingRight spacingTop ) )` ).
```
    exportJson( ?margin list( '( 20.0 20.0 ) '( 20.0 20.0 ) ) )
```

## Texts
Texts are represented as `svgpaths` by default. If you want to use custom `font_data` or the newstroke font you can pass the optional argument `?textsAsSvgPaths nil` to the export function( `exportJson( ?textsAsSvgPaths nil )` ) and the texts are described as defined in [DATAFORMAT.md](https://github.com/openscopeproject/InteractiveHtmlBom/blob/master/DATAFORMAT.md#text).

## Variants and alternate parts
If no `variants.lst` is present in the `allegro` directory, a warning is displayed in the command prompt and all components are considered in the json file; otherwise a json file for each variant is created and the `DNP` field in the `extra_fields` is set to mark unplaced components.
When an alternate part are used, the value of the part is changed to the value of the alternate part.

By passing the optional argument `?excludeDNP t` to the export function ( `exportJson( ?excludeDNP t )` ) all fabrication and silkscreen data of an unplaced component are ignored.

Parts with no reference designator assigned are not included in the interactive BOM.

## Custom properties
Any custom properties assigned to a component are added to the `extra_fields`.

## Layer Mapping
Only the following layers are considered for file creation:

| ibom | allegro |
| ------| ------ |
| edges | BOARD GEOMETRY/DESIGN_OUTLINE<br>BOARD GEOMETRY/CUTOUT
| fabrication | PACKAGE GEOMETRY/ASSEMBLY_TOP<br>PACKAGE GEOMETRY/ASSEMBLY_BOTTOM<br>REF DES/ASSEMBLY_TOP<br>REF DES/ASSEMBLY_BOTTOM<br>COMPONENT_VALUE/ASSEMBLY_TOP<br>COMPONENT_VALUE/ASSEMBLY_BOTTOM |
| silkscreen | PACKAGE GEOMETRY/SILKSCREEN_TOP<br>PACKAGE GEOMETRY/SILKSCREEN_BOTTOM<br>REF DES/SILKSCREEN_TOP<br>REF DES/SILKSCREEN_BOTTOM<br>COMPONENT_VALUE/SILKSCREEN_TOP<br>COMPONENT_VALUE/SILKSCREEN_BOTTOM |

## Call interactive HTML BOM from allegro
If you want to export the json file and convert it to the ibom in one step, you can use the code snippet below to write your own script.
For `ibomArgs` see [command line options](https://github.com/openscopeproject/InteractiveHtmlBom/wiki/Usage#command-line-options).
```
ibomSourcePath = ...

when( ibomSourcePath
    ibomPythonFile = strcat( ibomSourcePath "generate_interactive_bom.py" )		
)

ibomArgs = "--name %f --dnp-field DNP --show-fabrication --hide-silkscreen --dest-dir ../ibom --layer-view F --dark-mode --no-browser"

workingDir = getWorkingDir()

; list create files in json directory
files = getDirFiles( "json" ) 

foreach( file files 
    subStrings = parseString( file "." )

    ; if file is json file
    when( car( last( subStrings ) ) == "json" 
        fullFilePath = strcat( "\"" buildString( list( workingDir "json" file ) "/" ) "\"" )
        command = buildString( list( "python" ibomPythonFile fullFilePath ibomArgs ) )
        result = shell( command )	

        unless( result				
            axlUIConfirm( "Error during ibom generation ..." 'error )
        )
    )						
)				
axlUIConfirm( "Process finished!" 'info )
```
## Example
As an example I have done the json export and the ibom creation for the [AD-FMCOMMS3-EBZ](https://wiki.analog.com/resources/eval/user-guides/ad-fmcomms3-ebz/hardware) design, which `.brd` file is freely accessible.
