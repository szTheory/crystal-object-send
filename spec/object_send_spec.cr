require "spec"
require "../src/object_send"

describe "send" do
  describe String do
    it "chars" do
      "abc".send("chars").should eq ['a', 'b', 'c']
    end

    it "size" do
      var = "size"
      "abc".send(var).should eq 3
    end

    it "size()" do
      "abc".send("size()").should eq 3
    end

    it "starts_with? Char" do
      "abc".send("starts_with? 'a'").should be_true
    end

    it "lchop(Char)" do
      "abc".send("lchop('a')").should eq "bc"
    end

    it "insert Index, Char" do
      "abc".send("insert 1, 'z'").should eq "azbc"
    end
  end

  describe Int32 do
    it "- Float" do
      2.send("+ 3.0").should eq 5
    end
  end

  describe Hash do
    it "keys" do
      {"a" => 'b'}.send("keys").should eq ["a"]
    end
  end

  describe Array do
    it "gets index with []?" do
      [0, 1, 2].send("[1]?").should eq 1
    end

    it "gets range with []" do
      [0, 1, 2].send("[..]").should eq [0, 1, 2]
    end

    it "first" do
      [0, 1, 2].send("first 2").should eq [0, 1]
    end

    it "deletes at Int index, Int count" do
      [0, 1, 2].send("delete_at(1, 1)").should eq [1]
    end

    it "deletes within a Range" do
      ary = [0, 1, 2]
      ary.send("delete_at(1..2)").should eq [1, 2]
      ary.should eq [0]
    end
  end
end
