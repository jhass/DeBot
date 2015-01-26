require "fileutils"


def run prog
  r, w = IO.pipe
  system("./sandbox_crystal", "eval", prog, err: w)
  w.close
  stderr = r.read
  puts "#{stderr}"
  [stderr, $?.exitstatus]
end

def needed? prog
  stderr, exitstatus = run prog
  exitstatus != 0 || stderr.include?("Bad system call")
end

syscalls = File.readlines(ARGV[0] || "all_syscalls64").map(&:chomp).sort

needed_calls = syscalls

# syscalls -= %w(connect dup2 execve2 )

syscalls.each do |call|
  tmp_calls = needed_calls-[call]
  File.write("sandbox_whitelist", tmp_calls.join("\n"))
  puts "without #{call}:"
  needed = false
  stderr, exitstatus = run "putss \"hi\""

  if stderr.start_with? "playpen"
    exitstatus = stderr[/with signal (\d+)/, 1].to_i
    needed = true if exitstatus == 31 || stderr.include?("timeout triggered!")
  elsif stderr.include?("Bad system call")
    needed  = true
  end

  needed ||= needed? "puts \"hi\""
  needed ||= needed? "`ls -al`"

  unless needed
    needed_calls = tmp_calls
    puts "Dropped #{call}"
  end

  puts
end
