require 'spec_helper'
require 'anchor/resource/root'

describe Anchor::Root do
  context "#nuke" do
    it "clears everything" do
      Anchor::Root.expects(:fire_delete).with('/').once
      Anchor::Root.nuke
    end
  end
end
