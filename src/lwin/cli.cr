require "option_parser"
require "ecr"
require "colorize"

module LwinCLI
  opts = {
    "last" => 10,
    "drum" => "none"
  }

  p = OptionParser.parse! do |parser|
    parser.banner = "Usage: lwin [x7|x6p|joker|last|freq|stats|update]..."
    
    # short list last draws with sales and winning columns
    parser.on("-l LAST", "--last=LAST", "LAST: number of draws (10)") do |l|
      opts["last"] = l.to_i
    end

    # drum: stresa, venus, none
    parser.on("-d DRUM", "--drun=DRUM", "DRUM: stresa|venus|none") do |d|
      unless d =~ /^stresa|venus|none$/i
        puts "Invalid DRUM: '#{ d }'"
        puts parser
        exit 1
      end
      opts["drum"] = d.downcase
    end

    parser.on("-h", "--help", "Show this help") do
      puts parser
      exit 1
    end
  end

  puts p if ARGV.size == 0
    
# TODO:
# - annual sales
# - append draw, resolve url problem

  ARGV.each do |cmd|
    case cmd
    when "x7"
      winners_x7
    when "x6p"
      winners_x6p
    when "joker"
      winners_joker
    when "last"
      last_draws opts
    when "freq"
      freq opts
    when "stats"
      stats
    when "update"
      update
    else
      puts "invalid command #{ cmd }"
      exit 1
    end
  end
 
  # x7
  class WinX7Temp
    @a : Array( Hash(String, Time|Float64|Int64|String))
    def initialize(@a)
    end

    ECR.def_to_s %{#{ `pwd`.chomp }/templates/winx7.ecr}
  end

  def self.winners_x7
    qry = <<-EOQ
      SELECT
        A, B, D,
        I, N, S
      WHERE
        D > 0
      ORDER BY B
    EOQ

    r = Gs.execute qry
    unless r.nil?
      Colorize.on_tty_only!
      tmpl = WinX7Temp.new r
      puts tmpl
    end
  end

  # x6p
  class WinX6pTemp
    COLORS = [ :red, :green, :yellow, :blue, :magenta, :cyan,
      :light_gray, :light_red, :light_green, :light_yellow, 
      :light_blue, :light_magenta, :light_cyan, :white
    ]
    @a : Array( Hash(String, Time|Float64|Int64|String))
    def initialize(@a)
    end

    ECR.def_to_s %{#{ `pwd`.chomp }/templates/winx6p.ecr}
  end

  def self.winners_x6p
    qry = <<-EOQ
      SELECT
        A, B, E,
        J, O, T
      WHERE
        E > 0
      ORDER BY B
    EOQ

    r = Gs.execute qry
    unless r.nil?
      Colorize.on_tty_only!
      tmpl = WinX6pTemp.new r
      puts tmpl
    end
  end

  # joker
  class WinJokerTemp
    COLORS = [ :red, :green, :yellow, :blue, :magenta, :cyan,
      :light_gray, :light_red, :light_green, :light_yellow, 
      :light_blue, :light_magenta, :light_cyan, :white
    ]
    @a : Array( Hash(String, Time|Float64|Int64|String))
    def initialize(@a)
    end

    ECR.def_to_s %{#{ `pwd`.chomp }/templates/win_joker.ecr}
  end

  def self.winners_joker
    qry = <<-EOQ
      SELECT
        A, B, AG,
        AM, AS, AY
      WHERE
        AG > 0
      ORDER BY B
    EOQ

    r = Gs.execute qry
    unless r.nil?
      Colorize.on_tty_only!
      tmpl = WinJokerTemp.new r
      puts tmpl
    end
  end

  # last draws
  class LastDrawsTemp
    COLORS = [ :red, :green, :yellow, :blue, :magenta,
      :cyan, :light_magenta, :light_gray ]
    @a : Array( Hash(String, Time|Float64|Int64|String))
    @count : Int32
    def initialize(@a, @count)
    end

    ECR.def_to_s %{#{ `pwd`.chomp }/templates/last_draws.ecr}
  end
  def self.last_draws(opts)
    qry = <<-QRY
      SELECT
        A, B,
        C, X, Y, Z, AA, AB, AC, AD, AE,
        AF, BE
      ORDER BY B DESC
      LIMIT %d
    QRY
    r = Gs.execute qry % opts["last"]
    unless r.nil?
      Colorize.on_tty_only!
      r.reverse!
      tmpl = LastDrawsTemp.new r, opts["last"].to_i
      puts tmpl
    end
  end

  # lotto freq
  class FreqTemp
    @f : Array(Array(Int64))
    @drum : String

    def initialize(@f, @drum)
    end

    ECR.def_to_s %{#{ `pwd`.chomp }/templates/freq.ecr}
  end
  def self.freq(opts)
    qry = <<-QRY
      SELECT X, Y, Z, AA, AB, AC, AD, AE
    QRY

    qry = case opts["drum"]
          when "stresa"
            "#{ qry } WHERE B >= date '%s'" % Gs::STRESA_DATE.to_s(Gs::YMD_FMT)
          when "venus"
            "#{ qry } WHERE B <= date '%s'" % Gs::VENUS_DATE.to_s(Gs::YMD_FMT)
          else
            qry
          end
    r = Gs.execute qry
    freq = [] of Array(Int64)

    unless r.nil?
      Colorize.on_tty_only!
      (34+1).times { freq << [0_i64, 0_i64, 0_i64, 0_i64, 0_i64, 0_i64, 0_i64, 0_i64] }
      r.each do |r|
        freq[r["lwc1"].as(Int64)][0] += 1
        freq[r["lwc2"].as(Int64)][1] += 1
        freq[r["lwc3"].as(Int64)][2] += 1
        freq[r["lwc4"].as(Int64)][3] += 1
        freq[r["lwc5"].as(Int64)][4] += 1
        freq[r["lwc6"].as(Int64)][5] += 1
        freq[r["lwc7"].as(Int64)][6] += 1
        freq[r["lwcp"].as(Int64)][7] += 1
      end
      tmpl = FreqTemp.new freq, opts["drum"].as(String)

      puts tmpl
    end
  end

  # stats
  class StatsTemp
    @a   : Array(Hash(String, Time|Float64|Int64|String))
    @h6p : Hash(Int32, Int32)
    @h6  : Hash(Int32, Int32)

    def initialize(@a, @h6p, @h6)
    end

    ECR.def_to_s %{#{ `pwd`.chomp }/templates/stats.ecr}
  end
  def self.stats
    qry = <<-QRY
      SELECT
        YEAR(B),
        COUNT(B),
        MIN(C),AVG(C), MAX(C),
        SUM(D), SUM(E),
        AVG(F), AVG(G), AVG(H)
      GROUP BY YEAR(B)
      ORDER BY YEAR(B)
      LABEL YEAR(B) "year", COUNT(B) "draws",
            MIN(C) "min_lsales", AVG(C) "avg_lsales", MAX(C) "max_lsales",
            SUM(D) "x7", SUM(E) "x6p",
            AVG(F) "x6", AVG(G) "x5", AVG(H) "x4"
    QRY

    q6p = <<-QRY
      SELECT
        YEAR(B),
        COUNT(E)
      WHERE
        E > 0
      GROUP BY YEAR(B)
      ORDER BY YEAR(B)
      LABEL YEAR(B) "year", COUNT(E) "x6p_draws"
    QRY

    r6p = Gs.execute q6p
    h6p = { } of Int32 => Int32
    unless r6p.nil?
      r6p.each do |r|
        h6p[r["year"].as(Float64).to_i] = r["x6p_draws"].as(Float64).to_i
      end
    end

    q6 = <<-QRY
      SELECT
        YEAR(B),
        COUNT(F)
      WHERE
        F > 0
      GROUP BY YEAR(B)
      ORDER BY YEAR(B)
      LABEL YEAR(B) "year", COUNT(F) "x6_draws"
    QRY

    r6 = Gs.execute q6
    h6 = { } of Int32 => Int32
    unless r6.nil?
      r6.each do |r|
        h6[r["year"].as(Float64).to_i] = r["x6_draws"].as(Float64).to_i
      end
    end

    r = Gs.execute qry
    unless r.nil?
      Colorize.on_tty_only!
      tmpl = StatsTemp.new r, h6p, h6
      puts tmpl
    end
  end

  # update
  def self.next_draw_for(d)
    wday = d["date"].as(Time).day_of_week
    if    wday.wednesday?
      dd = d["date"].as(Time) + 3.days
      if d["date"].as(Time).year == dd.year
        { "draw" => d["draw"].as(Int64) + 1, "date" => dd }
      else
        { "draw" => 1_i64, "date" => dd }
      end
    elsif wday.saturday?
      dd = d["date"].as(Time) + 4.days
      if d["date"].as(Time).year == dd.year
        { "draw" => d["draw"].as(Int64) + 1, "date" => dd }
      else
        { "draw" => 1_i64, "date" => dd }
      end
    else
      puts "Invalid date: #{ d }"
      exit 1
    end
  end
  def self.missing_draws_for(d)
    today = Time.now
    a = [] of Hash(String, Int64|Time)
    next_draw = next_draw_for d
    while next_draw["date"].as(Time) + 21.hours < today
      a << next_draw
      next_draw = next_draw_for next_draw
    end
    a
  end
  def self.update
    qlast = <<-QRY
      SELECT A, B ORDER BY B DESC LIMIT 1
    QRY
    
    r = Gs.execute qlast
    exit 1 if r.nil?
      
    last_draw = r[0]
    puts "last draw: #{ last_draw["draw"] } #{ last_draw["date"].as(Time).to_s(Gs::YMD_FMT) }"

    missing_draws = missing_draws_for last_draw

    if missing_draws.size == 0
      puts "DB is up to date, nothing to do."
      exit 0
    end

    missing_draws.each do |d|
      puts "#{ d["draw"] } #{ d["date"].as(Time).to_s(Gs::YMD_FMT) }"
      lw = Lwin::WinParser.new d["date"].as(Time).year, d["draw"].as(Int64).to_i
      status_code = Gs.append(lw.to_h)
      unless [200, 302].includes? status_code
        puts "Error updating (#{ status_code })"
        exit 1
      end
    end
  end
end
