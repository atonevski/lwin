require "./lwin/*"

require "http/client"
require "json"
require "xml"

module Lwin
  # TODO  
  #   - make it a class WinParser
  #   - should fill all fields
  #   - contstuctor should have (year, draw)

  
  url = "http://test.lotarija.mk/Results/WebService.asmx/GetDetailedReport"
  uri = URI.parse url
  headers = HTTP::Headers {"Content-Type" => "application/json",
    "Accept" => "application/json"}
  body = %{{"godStr": "2017","koloStr": "87"}}
  html = ""
  HTTP::Client.post url: url, headers: headers, body: body do |response|
    puts "status: #{ response.status_code }"
    s = response.body_io.gets
    html = JSON.parse(s.to_s)["d"].to_s
    # puts html
  end

  puts html
  doc = XML.parse_html html

  # winning column
  match = /<p>Редослед на извлекување:\s*(.+?)\.<\/p>/.match(html).try &.[1]
  win_col = [] of Int32
  unless match.nil?
    match.split(/\s*,\s*/).each do |e|
      win_col << e.to_i
    end
  end
  puts win_col.join(", ")

  # joker winning column
  node = doc.xpath_node("//div[@id='joker']")
  unless node.nil?
    puts node.content
  end
end
