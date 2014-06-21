require 'spec_helper'
require 'dpl/cli'

describe DPL::CLI do
  describe "#options" do
    example { expect(described_class.new.options[:app])                           .to eq(File.basename(Dir.pwd)) }
    example { expect(described_class.new(:app => 'foo')            .options[:app]).to eq('foo')                  }
    example { expect(described_class.new("--app=foo")              .options[:app]).to eq('foo')                  }
    example { expect(described_class.new("--app")                  .options[:app]).to eq(true)                   }
    example { expect(described_class.new("--app=foo", "--app=bar") .options[:app]).to eq(['foo', 'bar'])         }

    example do
      expect(described_class.new("--foo.bar=foo", "--foo.baz=012345abcd").options[:foo]).
        to eql({:bar=>"foo", :baz=>"012345abcd"})
    end

    example do
      expect(described_class.new("--foo.bar=foo", "--foo.bar=012345abcd").options[:foo]).
        to eql({:bar=>["foo", "012345abcd"]})
    end

    example "error handling" do
      expect($stderr).to receive(:puts).with('invalid option "app"')
      expect { described_class.new("app") }.to raise_error(SystemExit)
    end
  end

  describe "#run" do
    example "triggers deploy" do
      provider = double('provider')
      expect(DPL::Provider).to receive(:new).and_return(provider)
      expect(provider).to receive(:deploy)

      described_class.run("--provider=foo")
    end

    example "error handling" do
      expect($stderr).to receive(:puts).with('missing provider')
      expect { described_class.run }.to raise_error(SystemExit)
    end

    example "error handling in debug mode" do
      expect { described_class.run("--debug") }.to raise_error(DPL::Error, 'missing provider')
    end
  end
end
