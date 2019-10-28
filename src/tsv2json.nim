############################################################
##
##   Gets TSV records from file or stdin
##   and yields same content formatted as JSON to stdout
##
############################################################

# nim -f c -d:danger --app:console --opt:speed --passc:-flto tsv2json.nim && strip -s tsv2json && upx --best tsv2json

import terminal, strutils, parseopt, os

var
  thisProgramName: string
  input_file: File
  this_record: string
  num_of_tabs_of_this_record: int
  num_of_fields_of_this_record_base1: int
  num_of_errors_found: int
  num_of_errors_corrected: int
  num_of_records_processed: int
  num_of_lines_processed: int
  num_of_fields_of_header_base1: int
  there_was_crisis: bool = false


proc show_version =
  stderr.styledWriteLine styleBright, fgGreen, thisProgramName & ", version 0.1.3"


proc show_help =
  show_version()
  stderr.writeLine ""
  stderr.styledWriteLine styleBright, "Usage:"
  stderr.writeLine "    " & thisProgramName & " infile.tsv  [>outfile.json]"
  stderr.writeLine "    " & thisProgramName & " <infile.tsv [>outfile.json]"
  stderr.writeLine "    " & thisProgramName & " [option]"
  stderr.writeLine ""
  stderr.styledWriteLine styleBright, "Options:"
  stderr.writeLine "    -h, --help              Display this message"
  stderr.writeLine "    -v, --version           Print version info and exit"
  stderr.writeLine ""
  stderr.styledWriteLine styleBright, "Authors:"
  stderr.writeLine "    Héctor M. Monacci (2019)"


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
  num_of_fields_of_this_record_base1 = num_of_tabs_of_this_record + 1
  stderr.styledWriteLine styleBright, fgRed, "Header line has " & $num_of_fields_of_header_base1 & " fields but this record has " & $num_of_fields_of_this_record_base1 & ":"
  stderr.writeLine this_record.replace("\t", "\n")
  stderr.styledWriteLine styleBright, fgRed, "The above error was found at line " & $num_of_lines_processed & " of TSV input."
  there_was_crisis = true
  show_statistics()
  quit QuitFailure


proc cmdline =
  input_file = stdin
 
  for kind, key, value in getOpt():
    case kind
    of cmdArgument:
      if existsFile key:
        input_file = open key
      else:
        stderr.styledWriteLine styleBright, fgRed, "Cannot find file \"" & key & "\"."
        quit QuitFailure
    of cmdLongOption, cmdShortOption:
      case key
      of "h", "help":
        show_help()
        quit QuitSuccess
      of "v", "version":
        show_version()
        quit QuitSuccess
      else:
        stderr.writeLine "Unknown option: \"" & key & "\"."
        quit QuitFailure
    of cmdEnd:
      discard


proc main =
  var
    header: string
    fields_of_header: seq[string]
    num_of_fields_of_header_base0: int
    is_first_record: bool = true
    fields_of_this_record: seq[string]
    num_of_tabs_header: int
    completion_record: string

  thisProgramName = getAppFilename().extractFilename()

  cmdline()

  if input_file.readLine header:
    inc num_of_lines_processed
    fields_of_header = header.replace("\"", "'").split "\t"
    num_of_fields_of_header_base1 = fields_of_header.len
    num_of_fields_of_header_base0 = num_of_fields_of_header_base1 - 1
    num_of_tabs_header = num_of_fields_of_header_base0
  else:
    alert_and_exit()

  echo "["

  while input_file.readLine this_record:
    num_of_lines_processed.inc
    this_record = this_record.replace("\"", "'")
    num_of_tabs_of_this_record = this_record.count "\t"

    while num_of_tabs_of_this_record != num_of_tabs_header:
      num_of_errors_found.inc
      if num_of_tabs_of_this_record > num_of_tabs_header:
        alert_and_exit()
      if input_file.readLine completion_record:
        num_of_lines_processed.inc
        this_record.add(" " & completion_record.replace("\"", "'"))
        num_of_tabs_of_this_record = this_record.count "\t"
        num_of_errors_corrected.inc
      else:
        alert_and_exit()

    if is_first_record:
      is_first_record = false
    else:
      stdout.writeLine ","

    stdout.write "{"

    num_of_records_processed.inc
    fields_of_this_record = this_record.split "\t"
    for num_of_this_field in 0..num_of_fields_of_header_base0:
      stdout.write "\"" & fields_of_header[num_of_this_field] & """":"""" & fields_of_this_record[num_of_this_field] & "\""
      if num_of_this_field < num_of_fields_of_header_base0:
        stdout.write ","

    stdout.write "}"

  echo "\n]"
  show_statistics()

main()
