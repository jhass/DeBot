require "../core_ext/src/core_ext/dir.cr"
Dir.chdir File.dirname(PROGRAM_NAME)
args = [
  "sandbox",
  "-p",
  "-d", "/dev/null:rw",
  "-u", "crystal",
#  "-m", "128",
 "-t", "5",
 "-S", "sandbox_whitelist",
  # "-l", "sandbox_whitelist",
  "--",
  "/usr/bin/crystal"
]
args += ARGV
status = Process.run "/usr/bin/playpen", args
exit status.exit.not_nil!
