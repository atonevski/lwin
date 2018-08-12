# Google scripts etc.

require "uri"
require "http/client"
require "json"

# 
#  draw no., date
#  A         B
#  lsales, lx7, lx6p, lx6, lx5, lx4, lmx7, lmx6p, lmx6, lmx5, lmx4,
#  C       D    E     F    G    H    I     J     K      L     M
#          lfx7, lfx6p, lfx6, lfx5, lfx4, ljx7, ljx6p, ljx6, ljx5, ljx4,
#          N      O     P     Q     R     S      T     U     V     W
#          lwc1, lwc2, lwc3, lwc4, lwc5, lwc6, lwc7, lwcp
#          X     Y     Z     AA    AB    AC    AD     AE
#  jsales, jx6, jx5, jx4, jx3, jx2, jx1, jmx6, jmx5, jmx4, jmx3, jmx2, jmx1,
#  AF      AG   AH   AI   AJ   AK   AL   AM    AN    AO    AP    AQ    AR
#          jfx6, jfx5, jfx4, jfx3, jfx2, jfx1, jjx6, jjx5, jjx4, jjx3, jjx2, jjx1,
#          AS    AT    AU    AV    AW    AX    AY    AZ    BA    BB    BC    BD
#          jwc
#          BE
module Gs
  KEY     = "1deUDEVwaNPH1fgy3RlmV98TwgVtHfxQc7gA9YeVs_mc"
  URL     = "https://docs.google.com"
  RES_RE  = /^([^(]+?\()(.*)\);$/

  YMD_FMT       = "%Y-%m-%d"
  MK_FMT        = "%d.%m.%Y"
  VENUS_DATE    = Time.new 2011, 9, 15 # date ≤ 15.09.2011
  STRESA_DATE   = Time.new 2011, 9, 17 # date ≥ 17.09.2011

  APPEND_URL = "https://script.google.com/macros/s/" \
               "AKfycbz_vGNNQpXV4VFBt8dAktnbSWKASduNUS9OJkq8PBpuoUAabh1W/exec"
  # APPEND_URL = "https://script.google.com/macros/exec?"\
  #              "service=AKfycbz_vGNNQpXV4VFBt8dAktnbSWKASduNUS9OJkq8PBpuoUAabh1W"

  # APPEND_URL = "https://script.google.com/macros/exec"
  # APPEND_KEY = "AKfycbz_vGNNQpXV4VFBt8dAktnbSWKASduNUS9OJkq8PBpuoUAabh1W"

  def self.exec(q)
    HTTP::Client.new(host: URI.parse(URL).host.to_s, port: 443, tls: true) do |client|
      path = "/spreadsheets/d/%s/gviz/tq?tqx=out:json&tq=%s" % [KEY, URI.escape(q)]
      headers = HTTP::Headers {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
      client.get(path, headers: headers) do |res|
        r = JSON.parse (res.body_io.gets_to_end.match(RES_RE).try &.[2]).to_s
        return r
      end
    end
  end

  def self.execute(q)
    HTTP::Client.new(host: URI.parse(URL).host.to_s, port: 443, tls: true) do |client|
      path = "/spreadsheets/d/%s/gviz/tq?tqx=out:json&tq=%s" % [KEY, URI.escape(q)]
      headers = HTTP::Headers {
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
      client.get(path, headers: headers) do |res|
        r = JSON.parse (res.body_io.gets_to_end.match(RES_RE).try &.[2]).to_s
        return nil unless r["status"] == "ok"
        a = [ ] of Hash(String, Time|Float64|Int64|String)
        cols = r["table"]["cols"]
        rows = r["table"]["rows"]
        rows.as_a.each do |r|
          h = { } of String => Time|Float64|Int64|String
          cols.as_a.each_with_index do |c, i|
            label = c["label"].to_s
            case c["type"]
            when "number"
              if !c["pattern"]?.nil? && c["pattern"].to_s =~ /^(#,?)?##(#|0)$/
                h[label] = r["c"][i]["f"].to_s.gsub(",", "").to_i64
              else
                h[label] = r["c"][i]["v"].as_f
              end
            when "date"
              ymd = (r["c"][i]["v"].to_s.match(/Date\((.*)\)/).try &.[1]).
                      to_s.split(",").map{|x| x.to_i}
              h[label] = Time.new ymd[0], ymd[1]+1, ymd[2]
            else
              h[label] = r["c"][i]["v"].to_s
            end
          end
          a << h
        end
        return a
      end
    end
  end

  def self.append(h)
    uri = URI.parse(APPEND_URL) 
    HTTP::Client.new(host: uri.host.to_s, tls: true) do |client|
      client.compress = true
      headers = HTTP::Headers {
        "Content-Type"    => "application/x-www-form-urlencoded",
        "Accept-Charset"  => "utf-8",
        # "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
      # puts "HOST: #{ uri.host }"
      # puts "PATH: #{ uri.path }"
      client.post(uri.path.to_s, headers: headers, body: h_to_p(h)) do |res|
        return res.status_code
      end
    end
  end

  # hash to uri pararemters
  def self.h_to_p(h)
    h.keys.map {|k| "#{k}=#{h[k]}"}.join("&")
  end

  def self.get_last_draw
    execute "SELECT A, B ORDER BY B DESC LIMIT 1"
  end
  
  def self.f_to_sep(n) : String
    s = sprintf("%.2f", n)

    s.reverse.gsub(/(\d\d\d)(?=\d)/, "\\1,").reverse
  end
  def self.i_to_sep(n) : String
    s = sprintf("%d", n)

    s.reverse.gsub(/(\d\d\d)(?=\d)/, "\\1,").reverse
  end
end
