# JSON export for Allegro PCB designs
**Skill script for Allegro PCB Designer to generate a JSON file representing the design.**

The generated json file complies to the [schema](https://github.com/openscopeproject/InteractiveHtmlBom/tree/master/InteractiveHtmlBom/ecad/schema), that is needed to generate the [InteractiveHtmlBom](https://github.com/openscopeproject/InteractiveHtmlBom).

[A demo is worth a thousand words.](https://openscopeproject.org/InteractiveHtmlBomDemo/)

## Prerequisites
To make the skill script available for use, you need to copy the `exportJson.il` file to your local skill directory ( usually your installation path + `\share\pcb\etc` ) or the skill directory in the `$CDS_SITE` path. Append it to the `allegro.ilinit` file ( add `load( "path/exportJson.il" )` ) or load it manually via the skill load command ( type `set telskill` into the command line and then type `load("exportJson.il" )`.

## Usage
Once the script is loaded successfully, you can start exporting the json file by typing `exportJson + enter` in the command line.
A directory named `json` is created in your project folder containing the `.json`.

The script uses the "project name" ( optional:  + "_" + "variant" ) as the file name and asks for the optional arguments `revision` and `company` but you can pass the revision and company name as arguments to the [`addMetadata`](https://github.com/juulsA/exportJson/blob/00f01b0105800a2920b9ec6f3041799332a9ff84/exportJson.il#L3) function by changing this [line](https://github.com/juulsA/exportJson/blob/00f01b0105800a2920b9ec6f3041799332a9ff84/exportJson.il#L2048) to your needs. The input prompt is then suppressed.

## Variants and alternate parts
If no `variants.lst` is present in the `allegro` directory, a warning is displayed in the command prompt and all components are considered in the json file; otherwise a json file for each variant is created and the `DNP` field in the `extra_fields` is set to mark unplaced components.
When an alternate part are used, the value of the part is changed to the value of the alternate part.

By passing the optional argument `excludeTexts = t` to the export function ( `exportJson( t )` ) all texts of an unplaced component are ignored.

## Custom properties
Any custom properties assigned to a component are added to the `extra_fields`.

## Layer Mapping
Only the following layers are considered for file creation:

| ibom | allegro |
| ------| ------ |
| edges | BOARD GEOMETRY/DESIGN_OUTLINE<br>BOARD GEOMETRY/CUTOUT
| fabrication | PACKAGE GEOMETRY/ASSEMBLY_TOP<br>PACKAGE GEOMETRY/ASSEMBLY_BOTTOM<br>REF DES/ASSEMBLY_TOP<br>REF DES/ASSEMBLY_BOTTOM<br>COMPONENT_VALUE/ASSEMBLY_TOP<br>COMPONENT_VALUE/ASSEMBLY_BOTTOM |
| silkscreen | PACKAGE GEOMETRY/SILKSCREEN_TOP<br>PACKAGE GEOMETRY/SILKSCREEN_BOTTOM<br>REF DES/SILKSCREEN_TOP<br>REF DES/SILKSCREEN_BOTTOM<br>COMPONENT_VALUE/SILKSCREEN_TOP<br>COMPONENT_VALUE/SILKSCREEN_BOTTOM |

## Example
As an example I have done the json export and the ibom creation for the [AD-FMCOMMS3-EBZ](https://wiki.analog.com/resources/eval/user-guides/ad-fmcomms3-ebz/hardware) design, which `.brd` file is freely accessible.

## Open tasks
- [ ] add a second optional argument to the `exportJson` function ( or expand the current text removal ) to suppress all fabrication and silkscreen data for `DNP` components ( inspired by [qu1ck](https://github.com/openscopeproject/InteractiveHtmlBom/issues/336#issuecomment-1323722800) )
- [ ] generate pads as `svgpaths` instead of `polygons`
- [ ] generate the `font_data` from allegro and append it to the json file
