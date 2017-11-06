require "./lwin/*"

require "http/client"
require "json"
require "xml"

module Lwin
  # TODO  
  #   - update google sheet flat database
  #   - more tools (reporting, stats, etc.)
  #   - newer ionic app

  class WinParser
    @@url = "http://test.lotarija.mk/Results/WebService.asmx/GetDetailedReport"
    @@lwin_cat = [:x7, :x6p, :x6, :x5, :x4]
    @@jwin_cat = [:x6, :x5, :x4, :x3, :x2, :x1]
    
    getter year : Int32
    getter draw : Int32
    getter status : Int32 | Nil
    getter html : String | Nil
    getter lcolumn = [] of Int32
    getter jcolumn : String | Nil
    getter date : Time | Nil
    getter lsales : Int32 | Nil
    getter jsales : Int32 | Nil
    getter lfunds : Float64
    getter jfunds : Float64
    
    getter lwinners  # : Hash(Symbol, Int32)
    getter lwamounts  # : Hash(Symbol, Float64)
    getter lwfunds  # : Hash(Symbol, Float64)
    getter lwjpots  # : Hash(Symbol, Float64)

    getter jwinners  # : Hash(Symbol, Int32)
    getter jwamounts  # : Hash(Symbol, Int32)
    getter jwfunds  # : Hash(Symbol, Float64)
    getter jwjpots  # : Hash(Symbol, Float64)

    def initialize(@year, @draw)
      headers = HTTP::Headers { "Content-Type" => "application/json",
        "Accept" => "application/json" }
      body = %{{"godStr": #{ @year },"koloStr": #{ @draw }}} 

      @html = ""
      HTTP::Client.post url: @@url, headers: headers, body: body do |response|
        @status = response.status_code
        @html = JSON.parse(response.body_io.gets.to_s)["d"].to_s
      end
      doc = XML.parse_html @html.to_s

      # lotto winning column
      node = doc.xpath_node "//p[preceding::br[@class='cleared']]"
      unless node.nil?
        s = node.content.match(/([\d,]+)/).try &.[1]
        s.split(/\s*,\s*/).each {|e| @lcolumn << e.to_i} unless s.nil?
      end

      # joker winning column
      node = doc.xpath_node("//div[@id='joker']")
      @jcolumn = node.content unless node.nil?

      # sales, draw date, funds
      nodes = doc.xpath_nodes "//table[@class='uplata']"
      node = nodes[0].xpath_nodes(".//td")[0]
      @date   = WinParser.mk_to_date(node.content) # calling class method
      @lsales = WinParser.mk_to_i nodes[0].xpath_nodes(".//td")[1].content
      @lfunds = WinParser.mk_to_f nodes[0].xpath_nodes(".//td")[2].content
      @jsales = WinParser.mk_to_i nodes[1].xpath_nodes(".//td")[0].content
      @jfunds = WinParser.mk_to_f nodes[1].xpath_nodes(".//td")[1].content

      # lotto winners & amounts
      @lwinners = Hash(Symbol, Int32).new
      @lwamounts = Hash(Symbol, Float64).new
      doc.xpath_nodes("//table[@class='nl734']")[1]
         .xpath_nodes("./tbody/tr")
         .each_with_index do |row, i|
        w, m = row.xpath_nodes("./td")
        @lwinners[@@lwin_cat[i]] = w.content.to_i
        @lwamounts[@@lwin_cat[i]] = WinParser.mk_to_f m.content
      end

      # lotto winning funds & jackpots
      @lwfunds = Hash(Symbol, Float64).new
      @lwjpots = Hash(Symbol, Float64).new
      doc.xpath_nodes("//table[@class='nl734']")[0]
         .xpath_nodes("./tbody/tr")
         .each_with_index do |row, i|
        f, jp = row.xpath_nodes("./td")
        @lwfunds[@@lwin_cat[i]] = WinParser.mk_to_f f.content
        @lwjpots[@@lwin_cat[i]] = WinParser.mk_to_f jp.content
      end

      # joker winners & amounts
      @jwinners = Hash(Symbol, Int32).new
      @jwamounts = Hash(Symbol, Float64).new
      doc.xpath_nodes("//table[@class='j734']")[1]
         .xpath_nodes("./tbody/tr")
         .each_with_index do |row, i|
        x, w, m = row.xpath_nodes("./td")
        @jwinners[@@jwin_cat[i]] = w.content.to_i
        @jwamounts[@@jwin_cat[i]] = WinParser.mk_to_f m.content
      end

      # lotto winning funds & jackpots
      @jwfunds = Hash(Symbol, Float64).new
      @jwjpots = Hash(Symbol, Float64).new
      doc.xpath_nodes("//table[@class='j734']")[0]
         .xpath_nodes("./tbody/tr")
         .each_with_index do |row, i|
        f, jp = row.xpath_nodes("./td")
        @jwfunds[@@jwin_cat[i]] = WinParser.mk_to_f f.content
        @jwjpots[@@jwin_cat[i]] = WinParser.mk_to_f jp.content
      end
    end

    def self.mk_to_i(s)
     s = s.match(/\s*([.\d]+)/).try &.[1]
     unless s.nil?
      s.gsub(".", "").to_i
      else
        0
     end
    end

    def self.mk_to_f(s)
     s = s.match(/\s*([.,\d]+)/).try &.[1]
     unless s.nil?
      s.gsub(".", "").gsub(",", ".").to_f
      else
        0_f64
     end
    end

    def self.mk_to_date(s)
      d, m, y = s.split(".")
      Time.new(y.to_i, m.to_i, d.to_i)
    end
  end
end

win = Lwin::WinParser.new 2017, 87

puts "status: #{ win.status }"
# puts win.html
