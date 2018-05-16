require "./spec_helper"

describe Gs do
  it "works" do
    (Gs::KEY == "1deUDEVwaNPH1fgy3RlmV98TwgVtHfxQc7gA9YeVs_mc").should be_true
    
    # should have at least 812 draws so far
    r = Gs.execute %{ SELECT COUNT(A) }
    unless r.nil?
      r[0]["count draw"].as(Float64).to_i.should be >= 812
    else
      r.should_not be_nil
    end

    # at least 20 x7
    r = Gs.execute %{ SELECT COUNT(A) WHERE D > 0 }
    unless r.nil?
      r[0]["count draw"].as(Float64).to_i.should be >= 20
    else
      r.should_not be_nil
    end

  end

  it "returns correct joker winning column" do # leading zeros
    qry_fmt = "SELECT A, B, BE WHERE B = date '%s'"

    # 1 zero in front 
    r = Gs.execute qry_fmt % Time.new(2018, 3, 21).to_s(Gs::YMD_FMT)
    unless r.nil?
      (r[0]["draw"].as(Int64).should eq 23_i64) && 
        (r[0]["jwc"].as(String).should eq "058641")
    end

    # 2 zeros in front 
    r = Gs.execute qry_fmt % Time.new(2011, 10, 1).to_s(Gs::YMD_FMT)
    unless r.nil?
      (r[0]["draw"].as(Int64).should eq 79_i64) && 
        (r[0]["jwc"].as(String).should eq "002726")
    end

    # joker winning column == "477777"
    r = Gs.execute qry_fmt % Time.new(2017, 12, 6).to_s(Gs::YMD_FMT)
    unless r.nil?
      (r[0]["draw"].as(Int64).should eq 97_i64) && 
        (r[0]["jwc"].as(String).should eq "477777")
    end
  end
end
