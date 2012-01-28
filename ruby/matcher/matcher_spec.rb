# This is a public domain

require 'rspec'
require_relative './matcher'

describe Matcher do
  describe ".new" do
    it 'accepts target object and default key for matching' do
      expect { Matcher.new(hi: :hey) }.to_not raise_error
      expect { Matcher.new({hi: :hey}, :hi) }.to_not raise_error
    end
  end

  describe "#match?" do
    before { @matcher = Matcher.new(foo: "bar", bar: "foo") }

    it 'accepts multiple arguments' do
      expect { @matcher.match?("baa","bar") }.to_not raise_error
      expect { @matcher.match?("baa") }.to_not raise_error
    end

    it 'calls #match' do
      @matcher.should_receive(:match).with(["bar"]).and_return([true])
      @matcher.match?("bar").should be_true
      @matcher.should_receive(:match).with(["bar","baz"]).and_return([true])
      @matcher.match?("bar","baz").should be_true
    end

    it 'returns boolean' do
      @matcher.match?(/ba/).should == true
      @matcher.match?(/bo/).should == false
      @matcher.match?("bar").should == true
      @matcher.match?("baa").should == false
    end
  end

  describe '#match' do
    before { @matcher = Matcher.new(foo: "bar", bar: "foo") }

    it 'accepts multiple arguments' do
      expect { @matcher.match("baa","bar") }.to_not raise_error
      expect { @matcher.match("baa") }.to_not raise_error
    end

    it 'accepts Regexp to check match with default key' do
      @matcher.match(/ba/).should be_a_kind_of(Array)
      @matcher.match(/bo/).should be_false
    end

    it 'accepts Regexp and return matchdatas' do
      @matcher.match(/ba/).should be_a_kind_of(Array)
      @matcher.match(/ba/).first.should be_a_kind_of(MatchData)
    end

    it 'accepts other to check equal with the default key' do
      @matcher.match("bar").should be_a_kind_of(Array)
      @matcher.match("bar").first.should == "bar"
      @matcher.match("baa").should be_false
    end

    it 'accepts other and return array' do
      @matcher.match("bar").should be_a_kind_of(Array)
      @matcher.match("bar").should_not be_empty
      @matcher.match("bar").first.should == "bar"
    end

    describe 'with multiple arguments' do
      it 'checks is any conditions in argumens is true' do
        @matcher.match("baa", "bar").should be_a_kind_of(Array)
        @matcher.match("baa", "bar").first.should == "bar"
        @matcher.match("baa", /b/).should be_a_kind_of(Array)
        @matcher.match("baa", /b/).first.should be_a_kind_of(MatchData)
        @matcher.match(/fo/, /ba/).should be_a_kind_of(Array)
        @matcher.match("baa", "bar").first.should == "bar"
        @matcher.match(/far/, /baz/).should be_false
      end
    end

    describe 'with mixed type of arguments' do
      it 'returns array includes MatchData only' do
        @matcher.match("baa", /b/).should be_a_kind_of(Array)
        @matcher.match("baa", /b/).size.should == 1
        @matcher.match("baa", /b/).first.should be_a_kind_of(MatchData)
      end
    end

    it 'checks is any conditions in array is true' do
      @matcher.match(["baa", "bar"]).should be_a_kind_of(Array)
      @matcher.match(["baa", "bar"]).first.should == "bar"
      @matcher.match(["baa", /b/]).should be_a_kind_of(Array)
      @matcher.match(["baa", /b/]).first.should be_a_kind_of(MatchData)
      @matcher.match([/fo/, /ba/]).should be_a_kind_of(Array)
      @matcher.match([/fo/, /ba/]).first.should be_a_kind_of(MatchData)
      @matcher.match(["baa", "baz"]).should be_false
    end

    describe 'with Hash' do
      it "checks is any key&value true" do
        @matcher.match(foo: "bar", bar: "bar").should be_a_kind_of(Array)
        @matcher.match(foo: "bar", bar: "bar").first.should == {foo: "bar"}
        @matcher.match(foo: /b/, bar: "bar").should be_a_kind_of(Array)
        @matcher.match(foo: /b/, bar: "bar").first.keys[0].should == :foo
        @matcher.match(foo: /b/, bar: "bar").first[:foo].should be_a_kind_of(MatchData)
        @matcher.match(foo: /b/, bar: /ba/).should be_a_kind_of(Array)
        @matcher.match(foo: /b/, bar: /ba/).first.keys[0].should == :foo
        @matcher.match(foo: /b/, bar: /ba/).first[:foo].should be_a_kind_of(MatchData)
        @matcher.match(foo: /f/, bar: /ba/).should be_false
        @matcher.match(foo: "b", bar: /ba/).should be_false
      end

      it "checks does specified value (Regexp) matchs to obj[key]" do
        @matcher.match(foo: /b/).should be_a_kind_of(Array)
        @matcher.match(foo: /b/).first.should be_a_kind_of(Hash)
        @matcher.match(foo: /b/).first[:foo].should be_a_kind_of(MatchData)
        @matcher.match(foo: /f/).should be_false
      end

      it "checks does obj[key] equals to specified value (if value is not Regexp)" do
        @matcher.match(bar: "foo").should be_a_kind_of(Array)
        @matcher.match(bar: "foo").first.should be_a_kind_of(Hash)
        @matcher.match(bar: "foo").first[:bar].should  == "foo"
        @matcher.match(bar: "bar").should be_false
      end

      it 'checks is any conditions in specified value (Array) true' do
        @matcher.match(foo: ["foo", "bar"]).should be_a_kind_of(Array)
        @matcher.match(foo: ["foo", "bar"]).first.should be_a_kind_of(Hash)
        @matcher.match(foo: ["foo", "bar"]).first[:foo].should == "bar"
        @matcher.match(foo: ["foo", /baz/]).should be_false
        @matcher.match(foo: ["bar", /b/]).should be_a_kind_of(Array)
        @matcher.match(foo: ["bar", /b/]).first.should be_a_kind_of(Hash)
        @matcher.match(foo: ["bar", /b/]).first[:foo].should == "bar"
        @matcher.match(foo: ["bar", /b/]).size.should == 1
        @matcher.match(bar: ["bar", "baz"]).should be_false
      end

      it 'checks is all conditions in key :all is true' do
        @matcher.match(all: [{foo: "bar"}, {bar: "foo"}]).should be_a_kind_of(Array)
        @matcher.match(all: {foo: "bar", bar: "foo"}).should be_a_kind_of(Array)
        @matcher.match(all: [{foo: "foo"}, {bar: "foo"}]).should be_false
        @matcher.match(all: {foo: "foo", bar: "foo"}).should be_false
        @matcher.match(all: {foo: "bar", any: {foo: "foo", bar: "foo"}}).should be_a_kind_of(Array)
      end

      it 'checks is any conditions in key :any is true' do
        @matcher.match(any: [{foo: "bar"}, {bar: "foo"}]).should be_a_kind_of(Array)
        @matcher.match(any: {foo: "bar", bar: "foo"}).should be_a_kind_of(Array)
        @matcher.match(any: [{foo: "foo"}, {bar: "foo"}]).should be_a_kind_of(Array)
        @matcher.match(any: {foo: "foo", bar: "foo"}).should be_false
        @matcher.match(any: {foo: "bar", any: {foo: "foo", bar: "foo"}}).should be_a_kind_of(Array)
      end

      describe 'returns a Hash:' do
        it 'has only one Hash in the last of array' do
          @matcher.match(all: [{foo: "bar"}, {bar: "foo"}]).should be_a_kind_of(Array)
          @matcher.match(all: [{foo: "bar"}, {bar: "foo"}]).size.should == 1
          @matcher.match(all: [{foo: "bar"}, {bar: "foo"}]).last.should be_a_kind_of(Hash)
          @matcher.match(all: [{foo: "bar"}, {bar: "foo"}]).last[:foo].should == "bar"
          @matcher.match(all: [{foo: "bar"}, {bar: "foo"}]).last[:bar].should == "foo"
          @matcher.match(all: ["bar", {foo: "bar"}, {bar: "foo"}]).last.should be_a_kind_of(Hash)
        end

        it 'has Array for a value when a key has multiple matches' do
          @matcher.match(all: {foo: [/b/,/a/,/r/]}).last[:foo].should be_a_kind_of(Array)
          @matcher.match(all: {foo: [/b/,/a/,/r/]}).last[:foo].size.should == 3
        end
      end

    end
  end
end
