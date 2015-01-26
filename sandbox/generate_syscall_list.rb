require "fileutils"


def run prog
  r, w = IO.pipe
  system("./sandbox_crystal", "eval", prog, err: w)
  w.close
  stderr = r.read
  puts "#{stderr}"
  [stderr, $?.exitstatus]
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
  elsif stderr.include?("10 Bad system call")
    exitstatus = -1
    needed  = true
  end

  stderr, exitstatus = run "puts \"hi\""
  needed = true unless exitstatus == 0
  stderr, exitstatus = run "`ls -al`"
  needed = true unless exitstatus == 0

  unless needed
    needed_calls = tmp_calls
    puts "Dropped #{call}"
  end

  puts
end
