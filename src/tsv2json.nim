############################################################
##
##   Gets TSV records from file or stdin
##   and yields same content formatted as JSON to stdout
##
############################################################

# nim -f c -d:danger --app:console --opt:speed --passc:-flto tsv2json.nim && strip -s tsv2json && upx --best tsv2json

import terminal, strutils, parseopt, os

let my_version = "0.1.7"
let my_name = getAppFilename().splitPath.tail

var
  input_file: File
  this_record: string
  num_of_tabs_in_this_record: int
  num_of_fields_in_this_record_base1: int
  num_of_errors_found: int
  num_of_errors_corrected: int
  num_of_records_processed: int
  num_of_lines_processed: int
  num_of_fields_in_header_base1: int
  there_was_crisis: bool = false
  be_verbose: bool = false


proc show_version =
  stderr.writeLine my_name & ", version " & my_version
  echo ""


proc show_help =
  show_version()
  stderr.writeLine """
Usage:
    tsv2json infile.tsv  [>outfile.json]
    tsv2json <infile.tsv [>outfile.json]
    tsv2json [option]

Options:
    -h, --help              Display this message
    -v, --version           Print version info and exit
    -V, --verbose           Print more explicit messages

Authors:
    Héctor M. Monacci (2019)
"""


proc show_statistics =
  var crisis_color: ForegroundColor
  if there_was_crisis:
    crisis_color = fgRed
  else:
    crisis_color = fgGreen
  stderr.styledWriteLine styleBright, crisis_color, $num_of_lines_processed & " lines read."
  stderr.styledWriteLine styleBright, crisis_color, $num_of_records_processed & " records processed."
  if num_of_errors_found > 0:
    stderr.styledWriteLine styleBright, crisis_color, $num_of_errors_found & " errors found."
    stderr.styledWriteLine styleBright, crisis_color, $num_of_errors_corrected & " errors corrected."


proc alert_and_exit =
  num_of_fields_in_this_record_base1 = num_of_tabs_in_this_record + 1
  stderr.styledWriteLine styleBright, fgRed, "Error: header line has " & $num_of_fields_in_header_base1 & " fields but this record has " & $num_of_fields_in_this_record_base1 & ":"
  stderr.writeLine this_record.replace("\t", "\n")
  stderr.styledWriteLine styleBright, fgRed, "The above error was found at line " & $num_of_lines_processed & " of TSV input."
  there_was_crisis = true
  show_statistics()
  quit QuitFailure


proc cmdline =
  input_file = stdin

  var has_parameters: bool = false

  for kind, key, value in getOpt():
    has_parameters = true
    case kind
    of cmdArgument:
      if existsFile key:
        input_file = open key
      else:
        stderr.styledWriteLine styleBright, fgRed, "Error: cannot find file \"" & key & "\"."
        quit QuitFailure
    of cmdLongOption, cmdShortOption:
      case key
      of "h", "help":
        show_help()
        quit QuitSuccess
      of "v", "version":
        show_version()
        quit QuitSuccess
      of "V", "verbose":
        be_verbose = true
      else:
        stderr.styledWriteLine styleBright, fgRed, "Error: unknown option: \"" & key & "\"."
        stderr.writeLine ""
        show_help()
        quit QuitFailure
    of cmdEnd:
      discard

  if has_parameters == false:
    if isatty(stdin):
      show_help()
      quit QuitSuccess


proc main =
  var
    header: string
    fields_in_header: seq[string]
    num_of_fields_in_header_base0: int
    is_first_record: bool = true
    fields_in_this_record: seq[string]
    num_of_tabs_in_header: int
    completion_record: string

  cmdline()

  if input_file.readLine header:
    num_of_lines_processed.inc
    fields_in_header = header.replace("\"", "'").split "\t"
    num_of_fields_in_header_base1 = fields_in_header.len
    num_of_fields_in_header_base0 = num_of_fields_in_header_base1 - 1
    num_of_tabs_in_header = num_of_fields_in_header_base0
  else:
    alert_and_exit()

  echo "["

  while input_file.readLine this_record:
    num_of_lines_processed.inc
    num_of_tabs_in_this_record = this_record.count "\t"

    while num_of_tabs_in_this_record != num_of_tabs_in_header:
      num_of_errors_found.inc
      if num_of_tabs_in_this_record > num_of_tabs_in_header:
        alert_and_exit()
      if input_file.readLine completion_record:
        num_of_lines_processed.inc
        this_record.add(" " & completion_record)
        num_of_tabs_in_this_record = this_record.count "\t"
        num_of_errors_corrected.inc
      else:
        alert_and_exit()

    if is_first_record:
      is_first_record = false
    else:
      stdout.writeLine ","

    stdout.write "{"

    num_of_records_processed.inc
    fields_in_this_record = this_record.replace("\"", "'").split "\t"
    for each_field in 0..num_of_fields_in_header_base0:
      stdout.write "\"" & fields_in_header[each_field] & """":"""" & fields_in_this_record[each_field] & "\""
      if each_field < num_of_fields_in_header_base0:
        stdout.write ","

    stdout.write "}"

  echo "\n]"
  if be_verbose:
    show_statistics()

main()
