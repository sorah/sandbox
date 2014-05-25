class Git
  def initialize(repo)
    @repo = repo
  end

  def commits(range = 'master')
    raw = get('git', 'log', '--pretty=%H %ct', range)

    raw.lines.reverse_each.map do |_| 
      hash, ts = _.split(/ /, 2)
      {hash: hash, committed_at: Time.at(ts.to_i), wday: Time.at(ts.to_i).wday}
    end
  end

  def commits_by_week(range = 'master')
    commits(range).slice_before([]) do |commit, state|
      prev = state[0]
      res = prev.nil? || commit[:committed_at].wday < prev[:committed_at].wday

      state[0] = commit
      res
    end.to_a
  end

  def checkout(*args)
    get('git', 'checkout', *args)
  end

  def show(*args)
    get('git', 'show', *args)
  end

  def clean(*args)
    get('git', 'clean', *args)
  end

  def reset(*args)
    get('git', 'reset', *args)
  end

  def get(*cmd)
    work do
      out = IO.popen(cmd, 'r', &:read)
      raise "#{cmd.inspect} Failed" unless $?.success?
      out
    end
  end

  def work(&block)
    Dir.chdir(@repo, &block)
  end
end

class Trial
  class Failed < Exception; end

  def initialize(git, commit, prepare, test, teardown, workdir)
    @git, @commit, @prepare, @test, @teardown, @workdir = \
      git, commit, prepare, test, teardown, workdir
    @status = nil
  end

  attr_reader :status

  def success?
    status == :success
  end

  def run
    $stdout.puts "=> Run #{@commit[:hash]}"
    setup_log
    checkout
    prepare
    test
    @status
  rescue Failed
    @log.puts("=> Teardown") if @log && !@log.closed?
    puts " ! FAILED"
    @status = :unknown_failure unless @status
    return @status
  ensure
    teardown
    $stdout.puts " = #{@commit[:hash]}: #{@status.to_s}"
    @log.puts("RESULT: #{@status.to_s}") if @log && !@log.closed?
    clean_log
  end

  def checkout
    $stdout.puts " * Checkout"
    @git.reset('--hard')
    @git.clean('-fdx')
    @git.checkout(@commit[:hash])

    @log.puts "=> git show"
    @log.puts @git.show(@commit[:hash])
  end

  def prepare
    $stdout.puts " * Prepare"
    @log.puts "=> Prepare"
    sys @prepare
  rescue Failed
    @status = :prefail
    raise
  end

  def test
    $stdout.puts " * Test"
    @log.puts "=> Test"
    sys @test
    @status = :success
  rescue Failed
    @status = :failure
    raise
  end

  def teardown
    $stdout.puts " * Teardown"
    @log.puts "=> Teardown"
    sys @teardown
  rescue Failed
    @status = :teardown_fail
    raise
  end

  def logfile
    File.join(@workdir, "#{@commit[:hash]}.log")
  end

  def setup_log
    @log = open(logfile, 'w')
  end

  def clean_log
    if @log
      path = @log.path
      @log.close unless @log.closed?

      if success?
        File.unlink(path) if File.exist?(path)
      end
    end
    @log = nil
  end

  def sys(cmd)
    $stdout.puts " $ #{cmd}"
    @log.puts " $ #{cmd}"
    result = @git.work { system(cmd, err: @log, out: @log) }
    raise Failed unless result
  end
end

class Runner
  def initialize(argv)
    @repo, @workdir, @range, @prepare, @test, @teardown, @reporter = argv
    @git = Git.new(@repo)
  end

  def summary_path
    File.join(@workdir, 'summary.txt')
  end

  def summary
    {}.tap do |summary|
      if File.exist?(summary_path)
        File.read(summary_path).each_line do |line|
          unixtime, timestamp, commit, status = line.split(/\t/, 4)
          summary[commit] = status.chomp
        end
      end
    end
  end

  def run
    weeks = @git.commits_by_week(@range)

    update_status = proc do |queue, phase|
      @total = weeks.flatten.size
      @phase = phase if phase
      @queue_size = queue ? queue.size : 0
      @queue_done = 0
    end

    failed_weeks = []
    succeed_weeks = []

    update_status[weeks, 'all weeks']
    weeks.each do |week|
      @queue_done += 1
      puts "===== WEEK RUN #{week.first[:committed_at]} ... #{week.last[:committed_at]}"
      trial = try(week.last)
      if trial == :failure
        puts "FAIL"
        failed_weeks << week
      else
        puts "PASS"
        succeed_weeks << week
      end
    end

    failed_days = []
    succeed_days = []

    run_week = proc do |week|
      @queue_done += 1
      days = commits_slice_into_day(week)

      stat = summary[week.last[:hash]]
      statstr = stat == 'failure' ? "FAIL " : ""

      days.each do |commits|
        puts "===== #{statstr}DAY RUN #{commits.first[:committed_at]} ... #{commits.last[:committed_at]}"
        trial = try(commits.last)
        if trial == :failure
          puts "FAIL"
          failed_days << commits
        else
          puts "PASS"
          succeed_days << commits
        end
      end
    end

    puts "===== running failed weeks"
    update_status[failed_weeks, 'days in failed weeks']
    failed_weeks.each(&run_week)

    run_commit = proc do |commit|
      @queue_done += 1
      stat = summary[commit[:hash]]
      statstr = stat == 'failure' ? "FAIL " : ""

      puts "===== #{statstr}COMMIT RUN #{commit[:committed_at]}"
      trial = try(commit)
    end

    puts "===== running failed days"
    update_status[failed_days.flatten, 'commits in failed days']
    failed_days.flatten.each(&run_commit)


    failed_days = []
    puts "===== running succeeded weeks"
    update_status[succeed_weeks, 'days in succeeded weeks']
    succeed_weeks.each(&run_week)

    puts "===== running failed days"
    update_status[failed_days.flatten, 'commits in failed days']
    failed_days.flatten.each(&run_commit)

    puts "===== running succeeded days"
    update_status[succeed_days.flatten, '(final) commits in succeeded days']
    succeed_days.flatten.each(&run_commit)
  end

  def try(commit)
    s = summary
    return s[commit[:hash]].to_sym if s[commit[:hash]]

    trial = Trial.new(@git, commit, @prepare, @test, @teardown, @workdir)
    trial.run

    timestamp = commit[:committed_at].strftime('%Y-%m-%d_%H.%M.%S')
    open(summary_path, 'a') { |io| io.puts "#{commit[:committed_at].to_i}\t#{timestamp}\t#{commit[:hash]}\t#{trial.status.to_s}" }

    if @reporter
      env = {
        "AUTOTRY_COMMIT" => commit[:hash],
        "AUTOTRY_TIMESTAMP_HUMAN" => timestamp.to_s,
        "AUTOTRY_TIMESTAMP" => commit[:committed_at].to_i.to_s,
        "AUTOTRY_RESULT" => trial.status.to_s,
        "AUTOTRY_LOG" => trial.logfile,
        "AUTOTRY_PROG_PHASE" => @phase || "unknown phase",
        "AUTOTRY_PROG_TOTAL_COMMITS" => @total.to_s,
        "AUTOTRY_PROG_DONE_COMMITS" => @done.to_s,
        "AUTOTRY_PROG_QUEUE_TOTAL" => @queue_size.to_s,
        "AUTOTRY_PROG_QUEUE_DONE" => @queue_done.to_s,
      }
      IO.popen([env, 'bash', '-c', @reporter], 'r') do |io|
        puts io.read
      end
    end

    @done = summary.size
    trial.status
  end

  private

  def commits_slice_into_day(commits)
    commits.slice_before([]) do |commit, state|
      prev = state[0]
      res = prev.nil? || commit[:committed_at].day != prev[:committed_at].day

      state[0] = commit
      res
    end.to_a
  end
end

#abort "usage: #{File.basename $0} repo workdir range prepare test cleanup reporter"

#git = Git.new(ARGV[0])
#commits_by_week = git.commits_by_week(ARGV[1])

Runner.new(ARGV).run
