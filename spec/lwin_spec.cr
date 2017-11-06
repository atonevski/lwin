require "./spec_helper"

describe Lwin do
  # TODO: Write tests

  win = Lwin::WinParser.new 2017, 87
  it "works" do
    win.status.should eq 200
    (win.year.should eq 2017) && (win.draw.should eq 87)
    win.html.should match /87. коло/
  end

  it "parses the winning columns correctly" do
    win.lcolumn.should eq [2, 3, 12, 1, 34, 32, 11, 27]
    win.jcolumn.should eq "655332"
  end
 
  it "converts mk format" do
    Lwin::WinParser.mk_to_i("1864").should eq 1864
    Lwin::WinParser.mk_to_i("1.864").should eq 1864
    Lwin::WinParser.mk_to_f("1.466.975,09").should eq 1466975.09
    Lwin::WinParser.mk_to_date("01.11.2017")
      .to_s("%Y-%m-%d")
      .should eq "2017-11-01"
  end

  it "parses date, sales and funds correctly" do
    date = win.date
    unless date.nil?
      date.to_s("%Y-%m-%d").should eq "2017-11-01"
    end
    lsales = win.lsales
    unless lsales.nil?
      lsales.should eq 1_330_880
    end
    lfunds = win.lfunds
    unless lfunds.nil?
      lfunds.should eq 665_355.98
    end
    jsales = win.jsales
    unless jsales.nil?
      jsales.should eq 192_940
    end
    jfunds = win.jfunds
    unless jfunds.nil?
      jfunds.should eq 96_480.48
    end
  end

  it "parses correctly lotto winners and winning amounts" do
    win.lwinners[:x7].should  eq 1
    win.lwinners[:x6p].should eq 0
    win.lwinners[:x6].should  eq 1
    win.lwinners[:x5].should  eq 85
    win.lwinners[:x4].should  eq 926

    win.lwamounts[:x7].should  eq 6_000_000.0
    win.lwamounts[:x6p].should eq 0.00
    win.lwamounts[:x6].should  eq 99_803.5
    win.lwamounts[:x5].should  eq 1_174.0
    win.lwamounts[:x4].should  eq 251.5
  end

  it "parses correctly lotto winning funds and jackpots" do
    win.lwfunds[:x7].should  eq 199_606.79
    win.lwfunds[:x6p].should eq 33_267.80
    win.lwfunds[:x6].should  eq 99_803.40
    win.lwfunds[:x5].should  eq 99_803.40
    win.lwfunds[:x4].should  eq 232_874.59

    win.lwjpots[:x7].should  eq 3_314_830.82
    win.lwjpots[:x6p].should eq 329_581.52
    win.lwjpots[:x6].should  eq 0.0
    win.lwjpots[:x5].should  eq 0.0
    win.lwjpots[:x4].should  eq 0.0
  end

  it "parses correctly joker winners and winning amounts" do
    win.jwinners[:x6].should eq 0
    win.jwinners[:x5].should eq 0
    win.jwinners[:x4].should eq 1
    win.jwinners[:x3].should eq 18
    win.jwinners[:x2].should eq 179
    win.jwinners[:x1].should eq 1684

    win.jwamounts[:x6].should eq 0.0
    win.jwamounts[:x5].should eq 0.0
    win.jwamounts[:x4].should eq 12_560.0
    win.jwamounts[:x3].should eq 698.0
    win.jwamounts[:x2].should eq 70.0
    win.jwamounts[:x1].should eq 20.0
  end

  it "parses correctly joker winning funds and jackpots" do
    win.jwfunds[:x6].should eq 12_560.1
    win.jwfunds[:x5].should eq 12_560.1
    win.jwfunds[:x4].should eq 12_560.1
    win.jwfunds[:x3].should eq 12_560.1
    win.jwfunds[:x2].should eq 12_560.1
    win.jwfunds[:x1].should eq 33_680.0

    win.jwjpots[:x6].should eq 1_454_414.99
    win.jwjpots[:x5].should eq 50_915.45
    win.jwjpots[:x4].should eq 0.0
    win.jwjpots[:x3].should eq 0.0
    win.jwjpots[:x2].should eq 0.0
    win.jwjpots[:x1].should eq 0.0
  end
end
