# JSON export for Allegro PCB designs
**Skill script for Allegro PCB Designer to generate a JSON file representing the design.**

The generated json file complies to the [schema](https://github.com/openscopeproject/InteractiveHtmlBom/tree/master/InteractiveHtmlBom/ecad/schema), that is needed to generate the [InteractiveHtmlBom](https://github.com/openscopeproject/InteractiveHtmlBom).

## Prerequisites
To make the skill script available for use, you need to copy the `exportJson.il` file to your local skill directory ( usually your installation path + `\share\pcb\etc` ) or the skill directory in the `$CDS_SITE` path. Append it to the `allegro.ilinit` file ( add `load( "path/exportJson.il" )` ) or load it manually via the skill load command ( type `set telskill` into the command line and then type `load("exportJson.il" )`.

## Usage
Once the script is loaded successfully, you can start exporting the json file by typing `exportJson + enter` in the command line.
A directory named `json` is created in your project folder containing the `.json`.

The script uses the "project name" ( optional:  + "_" + "variant" ) as the file name and asks for the optional arguments `revision` and `company` but you can pass the revision and company name as arguments to the `addMetadata` function by changing the code. The input prompt is than suppressed.

## Variants and alternate parts
If no `variants.lst` is present in the `allegro` directory, a warning is displayed in the command prompt and all components are considered in the json file; otherwise a json file for each variant is created. 
When an alternate part are used, the value of the part is changed to the value of the alternate part.

## Layer Mapping
Only the following layers are considered for file creation:

| Ibom | Allegro |
| ------| ------ |
| edges | BOARD GEOMETRY/DESIGN_OUTLINE<br>BOARD GEOMETRY/CUTOUT
| Fabrication | PACKAGE GEOMETRY/ASSEMBLY_TOP<br>PACKAGE GEOMETRY/ASSEMBLY_BOTTOM<br>REF DES/ASSEMBLY_TOP<br>REF DES/ASSEMBLY_BOTTOM<br>COMPONENT_VALUE/ASSEMBLY_TOP<br>COMPONENT_VALUE/ASSEMBLY_BOTTOM |
| Silkscreen | PACKAGE GEOMETRY/SILKSCREEN_TOP<br>PACKAGE GEOMETRY/SILKSCREEN_BOTTOM<br>REF DES/SILKSCREEN_TOP<br>REF DES/SILKSCREEN_BOTTOM<br>COMPONENT_VALUE/SILKSCREEN_TOP<br>COMPONENT_VALUE/SILKSCREEN_BOTTOM |

## Example
As an example I have done the json export and the ibom creation for the [AD-FMCOMMS3-EBZ](https://wiki.analog.com/resources/eval/user-guides/ad-fmcomms3-ebz/hardware) design, which `.brd` files are freely accessible.